import SwiftUI

struct ChatView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var streamedMessage: String = ""
    @State private var currentModel: String = "mistral:latest"
    @State private var showingModelPicker = false
    
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var modelManager = DynamicModelManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            if !ollamaService.isConnected {
                connectionStatusBar
            }
            
            // Model indicator bar
            if !modelManager.availableModels.isEmpty {
                modelIndicatorBar
            }
            
            // Chat messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageRowView(message: message)
                    }
                    
                    // Streaming message display
                    if isLoading && !streamedMessage.isEmpty {
                        StreamingMessageView(content: streamedMessage)
                    }
                    
                    // Loading indicator
                    if isLoading && streamedMessage.isEmpty {
                        LoadingMessageView(model: currentModel)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Input area
            inputArea
        }
        .navigationTitle(selectedProject?.title ?? "No Project")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if ollamaService.isConnected {
                    Button(action: { showingModelPicker.toggle() }) {
                        Image(systemName: "cpu")
                    }
                    .help("Select AI Model")
                }
            }
        }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerSheet(
                availableModels: modelManager.availableModels,
                selectedModel: $currentModel,
                autoOptimizationEnabled: modelManager.autoOptimizationEnabled
            )
        }
        .onAppear {
            loadMessages()
            setupInitialState()
        }
        .onChange(of: selectedProject) { _ in
            loadMessages()
        }
    }
    
    // MARK: - Connection Status Bar
    
    private var connectionStatusBar: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("Ollama not connected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await ollamaService.checkConnection()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
    
    // MARK: - Model Indicator Bar
    
    private var modelIndicatorBar: some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundColor(.blue)
                .font(.caption)
            
            Text("Using: \(currentModel)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if modelManager.autoOptimizationEnabled {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Auto")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(3)
            }
            
            Spacer()
            
            if ollamaService.isConnected {
                Button("Change") {
                    showingModelPicker = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        HStack {
            TextField("Type your message...", text: $inputText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .onSubmit {
                    if canSendMessage {
                        sendMessage()
                    }
                }
                .disabled(!ollamaService.isConnected)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(canSendMessage ? .blue : .secondary)
            }
            .disabled(!canSendMessage)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        ollamaService.isConnected
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        Task {
            await ollamaService.checkConnection()
            await modelManager.refreshAvailableModels()
            setInitialModel()
        }
    }
    
    private func loadMessages() {
        messages = selectedProject?.chats ?? []
    }
    
    private func setInitialModel() {
        if let preferredModel = modelManager.userPreferredModel,
           modelManager.availableModels.contains(where: { $0.name == preferredModel }) {
            currentModel = preferredModel
        } else if let firstModel = modelManager.availableModels.first {
            currentModel = firstModel.name
        }
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        guard let selectedProject = selectedProject else { return }
        guard canSendMessage else { return }
        
        let userMessage = ChatMessage(id: UUID(), role: .user, content: inputText)
        let messageToSend = inputText
        
        // Update UI immediately
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        streamedMessage = ""
        
        Task {
            // Select optimal model if auto-optimization is enabled
            if modelManager.autoOptimizationEnabled {
                let optimalModel = await selectOptimalModel(for: messageToSend)
                await MainActor.run {
                    currentModel = optimalModel
                }
            }
            
            // Ensure model is available
            guard await ollamaService.isModelAvailable(currentModel) else {
                await handleError("Model '\(currentModel)' is not installed")
                return
            }
            
            // Generate response
            await generateResponse(message: messageToSend, model: currentModel)
        }
    }
    
    private func generateResponse(message: String, model: String) async {
        guard let selectedProject = selectedProject else { return }
        
        let context = Array(messages.prefix(messages.count - 1)) // Exclude the just-added user message
        
        for await response in ollamaService.generateResponse(
            prompt: message,
            model: model,
            context: context,
            stream: true
        ) {
            await MainActor.run {
                self.streamedMessage = response.content
                
                if response.isComplete {
                    // Save the complete response
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response.content
                    )
                    self.messages.append(aiMessage)
                    self.streamedMessage = ""
                    self.isLoading = false
                    
                    // Save to project
                    if let index = self.projects.firstIndex(where: { $0.id == selectedProject.id }) {
                        self.projects[index].chats = self.messages
                        PersistenceManager.saveProjects(self.projects)
                    }
                }
            }
        }
        
        // Handle case where streaming finishes without completion
        await MainActor.run {
            if self.isLoading {
                self.isLoading = false
                if !self.streamedMessage.isEmpty {
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: self.streamedMessage
                    )
                    self.messages.append(aiMessage)
                    self.streamedMessage = ""
                    
                    // Save to project
                    if let index = self.projects.firstIndex(where: { $0.id == selectedProject.id }) {
                        self.projects[index].chats = self.messages
                        PersistenceManager.saveProjects(self.projects)
                    }
                } else {
                    self.handleErrorSync("No response received from model")
                }
            }
        }
    }
    
    private func selectOptimalModel(for message: String) async -> String {
        let complexity = analyzeQueryComplexity(message)
        let domain = analyzeQueryDomain(message)
        
        let optimalModel = await modelManager.selectOptimalModel(
            for: message,
            complexity: complexity,
            domain: domain,
            userOverride: modelManager.autoOptimizationEnabled ? nil : currentModel
        )
        
        return optimalModel.name
    }
    
    private func analyzeQueryComplexity(_ message: String) -> QueryComplexity {
        let messageLength = message.count
        let codePatterns = ["def ", "function", "class ", "import", "```", "console.log", "print("]
        let complexPatterns = ["architecture", "design pattern", "algorithm", "optimize", "refactor"]
        
        if complexPatterns.contains(where: message.lowercased().contains) {
            return .complex
        }
        
        if codePatterns.contains(where: message.contains) {
            return .standard
        }
        
        return messageLength > 100 ? .standard : .simple
    }
    
    private func analyzeQueryDomain(_ message: String) -> QueryDomain {
        let messageLower = message.lowercased()
        
        if messageLower.contains("code") || messageLower.contains("function") ||
           messageLower.contains("debug") || messageLower.contains("error") {
            if messageLower.contains("change") || messageLower.contains("modify") ||
               messageLower.contains("update") || messageLower.contains("fix") {
                return .codeIteration
            }
            return .codeGeneration
        }
        
        if messageLower.contains("math") || messageLower.contains("calculate") ||
           messageLower.contains("equation") || messageLower.contains("formula") {
            return .mathematics
        }
        
        if messageLower.contains("story") || messageLower.contains("write") ||
           messageLower.contains("creative") || messageLower.contains("poem") {
            return .creativeWriting
        }
        
        return .generalChat
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            handleErrorSync(message)
        }
    }
    
    private func handleErrorSync(_ message: String) {
        let errorMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "⚠️ \(message)"
        )
        messages.append(errorMessage)
        isLoading = false
        streamedMessage = ""
    }
}

