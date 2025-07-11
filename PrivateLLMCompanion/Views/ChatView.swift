import SwiftUI

struct ChatView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var streamedMessage: String = ""
<<<<<<< HEAD
    @State private var scrollID = UUID()
    
    private let ollamaEndpoint = URL(string: "http://127.0.0.1:11434/api/generate")!
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(messages) { message in
                            MessageRowView(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            if streamedMessage.isEmpty {
                                LoadingIndicatorView()
                                    .id(scrollID)
                            } else {
                                MessageRowView(
                                    message: ChatMessage(
                                        id: UUID(),
                                        role: .assistant,
                                        content: streamedMessage
                                    )
                                )
                                .id(scrollID)
                            }
                        }
                        
                        Color.clear.frame(height: 1).id(scrollID)
                    }
                    .padding()
                }
                .onChange(of: streamedMessage) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(scrollID, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(scrollID, anchor: .bottom)
=======
    @State private var currentModel: String = "mistral:latest"
    @State private var showingModelPicker = false
    @State private var responseStartTime: Date?
    @State private var estimatedResponseTime: Double = 3.0
    @State private var isTyping = false
    
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var modelManager = DynamicModelManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            if !ollamaService.isConnected {
                connectionStatusBar
            }
            
            // Model indicator bar with response speed info
            if !modelManager.availableModels.isEmpty {
                modelIndicatorBar
            }
            
            // Chat messages with enhanced visual feedback
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        EnhancedMessageRowView(message: message)
                    }
                    
                    // Enhanced streaming message display
                    if isLoading {
                        if streamedMessage.isEmpty {
                            EnhancedLoadingView(
                                model: currentModel,
                                estimatedTime: estimatedResponseTime,
                                elapsedTime: responseStartTime.map { Date().timeIntervalSince($0) } ?? 0
                            )
                        } else {
                            StreamingMessageView(
                                content: streamedMessage,
                                isComplete: false
                            )
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                        }
                    }
                }
            }
            
            Divider()
            
<<<<<<< HEAD
            HStack(spacing: 12) {
                TextField("Type your message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
=======
            // Enhanced input area with immediate feedback
            enhancedInputArea
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
    
    // MARK: - Enhanced Model Indicator Bar
    
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
            
            // Speed indicator
            if isLoading {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    
                    if let startTime = responseStartTime {
                        Text("\(String(format: "%.1f", Date().timeIntervalSince(startTime)))s")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
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
    
    // MARK: - Enhanced Input Area
    
    private var enhancedInputArea: some View {
        VStack(spacing: 8) {
            // Show typing indicator when user is composing
            if isTyping && !inputText.isEmpty {
                HStack {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.blue)
                    Text("Analyzing your message...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            HStack {
                TextField("Type your message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onChange(of: inputText) { newValue in
                        handleTextChange(newValue)
                    }
                    .onSubmit {
                        if canSendMessage {
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                            sendMessage()
                        }
                    }
                
<<<<<<< HEAD
                Button(action: sendMessage) {
                    Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .foregroundColor(isLoading ? .red : .blue)
                        .font(.title2)
=======
                Button(action: {
                    if isLoading {
                        // TODO: Implement stop functionality
                        print("Stop button pressed")
                    } else {
                        sendMessage()
                    }
                }) {
                    ZStack {
                        if isLoading {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(canSendMessage ? .blue : .secondary)
                        }
                    }
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading)
            }
            .padding()
        }
<<<<<<< HEAD
        .navigationTitle(selectedProject?.title ?? "No Project")
        .onAppear {
=======
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
        withAnimation(.easeInOut(duration: 0.3)) {
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
            messages = selectedProject?.chats ?? []
        }
    }
    
<<<<<<< HEAD
=======
    private func setInitialModel() {
        if let preferredModel = modelManager.userPreferredModel,
           modelManager.availableModels.contains(where: { $0.name == preferredModel }) {
            currentModel = preferredModel
        } else if let firstModel = modelManager.availableModels.first {
            currentModel = firstModel.name
        }
    }
    
    private func handleTextChange(_ text: String) {
        // Show typing indicator for longer messages
        withAnimation(.easeInOut(duration: 0.2)) {
            isTyping = text.count > 10
        }
        
        // Estimate response time based on message complexity
        if text.count > 0 {
            estimatedResponseTime = estimateResponseTime(for: text)
        }
    }
    
    private func estimateResponseTime(for text: String) -> Double {
        let baseTime = 2.0
        let lengthFactor = Double(text.count) / 100.0
        let complexityFactor = text.lowercased().contains("code") ? 2.0 : 1.0
        
        return min(baseTime + lengthFactor * complexityFactor, 15.0)
    }
    
    // MARK: - Message Sending with Enhanced Feedback
    
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
    private func sendMessage() {
        guard let selectedProject = selectedProject else { return }
        
        if isLoading {
            // TODO: Implement stop generation
            return
        }
        
        let userMessage = ChatMessage(id: UUID(), role: .user, content: inputText)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(userMessage)
<<<<<<< HEAD
        }
        
        inputText = ""
        isLoading = true
        streamedMessage = ""
        scrollID = UUID()
        
        // Build conversation context
        let conversationContext = buildConversationContext(from: messages)
        
        let payload: [String: Any] = [
            "model": "mistral",
            "prompt": conversationContext,
            "stream": true
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            handleError("Failed to encode request")
            return
        }
        
        var request = URLRequest(url: ollamaEndpoint)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use URLSession.shared with simple completion handler - no delegate needed
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleError("Network error: \(error.localizedDescription)")
                    return
                }
=======
            inputText = ""
            isLoading = true
            isTyping = false
            streamedMessage = ""
            responseStartTime = Date()
        }
        
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
        
        let context = Array(messages.prefix(messages.count - 1))
        
        for await response in ollamaService.generateResponse(
            prompt: message,
            model: model,
            context: context,
            stream: true
        ) {
            await MainActor.run {
                self.streamedMessage = response.content
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                
                guard let data = data else {
                    self.handleError("No data received")
                    return
                }
                
                // For now, handle as non-streaming response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let response = json["response"] as? String {
                        
                        let aiMessage = ChatMessage(
                            id: UUID(),
                            role: .assistant,
                            content: response
                        )
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.messages.append(aiMessage)
                        }
                        
                        self.isLoading = false
<<<<<<< HEAD
                        self.streamedMessage = ""
                        
                        // Save to project
                        if let index = self.projects.firstIndex(where: { $0.id == selectedProject.id }) {
                            self.projects[index].chats = self.messages
                            PersistenceManager.saveProjects(self.projects)
                        }
                    } else {
                        self.handleError("Invalid response format")
=======
                        self.responseStartTime = nil
                    }
                    
                    // Save to project
                    if let index = self.projects.firstIndex(where: { $0.id == selectedProject.id }) {
                        self.projects[index].chats = self.messages
                        PersistenceManager.saveProjects(self.projects)
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                    }
                } catch {
                    self.handleError("Failed to parse response: \(error.localizedDescription)")
                }
            }
        }
        
<<<<<<< HEAD
        task.resume()
    }
    
    private func buildConversationContext(from messages: [ChatMessage]) -> String {
        let recentMessages = Array(messages.suffix(10))
        
        var context = ""
        context += "You are a helpful AI assistant. Respond naturally and conversationally based on the chat history.\n\n"
        
        for message in recentMessages {
            switch message.role {
            case .user:
                context += "Human: \(message.content)\n\n"
            case .assistant:
                context += "Assistant: \(message.content)\n\n"
            case .system:
                context += "System: \(message.content)\n\n"
            }
        }
        
        context += "Assistant: "
        return context
=======
        // Handle case where streaming finishes without completion
        await MainActor.run {
            if self.isLoading {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.isLoading = false
                    self.responseStartTime = nil
                    
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
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
    }
    
    private func handleError(_ message: String) {
        withAnimation(.easeInOut(duration: 0.4)) {
            let errorMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "⚠️ \(message)"
            )
            messages.append(errorMessage)
            isLoading = false
            streamedMessage = ""
<<<<<<< HEAD
=======
            responseStartTime = nil
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
        }
    }
}

<<<<<<< HEAD
struct MessageRowView: View {
=======
// MARK: - Enhanced Message Components

struct EnhancedMessageRowView: View {
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
    let message: ChatMessage
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                .foregroundColor(message.role == .user ? .blue : .green)
                .font(.title3)
                .frame(width: 24)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1.0 : 0.5)
                
                Text(message.content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .opacity(isVisible ? 1.0 : 0.8)
            }
        }
        .padding(.vertical, 4)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

<<<<<<< HEAD
struct LoadingIndicatorView: View {
    @State private var animationAmount = 1.0
=======
struct StreamingMessageView: View {
    let content: String
    let isComplete: Bool
    @State private var cursorVisible = true
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
    
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
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationAmount)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationAmount
                            )
                    }
                    Text("thinking...")
                        .font(.caption)
                        .foregroundColor(.secondary)
