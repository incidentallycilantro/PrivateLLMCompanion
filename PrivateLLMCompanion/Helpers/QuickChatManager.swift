import Foundation
import SwiftUI
import Combine

// MARK: - Quick Chat Manager
// Handles immediate chat access, conversation state, and project graduation

class QuickChatManager: ObservableObject {
    
    // MARK: - Chat State
    
    enum ChatMode {
        case quickChat          // Immediate, unorganized chat
        case projectChat(UUID)  // Attached to a specific project
        case graduatingChat     // In process of becoming a project
    }
    
    struct ConversationState {
        var messages: [ChatMessage] = []
        var mode: ChatMode = .quickChat
        var sessionStartTime: Date = Date()
        var hasBeenOrganized: Bool = false
        var pendingSuggestions: [OrganizationSuggestion] = []
        var conversationTitle: String? = nil
    }
    
    // MARK: - Published Properties
    
    @Published var currentConversation: ConversationState = ConversationState()
    @Published var showOrganizationPanel: Bool = false
    @Published var activeOrganizationSuggestion: OrganizationSuggestion? = nil
    @Published var conversationTransitions: [ConversationTransition] = []
    @Published var isFirstTimeUser: Bool = true
    
    // MARK: - Dependencies
    
    private let conversationAnalyzer = ConversationAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public access to conversation analyzer for extensions
    var analyzer: ConversationAnalyzer {
        return conversationAnalyzer
    }
    
    // MARK: - Organization Suggestions
    
    struct OrganizationSuggestion {
        let id: UUID = UUID()
        let type: SuggestionType
        let title: String
        let subtitle: String
        let primaryAction: String
        let secondaryAction: String?
        let suggestedProjectName: String?
        let existingProjectId: UUID?
        let confidence: Double
        let showTiming: SuggestionTiming
        let isVisible: Bool = false
    }
    
    enum SuggestionType {
        case createProject
        case addToProject
        case splitConversation
        case graduateConversation
        case contextSwitch
    }
    
    enum SuggestionTiming {
        case immediate, onPause, onTypingStop, manual
    }
    
    struct ConversationTransition {
        let id: UUID = UUID()
        let fromMode: ChatMode
        let toMode: ChatMode
        let timestamp: Date
        let reason: String
        let userInitiated: Bool
    }
    
    // MARK: - Conversational Commands
    
    enum ConversationalCommand {
        case createProject(name: String)
        case moveToProject(name: String?)
        case organizeConversation
        case splitConversation
    }
    
    // MARK: - Initialization
    
    init() {
        setupAnalyzerBinding()
        checkFirstTimeUser()
        setupAutoAnalysis()
    }
    
    private func setupAnalyzerBinding() {
        conversationAnalyzer.$organizationSuggestions
            .sink { [weak self] suggestions in
                self?.handleNewSuggestions(suggestions)
            }
            .store(in: &cancellables)
    }
    
    private func checkFirstTimeUser() {
        isFirstTimeUser = !UserDefaults.standard.bool(forKey: "hasUsedQuickChat")
    }
    
    private func setupAutoAnalysis() {
        // Analyze conversation after each message
        $currentConversation
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] conversation in
                guard let self = self else { return }
                if conversation.messages.count >= 2 {
                    self.conversationAnalyzer.analyzeConversation(
                        conversation.messages,
                        existingProjects: []  // Will be injected from MainView
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Core Chat Functions
    
    func startQuickChat() {
        if isFirstTimeUser {
            UserDefaults.standard.set(true, forKey: "hasUsedQuickChat")
            isFirstTimeUser = false
        }
        
        // Reset to fresh quick chat state
        currentConversation = ConversationState()
        showOrganizationPanel = false
        activeOrganizationSuggestion = nil
        
        print("✅ Quick Chat started - immediate access ready")
    }
    
    func addMessage(_ message: ChatMessage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentConversation.messages.append(message)
        }
        
        // Trigger analysis for organization suggestions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkForOrganizationOpportunities()
        }
    }
    
