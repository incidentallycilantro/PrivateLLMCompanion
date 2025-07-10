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
    @State private var responseStartTime: Date?
    @State private var estimatedResponseTime: Double = 3.0
    @State private var isTyping = false
    @State private var currentResponseLayer: IntelligentResponsePipeline.ResponseLayer = .none
    
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var modelManager = DynamicModelManager()
    @StateObject private var intelligentPipeline = IntelligentResponsePipeline()
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            if !ollamaService.isConnected {
                connectionStatusBar
            }
            
            // Enhanced model indicator bar with pipeline status
            if !modelManager.availableModels.isEmpty {
                enhancedModelIndicatorBar
            }
            
            // Chat messages with enhanced visual feedback
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        EnhancedMessageRowView(message: message)
                    }
                    
                    // Enhanced streaming message display with layer indication
                    if isLoading {
                        if streamedMessage.isEmpty {
                            IntelligentLoadingView(
                                model: currentModel,
                                layer: currentResponseLayer,
                                estimatedTime: estimatedResponseTime,
                                elapsedTime: responseStartTime.map { Date().timeIntervalSince($0) } ?? 0
                            )
                        } else {
                            IntelligentStreamingView(
                                content: streamedMessage,
                                layer: currentResponseLayer,
                                isComplete: false
                            )
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Enhanced input area with pipeline predictions
            intelligentInputArea
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
            setupIntelligentState()
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
    
    // MARK: - Enhanced Model Indicator Bar with Pipeline Status
    
    private var enhancedModelIndicatorBar: some View {
        HStack {
            // Pipeline status indicator
            HStack(spacing: 4) {
                Image(systemName: pipelineStatusIcon)
                    .foregroundColor(pipelineStatusColor)
                    .font(.caption)
                
                Text(pipelineStatusText)
                    .font(.caption2)
                    .foregroundColor(pipelineStatusColor)
            }
            
            Divider()
                .frame(height: 12)
            
            Image(systemName: "cpu")
                .foregroundColor(.blue)
                .font(.caption)
            
            Text("Model: \(currentModel)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if modelManager.autoOptimizationEnabled {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Smart")
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
    
    // MARK: - Intelligent Input Area
    
    private var intelligentInputArea: some View {
        VStack(spacing: 8) {
            // Show intelligent prediction when user is composing
            if isTyping && !inputText.isEmpty {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text(getInputPrediction())
                        .font(.caption)
                        .foregroundColor(.purple)
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
                        handleIntelligentTextChange(newValue)
                    }
                    .onSubmit {
                        if canSendMessage {
                            sendIntelligentMessage()
                        }
                    }
                    .disabled(!ollamaService.isConnected)
                
                Button(action: {
                    if isLoading {
                        stopGeneration()
                    } else {
                        sendIntelligentMessage()
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
                }
                .disabled(!canSendMessage && !isLoading)
            }
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        ollamaService.isConnected
    }
    
    private var pipelineStatusIcon: String {
        switch currentResponseLayer {
        case .none: return "circle"
        case .instant: return "bolt.fill"
        case .fast: return "hare.fill"
        case .intelligent: return "brain.head.profile"
        }
    }
    
    private var pipelineStatusColor: Color {
        switch currentResponseLayer {
        case .none: return .secondary
        case .instant: return .yellow
        case .fast: return .orange
        case .intelligent: return .purple
        }
    }
    
    private var pipelineStatusText: String {
        switch currentResponseLayer {
        case .none: return "Ready"
        case .instant: return "Instant"
        case .fast: return "Fast"
        case .intelligent: return "Deep"
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupIntelligentState() {
        Task {
            await ollamaService.checkConnection()
            await modelManager.refreshAvailableModels()
            await intelligentPipeline.startBackgroundOptimization()
            setInitialModel()
        }
    }
    
    private func loadMessages() {
        withAnimation(.easeInOut(duration: 0.3)) {
            messages = selectedProject?.chats ?? []
        }
    }
    
    private func setInitialModel() {
        if let preferredModel = modelManager.userPreferredModel,
           modelManager.availableModels.contains(where: { $0.name == preferredModel }) {
            currentModel = preferredModel
        } else if let firstModel = modelManager.availableModels.first {
            currentModel = firstModel.name
        }
    }
    
    private func handleIntelligentTextChange(_ text: String) {
        // Show typing indicator for longer messages
        withAnimation(.easeInOut(duration: 0.2)) {
            isTyping = text.count > 5
        }
        
        // Estimate response time based on message complexity and layer prediction
        if text.count > 0 {
            estimatedResponseTime = estimateIntelligentResponseTime(for: text)
        }
    }
    
    private func getInputPrediction() -> String {
        let query = inputText.lowercased()
        
        if query.contains("hello") || query.contains("hi") {
            return "→ Instant response ready"
        }
        
        if query.contains("help") || query.contains("what") {
            return "→ Quick answer available"
        }
        
        if query.contains("code") || query.contains("function") {
            return "→ Programming mode activated"
        }
        
        if query.count > 50 {
            return "→ Deep analysis mode"
        }
        
        return "→ Smart routing enabled"
    }
    
    private func estimateIntelligentResponseTime(for text: String) -> Double {
        let query = text.lowercased()
        
        // Instant layer predictions
        if query.contains("hello") || query.contains("hi") || query.contains("thanks") {
            return 0.05
        }
        
        // Fast layer predictions
        if query.count < 20 && !query.contains("explain") && !query.contains("complex") {
            return 0.8
        }
        
        // Intelligent layer predictions
        let complexityFactor = query.contains("explain") || query.contains("analyze") ? 2.0 : 1.0
        let lengthFactor = Double(text.count) / 100.0
        
        return min(2.0 + lengthFactor * complexityFactor, 8.0)
    }
    
    // MARK: - Intelligent Message Sending
    
    private func sendIntelligentMessage() {
        guard let selectedProject = selectedProject else { return }
        guard canSendMessage else { return }
        
        let userMessage = ChatMessage(id: UUID(), role: .user, content: inputText)
        let messageToSend = inputText
        
        // Immediate UI feedback with animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.append(userMessage)
            inputText = ""
            isLoading = true
            isTyping = false
            streamedMessage = ""
            responseStartTime = Date()
            currentResponseLayer = .none
        }
        
        Task {
            await processIntelligentResponse(messageToSend, selectedProject: selectedProject)
        }
    }
    
    private func processIntelligentResponse(_ message: String, selectedProject: Project) async {
        let context = Array(messages.prefix(messages.count - 1))
        
        for await response in intelligentPipeline.processQuery(message, context: context) {
            await MainActor.run {
                self.currentResponseLayer = response.layer
                self.streamedMessage = response.content
                
                if response.isComplete {
                    // Complete with animation
                    withAnimation(.easeInOut(duration: 0.4)) {
                        let aiMessage = ChatMessage(
                            id: UUID(),
                            role: .assistant,
                            content: response.content
                        )
                        self.messages.append(aiMessage)
                        self.streamedMessage = ""
                        self.isLoading = false
                        self.responseStartTime = nil
                        self.currentResponseLayer = .none
                    }
                    
                    // Save to project
                    if let index = self.projects.firstIndex(where: { $0.id == selectedProject.id }) {
                        self.projects[index].chats = self.messages
                        PersistenceManager.saveProjects(self.projects)
                    }
                }
            }
        }
    }
    
    private func stopGeneration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
            streamedMessage = ""
            responseStartTime = nil
            currentResponseLayer = .none
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            handleErrorSync(message)
        }
    }
    
    private func handleErrorSync(_ message: String) {
        withAnimation(.easeInOut(duration: 0.4)) {
            let errorMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "⚠️ \(message)"
            )
            messages.append(errorMessage)
            isLoading = false
            streamedMessage = ""
            responseStartTime = nil
            currentResponseLayer = .none
        }
    }
}

// MARK: - Enhanced Message Components for Pipeline

struct EnhancedMessageRowView: View {
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
        .animation(.easeOut(duration: 0.4), value: isVisible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

struct IntelligentStreamingView: View {
    let content: String
    let layer: IntelligentResponsePipeline.ResponseLayer
    let isComplete: Bool
    @State private var cursorVisible = true
    
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
                    
                    // Layer indicator
                    Text(layerText)
                        .font(.caption2)
                        .foregroundColor(layerColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(layerColor.opacity(0.2))
                        .cornerRadius(3)
                    
                    if !isComplete {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(layerColor)
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
                            .fill(layerColor)
                            .frame(width: 2, height: 20)
                            .opacity(cursorVisible ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: cursorVisible)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            cursorVisible = true
        }
    }
    
    private var layerText: String {
        switch layer {
        case .none: return "Processing"
        case .instant: return "Instant"
        case .fast: return "Fast"
        case .intelligent: return "Deep"
        }
    }
    
    private var layerColor: Color {
        switch layer {
        case .none: return .secondary
        case .instant: return .yellow
        case .fast: return .orange
        case .intelligent: return .purple
        }
    }
}

struct IntelligentLoadingView: View {
    let model: String
    let layer: IntelligentResponsePipeline.ResponseLayer
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
                HStack {
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(layerText)
                        .font(.caption2)
                        .foregroundColor(layerColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(layerColor.opacity(0.2))
                        .cornerRadius(3)
                }
                
                HStack(spacing: 12) {
                    // Animated thinking indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(layerColor)
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
                        Text(loadingText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Progress indicator
                        HStack {
                            if estimatedTime > 0 && layer != .instant {
                                let progress = min(elapsedTime / estimatedTime, 1.0)
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 100)
                                
                                Text("\(String(format: "%.1f", elapsedTime))s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var layerText: String {
        switch layer {
        case .none: return "Routing"
        case .instant: return "Instant"
        case .fast: return "Fast"
        case .intelligent: return "Deep"
        }
    }
    
    private var layerColor: Color {
        switch layer {
        case .none: return .secondary
        case .instant: return .yellow
        case .fast: return .orange
        case .intelligent: return .purple
        }
    }
    
    private var loadingText: String {
        switch layer {
        case .none: return "Analyzing query..."
        case .instant: return "Processing instantly..."
        case .fast: return "Using fast model..."
        case .intelligent: return "Deep thinking with \(model)..."
        }
    }
}

// MARK: - Model Picker Sheet (Simplified for Pipeline)

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
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("Intelligent Pipeline Active")
                        .font(.headline)
                }
                
                Text("The system uses multiple models intelligently. This setting controls the primary model for complex queries.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
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
        }
    }
}