<<<<<<< HEAD
=======
                    
                    if !isComplete {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(cursorVisible ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                        value: cursorVisible
                                    )
                            }
                        }
                    }
                }
                
                HStack {
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    
                    if !isComplete && !content.isEmpty {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 2, height: 20)
                            .opacity(cursorVisible ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: cursorVisible)
                    }
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
<<<<<<< HEAD
            animationAmount = 0.5
=======
            cursorVisible = true
        }
    }
}

struct EnhancedLoadingView: View {
    let model: String
    let estimatedTime: Double
    let elapsedTime: Double
    
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // Animated thinking indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                                .opacity(animationPhase == index ? 1.0 : 0.6)
                        }
                    }
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                animationPhase = (animationPhase + 1) % 3
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thinking with \(model)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Progress indicator
                        HStack {
                            if estimatedTime > 0 {
                                let progress = min(elapsedTime / estimatedTime, 1.0)
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 100)
                                
                                Text("\(String(format: "%.1f", elapsedTime))s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .controlSize(.small)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Model Picker Sheet (Simplified for macOS)

struct ModelPickerSheet: View {
    let availableModels: [DynamicModelManager.ModelInfo]
    @Binding var selectedModel: String
    let autoOptimizationEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                        Text("Auto-Optimization Enabled")
                            .font(.headline)
                    }
                    
                    Text("The system automatically selects the best model for each query.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text("Available Models")
                .font(.headline)
            
            if availableModels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No models detected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(availableModels, id: \.name) { model in
                            Button(action: {
                                selectedModel = model.name
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(model.parameters) • \(formatSize(model.size))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedModel == model.name ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedModel == model.name ? .blue : .secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    private func formatSize(_ sizeInMB: Int) -> String {
        if sizeInMB < 1024 {
            return "\(sizeInMB) MB"
        } else {
            let sizeInGB = Double(sizeInMB) / 1024.0
            return String(format: "%.1f GB", sizeInGB)
>>>>>>> parent of 78b3861 (Implement Intelligent Response Pipeline - Eliminate AI response delays with multi-layer intelligence system)
        }
    }
}