    func graduateToProject(
        projectName: String,
        description: String = "",
        projects: inout [Project]
    ) -> Project {
        let newProject = Project(
            id: UUID(),
            title: projectName,
            description: description,
            createdAt: Date(),
            chats: currentConversation.messages,
            projectSummary: "",
            chatSummary: generateChatSummary()
        )
        
        projects.append(newProject)
        
        // Record the transition
        let transition = ConversationTransition(
            fromMode: currentConversation.mode,
            toMode: .projectChat(newProject.id),
            timestamp: Date(),
            reason: "User graduated conversation to project",
            userInitiated: true
        )
        conversationTransitions.append(transition)
        
        // Update current conversation state
        currentConversation.mode = .projectChat(newProject.id)
        currentConversation.hasBeenOrganized = true
        currentConversation.conversationTitle = projectName
        
        // Clear suggestions
        hideOrganizationPanel()
        
        print("✅ Conversation graduated to project: \(projectName)")
        
        return newProject
    }
    
    func moveToExistingProject(
        projectId: UUID,
        projects: inout [Project]
    ) -> Bool {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            return false
        }
        
        // Add current messages to the existing project
        projects[projectIndex].chats.append(contentsOf: currentConversation.messages)
        
        // Record transition
        let transition = ConversationTransition(
            fromMode: currentConversation.mode,
            toMode: .projectChat(projectId),
            timestamp: Date(),
            reason: "User moved conversation to existing project",
            userInitiated: true
        )
        conversationTransitions.append(transition)
        
        // Update state
        currentConversation.mode = .projectChat(projectId)
        currentConversation.hasBeenOrganized = true
        
        hideOrganizationPanel()
        
        print("✅ Conversation moved to existing project")
        
