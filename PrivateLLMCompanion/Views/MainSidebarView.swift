import SwiftUI
import Combine

struct MainSidebarView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?
    @StateObject private var quickChatManager = QuickChatManager()
    @State private var selectedView: SidebarSelection = .quickChat
    @State private var showingWelcomeAnimation = false
    
    // MARK: - NEW: Knowledge Integration Properties
    @StateObject private var knowledgeManager = KnowledgeManager()
    @State private var showingKnowledgePanel = false
    @State private var showingQuickFileUpload = false
    @State private var selectedRelevantFile: KnowledgeFile?
    @State private var showingFilePreview = false
    @State private var cancellables = Set<AnyCancellable>()
    
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
            // Revolutionary Detail View - UPDATED to use enhanced chat
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
            
            // MARK: - NEW: Setup Knowledge Integration
            setupKnowledgeIntegration()
        }
        .onChange(of: projects) { _, _ in
            // Keep quick chat manager updated with project list for intelligent suggestions
            quickChatManager.updateWithProjects(projects)
        }
        .sheet(isPresented: $showingFilePreview) {
            if let file = selectedRelevantFile {
                KnowledgeFilePreview(
                    file: file,
                    knowledgeManager: knowledgeManager
                )
            }
        }
    }
    
    // MARK: - Revolutionary Sidebar (UNCHANGED)
    
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
    
    // MARK: - Sidebar Header (UNCHANGED)
    
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
    
    // MARK: - Conversation Intelligence Bar (UNCHANGED)
    
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
    
    // MARK: - UPDATED: Revolutionary Detail View with Knowledge Integration
    
    private var revolutionaryDetailView: some View {
        Group {
            switch selectedView {
            case .quickChat:
                // MARK: - UPDATED: Use Enhanced Quick Chat View with Knowledge
                enhancedQuickChatView
                
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
    
    // MARK: - NEW: Enhanced Quick Chat View with Knowledge Integration
    
    private var enhancedQuickChatView: some View {
        VStack(spacing: 0) {
            // Enhanced context header with knowledge indicators
            enhancedContextHeader
            
            // Main chat interface with knowledge panel
            HStack(spacing: 0) {
                // Chat area (existing revolutionary chat)
                RevolutionaryEmbeddedChatView(
                    messages: quickChatManager.currentConversation.messages,
                    selectedProject: $selectedProject,
                    projects: $projects,
                    quickChatManager: quickChatManager
                )
                .frame(minWidth: 400)
                
                // Knowledge panel (toggleable)
                if showingKnowledgePanel {
                    Divider()
                    
                    KnowledgePanel(
                        knowledgeManager: knowledgeManager,
                        project: $currentProjectBinding
                    )
                    .frame(width: 350)
                    .transition(.move(edge: .trailing))
                }
            }
            
            // REVOLUTIONARY: Ambient Organization Panel (EXISTING)
            if quickChatManager.showOrganizationPanel {
                ambientOrganizationPanel
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
            
            // NEW: Contextual recommendations overlay
            if !knowledgeManager.contextualRecommendations.isEmpty {
                contextualRecommendationsOverlay
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - NEW: Enhanced Context Header with Knowledge Intelligence
    
    private var enhancedContextHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: selectedProject != nil ? "folder.fill" : "bolt.circle.fill")
                            .foregroundColor(selectedProject != nil ? .green : .blue)
                        
                        Text(selectedProject?.title ?? "Quick Chat")
                            .font(.headline)
                    }
                    
                    if let project = selectedProject {
                        HStack(spacing: 12) {
                            Text("Project chat • \(project.chats.count) messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // NEW: Knowledge health indicator
                            HStack(spacing: 4) {
                                Image(systemName: project.knowledgeHealth.icon)
                                    .foregroundColor(project.knowledgeHealth.color)
                                    .font(.caption)
                                
                                Text(project.knowledgeHealth.description)
                                    .font(.caption)
                                    .foregroundColor(project.knowledgeHealth.color)
                            }
                        }
                    } else {
                        Text(quickChatManager.getConversationSummary())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // NEW: Knowledge actions
                HStack(spacing: 8) {
                    // Toggle knowledge panel
                    Button(action: { toggleKnowledgePanel() }) {
                        Image(systemName: showingKnowledgePanel ? "sidebar.right" : "sidebar.left")
                            .foregroundColor(.blue)
                    }
                    .help(showingKnowledgePanel ? "Hide Knowledge Panel" : "Show Knowledge Panel")
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    // Quick file upload
                    Button(action: { showingQuickFileUpload = true }) {
                        Image(systemName: "plus.rectangle.on.folder")
                            .foregroundColor(.green)
                    }
                    .help("Add Files")
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    // Manual organization (EXISTING)
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
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // NEW: Intelligent context indicators
            if let project = selectedProject, !knowledgeManager.getKnowledgeFiles(for: project).isEmpty {
                knowledgeContextIndicators(for: project)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - NEW: Knowledge Context Indicators
    
    private func knowledgeContextIndicators(for project: Project) -> some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Relevant files for current conversation
                    let relevantFiles = knowledgeManager.getContextualFiles(
                        for: quickChatManager.currentConversation.messages.map { $0.content }.joined(separator: " "),
                        in: project,
                        limit: 3
                    )
                    
                    if !relevantFiles.isEmpty {
                        ForEach(relevantFiles.prefix(3)) { file in
                            RelevantFileChip(file: file) {
                                selectedRelevantFile = file
                                showingFilePreview = true
                            }
                        }
                    }
                    
                    // Recently used files
                    let recentFiles = knowledgeManager.getKnowledgeFiles(for: project)
                        .filter { $0.isRecentlyUsed }
                        .prefix(2)
                    
                    if !recentFiles.isEmpty {
                        ForEach(recentFiles) { file in
                            RecentFileChip(file: file) {
                                selectedRelevantFile = file
                                showingFilePreview = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - NEW: Contextual Recommendations Overlay
    
    private var contextualRecommendationsOverlay: some View {
        VStack {
            Spacer()
            
            ForEach(knowledgeManager.contextualRecommendations.prefix(2)) { recommendation in
                ContextualRecommendationCard(
                    recommendation: recommendation,
                    onAccept: { acceptRecommendation(recommendation) },
                    onDismiss: { dismissRecommendation(recommendation) }
                )
                .padding(.horizontal)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - EXISTING: Ambient Organization Panel (UNCHANGED)
    
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
    
    // MARK: - NEW: Helper Properties
    
    private var currentProjectBinding: Binding<Project> {
        if let selectedProject = selectedProject,
           let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            return $projects[projectIndex]
        } else {
            // Create a temporary project for quick chat
            return .constant(Project(
                id: UUID(),
                title: "Quick Chat Session",
                description: "Temporary project for quick chat files",
                createdAt: Date(),
                chats: quickChatManager.currentConversation.messages,
                projectSummary: "",
                chatSummary: ""
            ))
        }
    }
    
    // MARK: - NEW: Setup and Actions
    
    private func setupKnowledgeIntegration() {
        // Update knowledge manager when conversation changes
        quickChatManager.$currentConversation
            .sink { conversation in
                Task {
                    await knowledgeManager.generateContextualRecommendations(
                        for: conversation.messages,
                        in: selectedProject ?? currentProjectBinding.wrappedValue
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func toggleKnowledgePanel() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingKnowledgePanel.toggle()
        }
    }
    
    private func acceptRecommendation(_ recommendation: ContextualRecommendation) {
        switch recommendation.actionType {
        case .reference:
            let fileNames = recommendation.recommendedFiles.map { $0.name }.joined(separator: ", ")
            print("Referencing files: \(fileNames)")
            
        case .upload:
            showingQuickFileUpload = true
            
        case .compare:
            if recommendation.recommendedFiles.count >= 2 {
                print("Comparing files...")
            }
            
        case .summarize:
            Task {
                for file in recommendation.recommendedFiles {
                    _ = await knowledgeManager.executeSmartAction(.summarize, on: file)
                }
            }
        }
        
        knowledgeManager.contextualRecommendations.removeAll { $0.id == recommendation.id }
    }
    
    private func dismissRecommendation(_ recommendation: ContextualRecommendation) {
        withAnimation(.easeOut(duration: 0.3)) {
            knowledgeManager.contextualRecommendations.removeAll { $0.id == recommendation.id }
        }
    }
    
    // MARK: - EXISTING: Action Handlers (UNCHANGED)
    
    private func startNewQuickChat() {
        withAnimation(.spring()) {
            selectedProject = nil
            selectedView = .quickChat
            quickChatManager.resetForNewSession()
            quickChatManager.startQuickChat()
        }
    }
    
    // EXISTING: Organization suggestion handler (UNCHANGED)
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
            print("Split conversation feature coming soon")
            
        case .contextSwitch:
            print("Context switch feature coming soon")
        }
    }
}

// MARK: - NEW: Supporting Components for Knowledge Integration

struct RelevantFileChip: View {
    let file: KnowledgeFile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: file.fileIcon)
                    .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                    .font(.caption)
                
                Text(file.name)
                    .font(.caption)
                    .lineLimit(1)
                
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RecentFileChip: View {
    let file: KnowledgeFile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: file.fileIcon)
                    .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                    .font(.caption)
                
                Text(file.name)
                    .font(.caption)
                    .lineLimit(1)
                
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ContextualRecommendationCard: View {
    let recommendation: ContextualRecommendation
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Recommendation type icon
            VStack {
                Image(systemName: recommendationIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("AI")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !recommendation.recommendedFiles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(recommendation.recommendedFiles.prefix(3)) { file in
                                Text(file.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 6) {
                Button(actionButtonText) {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var recommendationIcon: String {
        switch recommendation.actionType {
        case .reference: return "link"
        case .upload: return "plus.rectangle.on.folder"
        case .compare: return "rectangle.split.2x1"
        case .summarize: return "text.alignleft"
        }
    }
    
    private var actionButtonText: String {
        switch recommendation.actionType {
        case .reference: return "Reference"
        case .upload: return "Upload"
        case .compare: return "Compare"
        case .summarize: return "Summarize"
        }
    }
}
