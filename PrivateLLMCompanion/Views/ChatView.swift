import SwiftUI

struct ChatView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var streamedMessage: String = ""
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
                        
                        // Invisible anchor for scrolling
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
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type your message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            sendMessage()
                        }
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .foregroundColor(isLoading ? .red : .blue)
                        .font(.title2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading)
            }
            .padding()
        }
        .navigationTitle(selectedProject?.title ?? "No Project")
        .onAppear {
            messages = selectedProject?.chats ?? []
        }
    }
    
    private func sendMessage() {
        guard let selectedProject = selectedProject else { return }
        
        if isLoading {
            // TODO: Implement stop generation logic
            return
        }
        
        let userMessage = ChatMessage(id: UUID(), role: .user, content: inputText)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(userMessage)
        }
        
        inputText = ""
        isLoading = true
        streamedMessage = ""
        scrollID = UUID()
        
        // Build conversation context from recent messages
        let conversationContext = buildConversationContext(from: messages)
        
        let payload: [String: Any] = [
            "model": "mistral",
            "prompt": conversationContext,
            "stream": true,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9,
                "top_k": 40
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            handleErrorSync("Failed to encode request")
            return
        }
        
        var request = URLRequest(url: ollamaEndpoint)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let delegate = StreamingDelegate(
            onReceive: { [weak self] chunk in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    withAnimation(.easeIn(duration: 0.1)) {
                        self.streamedMessage += chunk
                    }
                }
            },
            onComplete: { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.finalizeAssistantResponse(for: selectedProject)
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.handleErrorSync("Error: \(error.localizedDescription)")
                }
            }
        )
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    private func buildConversationContext(from messages: [ChatMessage]) -> String {
        // Take the last 10 messages to stay within context window limits
        let recentMessages = Array(messages.suffix(10))
        
        var context = ""
        
        // Add system instruction
        context += "You are a helpful AI assistant. Respond naturally and conversationally based on the chat history.\n\n"
        
        // Add conversation history
        for message in recentMessages {
            switch message.role {
            case .user:
                context += "Human: \(message.content)\n\n"
            case .assistant:
                context += "Assistant: \(message.content)\n\n"
            }
        }
        
        // Add current response prompt
        context += "Assistant: "
        
        return context
    }
    
    private func finalizeAssistantResponse(for selectedProject: Project) {
        let finalContent = streamedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't save empty responses
        guard !finalContent.isEmpty else {
            isLoading = false
            streamedMessage = ""
            return
        }
        
        let aiMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: finalContent
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(aiMessage)
        }
        
        isLoading = false
        streamedMessage = ""
        
        // Save to project
        if let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            projects[index].chats = messages
            PersistenceManager.saveProjects(projects)
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
        }
    }
}

struct MessageRowView: View {
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

struct LoadingIndicatorView: View {
    @State private var animationAmount = 1.0
    
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
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            animationAmount = 0.5
        }
    }
}
