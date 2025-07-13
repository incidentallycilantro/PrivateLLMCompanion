import SwiftUI

struct MainSidebarView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?
    @StateObject private var quickChatManager = QuickChatManager()
    @State private var selectedView: SidebarSelection = .quickChat
    @State private var showingWelcomeAnimation = false
    
    enum SidebarSelection: String, CaseIterable {
        case quickChat = "Quick Chat"
        case projects = "Projects"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .quickChat: return "bubble.left.and.bubble.right.fill"
            case .projects: return "folder.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Revolutionary Sidebar - Always shows immediate chat access
            revolutionarySidebar
        } detail: {
            // Revolutionary Detail View - Immediate chat access without barriers
            revolutionaryDetailView
        }
        .onAppear {
            // App opens directly to Quick Chat mode
            selectedView = .quickChat
            quickChatManager.startQuickChat()
            
            // Show welcome animation for first-time users
            if quickChatManager.isFirstTimeUser {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5)) {
                    showingWelcomeAnimation = true
                }
            }
        }
        .onChange(of: projects) { _, _ in
            // Keep quick chat manager updated with project list for intelligent suggestions
            quickChatManager.updateWithProjects(projects)
        }
    }
    
    // MARK: - Revolutionary Sidebar
    
    private var revolutionarySidebar: some View {
        VStack(spacing: 0) {
            // App Header with Quick Access Emphasis
            sidebarHeader
            
            Divider()
            
            // Revolutionary Navigation - Quick Chat Always First
            List(selection: $selectedView) {
                // REVOLUTIONARY: Quick Chat always accessible, prominently featured
                NavigationLink(value: SidebarSelection.quickChat) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.blue)
                            .imageScale(.medium)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Chat")
                                .font(.headline)
                            
                            if quickChatManager.currentConversation.messages.isEmpty {
                                Text("Start chatting instantly")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(quickChatManager.getConversationSummary())
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        // Show organization indicator if conversation is project-worthy
                        if quickChatManager.activeOrganizationSuggestion != nil {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .tag(SidebarSelection.quickChat)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                Divider()
                    .padding(.vertical, 8)
                
                // Projects Section with Enhanced Organization
                Section {
                    NavigationLink(value: SidebarSelection.projects) {
                        Label("Organize Projects", systemImage: "folder.fill")
                            .foregroundColor(.secondary)
                    }
                    .tag(SidebarSelection.projects)
                    
                    // Show recent/pinned projects for quick access
                    ForEach(projects.prefix(3)) { project in
                        Button(action: {
                            selectedProject = project
                            selectedView = .quickChat // Stay in chat mode but switch context
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text("\(project.chats.count) messages")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if projects.count > 3 {
                        Button("View All Projects...") {
                            selectedView = .projects
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.leading, 20)
                    }
                } header: {
                    Text("Recent Projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
                
                Spacer(minLength: 20)
                
                // Settings at bottom
                NavigationLink(value: SidebarSelection.settings) {
                    Label("Settings", systemImage: "gearshape.fill")
                        .foregroundColor(.secondary)
                }
                .tag(SidebarSelection.settings)
            }
            .listStyle(SidebarListStyle())
        }
        .navigationTitle("Private LLM")
        .frame(minWidth: 250)
    }
    
    // MARK: - Sidebar Header
    
    private var sidebarHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private LLM Companion")
                        .font(.title2)
                        .bold()
                    
                    if let onboardingMessage = quickChatManager.getOnboardingMessage() {
                        Text(onboardingMessage)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .opacity(showingWelcomeAnimation ? 1.0 : 0.0)
                            .scaleEffect(showingWelcomeAnimation ? 1.0 : 0.8)
                    }
                }
                
                Spacer()
                
                // Quick action button - New conversation
                Button(action: startNewQuickChat) {
                    Image(systemName: "plus.bubble.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .help("Start new conversation")
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Revolutionary Status Bar - Shows conversation intelligence
            conversationIntelligenceBar
        }
    }
    
    // MARK: - Conversation Intelligence Bar
    
    private var conversationIntelligenceBar: some View {
        Group {
            if quickChatManager.currentConversation.messages.count > 0 {
                HStack(spacing: 8) {
                    // Conversation analysis indicator
                    HStack(spacing: 4) {
                        if quickChatManager.analyzer.isAnalyzing {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        Text("AI analyzing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Organization opportunity indicator
                    if quickChatManager.activeOrganizationSuggestion != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("Organization suggested")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // MARK: - Revolutionary Detail View
    
    private var revolutionaryDetailView: some View {
        Group {
            switch selectedView {
            case .quickChat:
                revolutionaryQuickChatView
                
            case .projects:
                ProjectsView(
                    projects: $projects,
                    selectedProject: $selectedProject
                )
                
            case .settings:
                SettingsView()
            }
        }
    }
    
    // MARK: - Revolutionary Quick Chat View
    
    private var revolutionaryQuickChatView: some View {
        VStack(spacing: 0) {
            // Conversation Context Header
            if let selectedProject = selectedProject {
                projectContextHeader(selectedProject)
            } else {
                quickChatContextHeader
            }
            
            // Main Chat Interface - Enhanced ChatView
            RevolutionaryEmbeddedChatView(
                messages: quickChatManager.currentConversation.messages,
                selectedProject: $selectedProject,
                projects: $projects,
                quickChatManager: quickChatManager
            )
            
            // REVOLUTIONARY: Ambient Organization Panel
            if quickChatManager.showOrganizationPanel {
                ambientOrganizationPanel
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Context Headers
    
    private var quickChatContextHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(.blue)
                        Text("Quick Chat")
                            .font(.headline)
                    }
                    
                    if quickChatManager.currentConversation.messages.isEmpty {
                        Text("Start chatting about anything - I'll help organize as we go")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(quickChatManager.getConversationSummary())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Manual organization button
                if quickChatManager.currentConversation.messages.count >= 3 {
                    Button("Organize") {
                        withAnimation(.spring()) {
                            quickChatManager.triggerOrganizationSuggestion()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Show organization hint for new users
            if quickChatManager.shouldShowOrganizationHint() {
                HStack {
                    Text(quickChatManager.getOrganizationHint())
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Got it") {
                        // Dismiss hint
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func projectContextHeader(_ project: Project) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.green)
                        Text(project.title)
                            .font(.headline)
                    }
                    
                    Text("Project chat • \(project.chats.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Back to Quick Chat") {
                    selectedProject = nil
                    quickChatManager.startQuickChat()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - REVOLUTIONARY Ambient Organization Panel
    
    private var ambientOrganizationPanel: some View {
        VStack(spacing: 0) {
            Divider()
            
            if let suggestion = quickChatManager.activeOrganizationSuggestion {
                HStack(spacing: 16) {
                    // AI suggestion icon
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("AI")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    // Suggestion content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(suggestion.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(suggestion.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let projectName = suggestion.suggestedProjectName {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Suggested name: \"\(projectName)\"")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 8) {
                        Button(suggestion.primaryAction) {
                            handleOrganizationSuggestionAccepted(suggestion)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        if let secondaryAction = suggestion.secondaryAction {
                            Button(secondaryAction) {
                                quickChatManager.dismissOrganizationSuggestion()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func startNewQuickChat() {
        withAnimation(.spring()) {
            selectedProject = nil
            selectedView = .quickChat
            quickChatManager.resetForNewSession()
            quickChatManager.startQuickChat()
        }
    }
    
    // FIXED: Properly capture the returned project
    private func handleOrganizationSuggestionAccepted(_ suggestion: QuickChatManager.OrganizationSuggestion) {
        quickChatManager.acceptOrganizationSuggestion()
        
        switch suggestion.type {
        case .createProject, .graduateConversation:
            if let projectName = suggestion.suggestedProjectName {
                let newProject = quickChatManager.graduateToProject(
                    projectName: projectName,
                    description: "Created from Quick Chat conversation",
                    projects: &projects
                )
                
                // Switch to the new project
                withAnimation(.spring()) {
                    selectedProject = newProject
                }
                
                // Save projects
                PersistenceManager.saveProjects(projects)
            }
            
        case .addToProject:
            if let projectId = suggestion.existingProjectId {
                let success = quickChatManager.moveToExistingProject(
                    projectId: projectId,
                    projects: &projects
                )
                
                if success {
                    // Switch to the existing project
                    selectedProject = projects.first { $0.id == projectId }
                    PersistenceManager.saveProjects(projects)
                }
            }
            
        case .splitConversation:
            // TODO: Implement conversation splitting
            print("Split conversation feature coming soon")
            
        case .contextSwitch:
            // TODO: Implement context switching
            print("Context switch feature coming soon")
        }
    }
}

// MARK: - Revolutionary Embedded Chat View

struct RevolutionaryEmbeddedChatView: View {
    let messages: [ChatMessage]
    @Binding var selectedProject: Project? // FIXED: Changed from let to @Binding
    @Binding var projects: [Project]
    @ObservedObject var quickChatManager: QuickChatManager
    
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var streamedMessage: String = ""
    @State private var currentModel: String = "mistral:latest"
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var modelManager = DynamicModelManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages with Enhanced Visual Design
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Welcome message for empty state
                        if messages.isEmpty {
                            revolutionaryWelcomeView
                        }
                        
                        // Chat messages
                        ForEach(messages) { message in
                            RevolutionaryMessageRowView(message: message)
                                .id(message.id)
                        }
                        
                        // Streaming message display
                        if isLoading {
                            if streamedMessage.isEmpty {
                                RevolutionaryLoadingView(model: currentModel)
                            } else {
                                RevolutionaryStreamingMessageView(
                                    content: streamedMessage,
                                    isComplete: false
                                )
                            }
                        }
                        
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: streamedMessage) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            // Revolutionary Input Area with Immediate Feedback
            revolutionaryInputArea
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Revolutionary Welcome View
    
    private var revolutionaryWelcomeView: some View {
        VStack(spacing: 24) {
            // Hero welcome section
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .opacity(0.8)
                
                VStack(spacing: 8) {
                    Text("Ready to Chat!")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Start a conversation about anything. I'll intelligently suggest organizing it when it becomes substantial.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.top, 40)
            
            // Example prompts for inspiration
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking about:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ExamplePromptCard(
                        icon: "curlybraces",
                        title: "Code Help",
                        subtitle: "Debug code, architecture advice",
                        color: .green
                    ) {
                        inputText = "Help me debug this React component"
                    }
                    
                    ExamplePromptCard(
                        icon: "lightbulb.fill",
                        title: "Ideas & Planning",
                        subtitle: "Brainstorm, strategize, plan",
                        color: .orange
                    ) {
                        inputText = "Help me plan a mobile app idea"
                    }
                    
                    ExamplePromptCard(
                        icon: "graduationcap.fill",
                        title: "Learning",
                        subtitle: "Explain concepts, tutorials",
                        color: .purple
                    ) {
                        inputText = "Explain how SwiftUI state management works"
                    }
                    
                    ExamplePromptCard(
                        icon: "pencil.and.outline",
                        title: "Writing",
                        subtitle: "Content, documentation, emails",
                        color: .blue
                    ) {
                        inputText = "Help me write project documentation"
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: 600)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Revolutionary Input Area
    
    private var revolutionaryInputArea: some View {
        VStack(spacing: 12) {
            // Show conversation command suggestions
            if !inputText.isEmpty, let command = quickChatManager.processConversationalCommand(inputText) {
                conversationalCommandPreview(command)
            }
            
            // Main input area
            HStack(spacing: 12) {
                TextField("Type your message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit {
                        if canSendMessage {
                            sendMessage()
                        }
                    }
                    .overlay(
                        // Subtle typing indicator
                        HStack {
                            Spacer()
                            if !inputText.isEmpty && !isLoading {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                    .opacity(0.6)
                                    .padding(.trailing, 8)
                            }
                        }
                    )
                
                Button(action: {
                    if isLoading {
                        // TODO: Implement stop functionality
                        print("Stop generation")
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
                    .font(.title2)
                }
                .disabled(!canSendMessage && !isLoading)
                .buttonStyle(.plain)
                .scaleEffect(canSendMessage ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: canSendMessage)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Conversational Command Preview
    
    func conversationalCommandPreview(_ command: QuickChatManager.ConversationalCommand) -> some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Command Detected")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.orange)
                
                switch command {
                case .createProject(let name):
                    Text("Will create project: \"\(name)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .moveToProject(let name):
                    Text("Will move to project: \"\(name ?? "Unknown")\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .organizeConversation:
                    Text("Will organize this conversation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .splitConversation:
                    Text("Will split conversation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Helper Properties
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        ollamaService.isConnected
    }
    
    // MARK: - Core Functions
    
    func setupInitialState() {
        Task {
            _ = await ollamaService.checkConnection()
            await modelManager.refreshAvailableModels()
            setInitialModel()
        }
    }
    
    func setInitialModel() {
        if let preferredModel = modelManager.userPreferredModel,
           modelManager.availableModels.contains(where: { $0.name == preferredModel }) {
            currentModel = preferredModel
        } else if let firstModel = modelManager.availableModels.first {
            currentModel = firstModel.name
        }
    }
    
    func sendMessage() {
        guard canSendMessage else { return }
        
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ENHANCED: Check for conversational commands FIRST and execute them
        let commandResult = quickChatManager.processAndExecuteConversationalCommand(messageText, projects: &projects)
        
        switch commandResult {
        case .notACommand:
            // Regular message handling - proceed normally
            sendRegularMessage(messageText)
            
        case .projectCreated(let project):
            // Command successfully created project
            let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
            let confirmationMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "✅ Created project '\(project.title)' and moved this conversation there!"
            )
            
            quickChatManager.addMessage(userMessage)
            quickChatManager.addMessage(confirmationMessage)
            
            // Switch to the new project
            withAnimation(.spring()) {
                selectedProject = project
            }
            
        case .movedToProject(let project):
            // Command successfully moved to existing project
            let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
            let confirmationMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "✅ Moved this conversation to '\(project.title)' project!"
            )
            
            quickChatManager.addMessage(userMessage)
            quickChatManager.addMessage(confirmationMessage)
            
            // Switch to the existing project
            withAnimation(.spring()) {
                selectedProject = project
            }
            
        case .organizationTriggered:
            // Command triggered organization panel
            let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
            let responseMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "I'll help you organize this conversation. Let me suggest some options..."
            )
            
            quickChatManager.addMessage(userMessage)
            quickChatManager.addMessage(responseMessage)
            
        case .splitInitiated:
            // Command initiated conversation splitting
            let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
            let responseMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "🚧 Conversation splitting is coming soon! For now, I can help you create a new project."
            )
            
            quickChatManager.addMessage(userMessage)
            quickChatManager.addMessage(responseMessage)
            
        case .error(let errorMessage):
            // Command failed
            let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
            let errorResponseMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "❌ \(errorMessage)"
            )
            
            quickChatManager.addMessage(userMessage)
            quickChatManager.addMessage(errorResponseMessage)
        }
        
        inputText = ""
        
        // Save projects after any command execution
        PersistenceManager.saveProjects(projects)
    }
    
    // FIXED: Moved sendRegularMessage out of local scope and removed private
    func sendRegularMessage(_ messageText: String) {
        let userMessage = ChatMessage(id: UUID(), role: .user, content: messageText)
        
        // Add to quick chat manager or project
        if let selectedProject = selectedProject {
            // Add to existing project
            if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    projects[projectIndex].chats.append(userMessage)
                }
                PersistenceManager.saveProjects(projects)
            }
        } else {
            // Add to quick chat
            quickChatManager.addMessage(userMessage)
        }
        
        isLoading = true
        streamedMessage = ""
        
        // Generate AI response
        Task {
            await generateResponse(for: messageText, context: messages)
        }
    }
    
    func generateResponse(for message: String, context: [ChatMessage]) async {
        guard await ollamaService.isModelAvailable(currentModel) else {
            await handleError("Model '\(currentModel)' is not installed")
            return
        }
        
        let contextMessages = Array(context.suffix(10)) // Use recent context
        
        for await response in ollamaService.generateResponse(
            prompt: message,
            model: currentModel,
            context: contextMessages,
            stream: true
        ) {
            await MainActor.run {
                self.streamedMessage = response.content
                
                if response.isComplete {
                    // Add final message
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response.content
                    )
                    
                    if let selectedProject = selectedProject {
                        // Add to project
                        if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                projects[projectIndex].chats.append(aiMessage)
                            }
                            PersistenceManager.saveProjects(projects)
                        }
                    } else {
                        // Add to quick chat
                        quickChatManager.addMessage(aiMessage)
                    }
                    
                    self.isLoading = false
                    self.streamedMessage = ""
                }
            }
        }
        
        // Fallback if streaming doesn't complete properly
        await MainActor.run {
            if self.isLoading {
                self.isLoading = false
                if !self.streamedMessage.isEmpty {
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: self.streamedMessage
                    )
                    
                    if let selectedProject = selectedProject {
                        if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
                            projects[projectIndex].chats.append(aiMessage)
                            PersistenceManager.saveProjects(projects)
                        }
                    } else {
                        quickChatManager.addMessage(aiMessage)
                    }
                    
                    self.streamedMessage = ""
                }
            }
        }
    }
    
    func handleError(_ message: String) async {
        await MainActor.run {
            let errorMessage = ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "⚠️ \(message)"
            )
            
            if let selectedProject = selectedProject {
                if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
                    projects[projectIndex].chats.append(errorMessage)
                }
            } else {
                quickChatManager.addMessage(errorMessage)
            }
            
            isLoading = false
            streamedMessage = ""
        }
    }
}

// MARK: - Example Prompt Card

struct ExamplePromptCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: UUID())
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}

// MARK: - Revolutionary Message Components

struct RevolutionaryMessageRowView: View {
    let message: ChatMessage
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar with enhanced design
            ZStack {
                Circle()
                    .fill(message.role == .user ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                    .foregroundColor(message.role == .user ? .blue : .green)
                    .font(.system(size: 16, weight: .semibold))
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(message.role == .user ? "You" : "AI Assistant")
                        .font(.caption)
                        .bold()
                        .foregroundColor(message.role == .user ? .blue : .green)
                    
                    Spacer()
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
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
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RevolutionaryStreamingMessageView: View {
    let content: String
    let isComplete: Bool
    @State private var cursorVisible = true
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("AI Assistant")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                    
                    if !isComplete {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 3, height: 3)
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
                    
                    Spacer()
                }
                
                HStack {
                    Text(content)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isComplete && !content.isEmpty {
                        Rectangle()
                            .fill(Color.green)
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
}

struct RevolutionaryLoadingView: View {
    let model: String
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AI Assistant")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
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
                    
                    Text("Thinking with \(model)...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