        return true
    }
    
    // MARK: - Organization Intelligence
    
    private func checkForOrganizationOpportunities() {
        guard !currentConversation.hasBeenOrganized else { return }
        guard currentConversation.messages.count >= 3 else { return }
        
        // Check if conversation is substantial enough for organization
        let messageCount = currentConversation.messages.count
        let totalLength = currentConversation.messages.reduce(0) { $0 + $1.content.count }
        let averageLength = totalLength / messageCount
        
        if messageCount >= 5 && averageLength > 50 {
            // Conversation is getting substantial
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.triggerOrganizationSuggestion()
            }
        }
    }
    
    func triggerOrganizationSuggestion() {
        guard activeOrganizationSuggestion == nil else { return }
        guard !currentConversation.hasBeenOrganized else { return }
        guard currentConversation.messages.count >= 3 else { return }
        
        // Use analyzer's latest insight
        if let insight = conversationAnalyzer.currentInsight,
           let orgSuggestion = insight.organizationSuggestion {
            
            let suggestion = OrganizationSuggestion(
                type: mapSuggestionType(orgSuggestion.type),
                title: generateSuggestionTitle(orgSuggestion.type),
                subtitle: orgSuggestion.message,
                primaryAction: generatePrimaryAction(orgSuggestion.type),
                secondaryAction: "Not now",
                suggestedProjectName: orgSuggestion.projectName,
                existingProjectId: orgSuggestion.existingProjectId,
                confidence: orgSuggestion.confidence,
                showTiming: mapSuggestionTiming(orgSuggestion.timing)
            )
            
            showOrganizationSuggestion(suggestion)
        } else {
            // Fallback: Create a generic organization suggestion
            let genericSuggestion = OrganizationSuggestion(
                type: .graduateConversation,
                title: "Organize This Chat?",
                subtitle: "This conversation is getting substantial. Would you like to create a project for it?",
                primaryAction: "Create Project",
                secondaryAction: "Not now",
                suggestedProjectName: generateFallbackProjectName(),
                existingProjectId: nil,
                confidence: 0.7,
                showTiming: .immediate
            )
            
            showOrganizationSuggestion(genericSuggestion)
        }
    }
    
    private func mapSuggestionType(_ type: ConversationAnalyzer.SuggestionType) -> SuggestionType {
        switch type {
        case .createNewProject: return .createProject
        case .addToExistingProject: return .addToProject
        case .splitConversation: return .splitConversation
        case .graduateToProject: return .graduateConversation
        case .tagConversation: return .createProject // Fallback
        }
    }
    
    private func mapSuggestionTiming(_ timing: ConversationAnalyzer.SuggestionTiming) -> SuggestionTiming {
        switch timing {
        case .immediate: return .immediate
        case .nextPause: return .onPause
        case .endOfSession: return .onTypingStop
        case .manual: return .manual
        }
    }
    
    private func generateSuggestionTitle(_ type: ConversationAnalyzer.SuggestionType) -> String {
        switch type {
        case .createNewProject: return "Create Project?"
        case .addToExistingProject: return "Add to Project?"
        case .splitConversation: return "Split Conversation?"
        case .graduateToProject: return "Organize This Chat?"
        case .tagConversation: return "Tag Conversation?"
        }
    }
    
    private func generatePrimaryAction(_ type: ConversationAnalyzer.SuggestionType) -> String {
        switch type {
        case .createNewProject: return "Create Project"
        case .addToExistingProject: return "Add to Project"
        case .splitConversation: return "Split"
        case .graduateToProject: return "Organize"
        case .tagConversation: return "Tag"
        }
    }
    
    private func showOrganizationSuggestion(_ suggestion: OrganizationSuggestion) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            activeOrganizationSuggestion = suggestion
            showOrganizationPanel = true
        }
        
        // Auto-hide after 15 seconds if not interacted with
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.activeOrganizationSuggestion?.id == suggestion.id {
                self.hideOrganizationPanel()
            }
        }
    }
    
    private func generateFallbackProjectName() -> String {
        let currentDate = DateFormatter()
        currentDate.dateFormat = "MMM dd"
        let dateString = currentDate.string(from: Date())
        
        // Try to extract a topic from recent messages
        let recentMessages = Array(currentConversation.messages.suffix(3))
        let conversationText = recentMessages.map { $0.content }.joined(separator: " ").lowercased()
        
        if conversationText.contains("code") || conversationText.contains("programming") {
            return "Coding Session - \(dateString)"
        } else if conversationText.contains("design") || conversationText.contains("ui") {
            return "Design Work - \(dateString)"
        } else if conversationText.contains("project") || conversationText.contains("plan") {
            return "Project Planning - \(dateString)"
        } else if conversationText.contains("write") || conversationText.contains("content") {
            return "Writing Session - \(dateString)"
        } else {
            return "Chat Session - \(dateString)"
        }
    }
    
    private func handleNewSuggestions(_ suggestions: [ConversationAnalyzer.OrganizationSuggestion]) {
        // Only show one suggestion at a time
        if suggestions.first != nil, activeOrganizationSuggestion == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.triggerOrganizationSuggestion()
            }
        }
    }
    
    // MARK: - Organization Panel Management
    
    func hideOrganizationPanel() {
        withAnimation(.easeOut(duration: 0.3)) {
            showOrganizationPanel = false
            activeOrganizationSuggestion = nil
        }
    }
    
    func acceptOrganizationSuggestion() {
        guard let suggestion = activeOrganizationSuggestion else { return }
        
        // Record user acceptance for learning
        conversationAnalyzer.recordUserAction(.acceptedSuggestion(
            mapToAnalyzerSuggestionType(suggestion.type)
        ))
        
        // The actual organization action will be handled by the calling view
        // This just records the user's preference
        hideOrganizationPanel()
    }
    
    func dismissOrganizationSuggestion() {
        guard let suggestion = activeOrganizationSuggestion else { return }
        
        // Record user dismissal for learning
        conversationAnalyzer.recordUserAction(.dismissedSuggestion(
            mapToAnalyzerSuggestionType(suggestion.type)
        ))
        
        hideOrganizationPanel()
    }
    
    private func mapToAnalyzerSuggestionType(_ type: SuggestionType) -> ConversationAnalyzer.SuggestionType {
        switch type {
        case .createProject: return .createNewProject
        case .addToProject: return .addToExistingProject
        case .splitConversation: return .splitConversation
        case .graduateConversation: return .graduateToProject
        case .contextSwitch: return .tagConversation
        }
    }
    
    // MARK: - Conversational Commands
    
    func processConversationalCommand(_ message: String) -> ConversationalCommand? {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Project creation commands
        if lowercased.hasPrefix("create a project") || lowercased.hasPrefix("make this a project") {
            let projectName = extractProjectNameFromCommand(lowercased) ??
                conversationAnalyzer.currentInsight?.suggestedProjectName ?? "New Project"
            return .createProject(name: projectName)
        }
        
        // Move to project commands
        if lowercased.hasPrefix("move this to") || lowercased.hasPrefix("add this to") {
            let projectName = extractProjectNameFromCommand(lowercased)
            return .moveToProject(name: projectName)
        }
        
        // Organization commands
        if lowercased.contains("organize this") || lowercased.contains("create project") {
            return .organizeConversation
        }
        
        // Split commands
        if lowercased.contains("split this conversation") {
            return .splitConversation
        }
        
        return nil
    }
    
    private func extractProjectNameFromCommand(_ command: String) -> String? {
        // Simple extraction - look for text after "for", "called", "named"
        let patterns = ["for ", "called ", "named ", "to "]
        
        for pattern in patterns {
            if let range = command.range(of: pattern) {
                let afterPattern = String(command[range.upperBound...])
                let projectName = afterPattern.components(separatedBy: " ").prefix(3).joined(separator: " ")
                return projectName.isEmpty ? nil : projectName.capitalized
            }
        }
        
        return nil
    }
    
    // MARK: - Conversation Management
    
    func getConversationSummary() -> String {
        guard !currentConversation.messages.isEmpty else { return "No conversation yet" }
        
        let messageCount = currentConversation.messages.count
        let userMessages = currentConversation.messages.filter { $0.role == .user }.count
        let aiMessages = currentConversation.messages.filter { $0.role == .assistant }.count
        
        let duration = Date().timeIntervalSince(currentConversation.sessionStartTime)
        let durationText = formatDuration(duration)
        
        if let insight = conversationAnalyzer.currentInsight {
            return "\(messageCount) messages • \(insight.topic) • \(durationText)"
        } else {
            return "\(messageCount) messages (\(userMessages) from you, \(aiMessages) responses) • \(durationText)"
        }
    }
    
    private func generateChatSummary() -> String {
        guard !currentConversation.messages.isEmpty else { return "" }
        
        let conversationText = currentConversation.messages
            .prefix(5)
            .map { "\($0.role == .user ? "User" : "AI"): \($0.content)" }
            .joined(separator: "\n")
        
        return "Chat started \(formatDate(currentConversation.sessionStartTime))\n\n\(conversationText)"
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 1 {
            return "just started"
        } else if minutes == 1 {
            return "1 minute"
        } else if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Context Switching
    
    func detectContextSwitch(_ newMessage: String) -> ContextSwitchSuggestion? {
        guard let insight = conversationAnalyzer.currentInsight,
              let contextShift = insight.contextShift else { return nil }
        
        return ContextSwitchSuggestion(
            fromTopic: contextShift.fromTopic,
            toTopic: contextShift.toTopic,
            confidence: contextShift.confidence,
            suggestion: contextShift.suggestedAction,
            shouldCreateNewProject: contextShift.confidence > 0.7
        )
    }
    
    struct ContextSwitchSuggestion {
        let fromTopic: String
        let toTopic: String
        let confidence: Double
        let suggestion: String
        let shouldCreateNewProject: Bool
    }
    
    // MARK: - User Onboarding
    
    func getOnboardingMessage() -> String? {
        if isFirstTimeUser {
            return "👋 Welcome! Start chatting about anything - I'll help you organize as we go."
        } else if currentConversation.messages.isEmpty {
            return "Ready to chat! I'll suggest organizing when our conversation gets substantial."
        }
        return nil
    }
    
    func shouldShowOrganizationHint() -> Bool {
        return currentConversation.messages.count == 5 && !currentConversation.hasBeenOrganized
    }
    
    func getOrganizationHint() -> String {
        return "💡 Tip: I can suggest organizing this conversation into a project when it gets substantial enough."
    }
    
    // MARK: - Analytics and Learning
    
    func getConversationMetrics() -> ConversationMetrics {
        return ConversationMetrics(
            messageCount: currentConversation.messages.count,
            averageMessageLength: currentConversation.messages.isEmpty ? 0 :
                currentConversation.messages.reduce(0) { $0 + $1.content.count } / currentConversation.messages.count,
            sessionDuration: Date().timeIntervalSince(currentConversation.sessionStartTime),
            organizationSuggestionsShown: conversationTransitions.count,
            userOrganizedConversation: currentConversation.hasBeenOrganized,
            topicCoherence: conversationAnalyzer.conversationMetrics.topicCoherence,
            projectPotential: conversationAnalyzer.conversationMetrics.projectPotential
        )
    }
    
    struct ConversationMetrics {
        let messageCount: Int
        let averageMessageLength: Int
        let sessionDuration: TimeInterval
        let organizationSuggestionsShown: Int
        let userOrganizedConversation: Bool
        let topicCoherence: Double
        let projectPotential: Double
    }
    
    // MARK: - Integration Points
    
    func updateWithProjects(_ projects: [Project]) {
        // Update the analyzer with current projects for better suggestions
        conversationAnalyzer.analyzeConversation(
            currentConversation.messages,
            existingProjects: projects
        )
    }
    
    func resetForNewSession() {
        currentConversation = ConversationState()
        hideOrganizationPanel()
        conversationTransitions.removeAll()
    }
    
    // MARK: - User Experience Enhancements
    
    // Provide contextual tips based on conversation state
    func getContextualTip() -> String? {
        let messageCount = currentConversation.messages.count
        
        switch messageCount {
        case 3:
            return "💡 I'm starting to analyze this conversation for organization opportunities"
        case 7:
            return "🎯 This conversation is getting substantial - I might suggest organizing it soon"
        case 12:
            return "📁 You can tell me 'create a project for this' anytime to organize manually"
        case 20:
            return "🚀 Long conversations like this are perfect for project organization"
        default:
            return nil
        }
    }
    
    // Get conversation health metrics
    func getConversationHealth() -> ConversationHealth {
        let messageCount = currentConversation.messages.count
        let averageLength = currentConversation.messages.isEmpty ? 0 :
            currentConversation.messages.reduce(0) { $0 + $1.content.count } / messageCount
        
        let hasCodeBlocks = currentConversation.messages.contains { $0.content.contains("```") }
        let hasTechnicalTerms = currentConversation.messages.contains { message in
            ["function", "class", "api", "database"].contains { message.content.lowercased().contains($0) }
        }
        
        var health: ConversationHealth.HealthLevel = .healthy
        var recommendations: [String] = []
        
        if messageCount > 15 && !currentConversation.hasBeenOrganized {
            health = .needsOrganization
            recommendations.append("Consider organizing this conversation")
        }
        
        if averageLength > 300 {
            health = .complex
            recommendations.append("Messages are getting quite detailed")
        }
        
        if hasCodeBlocks && hasTechnicalTerms {
            recommendations.append("This looks like a coding session - perfect for a project")
        }
        
        return ConversationHealth(
            level: health,
            messageCount: messageCount,
            averageMessageLength: averageLength,
            recommendations: recommendations,
            organizationScore: calculateOrganizationScore()
        )
    }
    
    struct ConversationHealth {
        enum HealthLevel {
            case healthy, complex, needsOrganization, wellOrganized
        }
        
        let level: HealthLevel
        let messageCount: Int
        let averageMessageLength: Int
        let recommendations: [String]
        let organizationScore: Double // 0.0 to 1.0
    }
    
    private func calculateOrganizationScore() -> Double {
        if currentConversation.hasBeenOrganized {
            return 1.0
        }
        
        let messageCount = currentConversation.messages.count
        let complexity = conversationAnalyzer.conversationMetrics.technicalDepth
        let coherence = conversationAnalyzer.conversationMetrics.topicCoherence
        
        // Score based on multiple factors
        var score = 0.0
        
        // Message count factor (more messages = higher organization need)
        score += min(Double(messageCount) / 20.0, 0.4)
        
        // Complexity factor
        score += complexity * 0.3
        
        // Topic coherence (higher coherence = better for organization)
        score += coherence * 0.3
        
        return min(score, 1.0)
    }
}