// MARK: - Message Components

struct MessageRowView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                .foregroundColor(message.role == .user ? .blue : .green)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StreamingMessageView: View {
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LoadingMessageView: View {
    let model: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Thinking with \(model)...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Model Picker Sheet

struct ModelPickerSheet: View {
    let availableModels: [DynamicModelManager.ModelInfo]
    @Binding var selectedModel: String
    let autoOptimizationEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Select Model")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if autoOptimizationEnabled {
                autoOptimizationBanner
            }
            
            Text("Available Models")
                .font(.headline)
            
            if availableModels.isEmpty {
                emptyModelsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(availableModels, id: \.name) { model in
                            ModelPickerRow(
                                model: model,
                                isSelected: model.name == selectedModel,
                                onSelect: {
                                    selectedModel = model.name
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    private var autoOptimizationBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                Text("Auto-Optimization Enabled")
                    .font(.headline)
            }
            
            Text("The system automatically selects the best model for each query. You can still override the selection below.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var emptyModelsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No models detected")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Install models using Ollama CLI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ModelPickerRow: View {
    let model: DynamicModelManager.ModelInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatSize(model.size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(model.parameters)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        if let quantization = model.quantization {
                            Text(quantization)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Text(model.specialty?.rawValue.capitalized ?? "General")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatSize(_ sizeInMB: Int) -> String {
        if sizeInMB < 1024 {
            return "\(sizeInMB) MB"
        } else {
            let sizeInGB = Double(sizeInMB) / 1024.0
            return String(format: "%.1f GB", sizeInGB)
        }
    }
}
