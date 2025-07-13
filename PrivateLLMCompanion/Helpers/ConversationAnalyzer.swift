import Foundation
import Combine

// MARK: - Enhanced Conversation Analysis Engine
// Analyzes chat content with ACTUAL context awareness

class ConversationAnalyzer: ObservableObject {
    
    // MARK: - Analysis Results
    
    struct ConversationInsight {
        let topic: String
        let confidence: Double
        let suggestedProjectName: String
        let keywords: [String]
        let complexity: ConversationComplexity
        let organizationSuggestion: OrganizationSuggestion?
        let contextShift: ContextShift?
        let actualContent: String // NEW: Store actual conversation content for analysis
    }
    
    enum ConversationComplexity {
        case simple         // Basic Q&A, unlikely to need organization
        case developing     // Getting substantial, might need organization
        case substantial    // Definitely worth organizing
        case projectWorthy  // Should be a project
    }
    
    struct OrganizationSuggestion {
        let type: SuggestionType
        let message: String
        let projectName: String?
        let existingProjectId: UUID?
        let confidence: Double
        let timing: SuggestionTiming
        let actionable: Bool
    }
    
    enum SuggestionType: String {
        case createNewProject
        case addToExistingProject
        case splitConversation
        case tagConversation
        case graduateToProject
    }
    
    enum SuggestionTiming: String {
        case immediate      // Show right now
        case nextPause      // Wait for conversation lull
        case endOfSession   // Show when user stops typing
        case manual         // Only if user asks
    }
    
    struct ContextShift {
        let fromTopic: String
        let toTopic: String
        let confidence: Double
        let suggestedAction: String
    }
    
    // MARK: - Published Properties
    
    @Published var currentInsight: ConversationInsight?
    @Published var organizationSuggestions: [OrganizationSuggestion] = []
    @Published var isAnalyzing: Bool = false
    @Published var conversationMetrics: ConversationMetrics = ConversationMetrics()
    
    // MARK: - Private Properties
    
    private var existingProjects: [Project] = []
    private var conversationHistory: [String] = []
    private var topicHistory: [String] = []
    private var userOrganizationPatterns: UserPatterns = UserPatterns()
    private var analysisTimer: Timer?
    
    // MARK: - User Learning
    
    struct UserPatterns: Codable {
        var organizationPreferences: [String: Double] = [:]
        var topicCategories: [String: [String]] = [:]
        var projectNamingStyle: ProjectNamingStyle = .descriptive
        var organizationTriggers: [String] = []
        var dismissedSuggestions: [String] = []
    }
    
    enum ProjectNamingStyle: Codable {
        case descriptive, technical, creative, minimal
    }
    
    struct ConversationMetrics {
        var messageCount: Int = 0
        var averageMessageLength: Int = 0
        var technicalDepth: Double = 0.0
        var topicCoherence: Double = 0.0
        var userEngagement: Double = 0.0
        var projectPotential: Double = 0.0
    }
    
    // MARK: - Initialization
    
    init() {
        loadUserPatterns()
    }
    
    // MARK: - ENHANCED Main Analysis Function with Real Context Awareness
    
    func analyzeConversation(_ messages: [ChatMessage], existingProjects: [Project]) {
        self.existingProjects = existingProjects
        
        guard messages.count >= 2 else { return } // Need at least some conversation
        
        isAnalyzing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let analysis = self.performContextAwareAnalysis(messages)
            
            DispatchQueue.main.async {
                self.currentInsight = analysis
                self.updateConversationMetrics(messages)
                self.generateContextualOrganizationSuggestions(analysis, messages)
                self.isAnalyzing = false
            }
        }
    }
    
    // MARK: - ENHANCED Deep Analysis Engine with REAL Context Understanding
    
    private func performContextAwareAnalysis(_ messages: [ChatMessage]) -> ConversationInsight {
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        
        // ENHANCED: Extract actual content for context-aware analysis
        let recentUserMessages = messages.filter { $0.role == .user }.suffix(3)
        let recentContent = recentUserMessages.map { $0.content }.joined(separator: " ")
        
        // ENHANCED: Real topic extraction based on actual content
        let topic = extractActualTopic(from: conversationText, recentContent: recentContent)
        let keywords = extractContextualKeywords(from: conversationText, recentContent: recentContent)
        
        // Complexity analysis
        let complexity = analyzeComplexity(messages)
        
        // ENHANCED: Context-aware project name suggestion
        let suggestedName = generateContextAwareProjectName(
            topic: topic,
            keywords: keywords,
            recentContent: recentContent
        )
        
        // Context shift detection
        let contextShift = detectContextShift(messages)
        
        // Organization suggestion
        let orgSuggestion = generateContextualOrganizationSuggestion(
            topic: topic,
            complexity: complexity,
            keywords: keywords,
            messageCount: messages.count,
            recentContent: recentContent
        )
        
        return ConversationInsight(
            topic: topic,
            confidence: calculateTopicConfidence(keywords, conversationText),
            suggestedProjectName: suggestedName,
            keywords: keywords,
            complexity: complexity,
            organizationSuggestion: orgSuggestion,
            contextShift: contextShift,
            actualContent: recentContent
        )
    }
    
    // MARK: - ENHANCED Topic Extraction with Real Context Understanding
    
    private func extractActualTopic(from fullText: String, recentContent: String) -> String {
        let analysisText = recentContent.isEmpty ? fullText : recentContent
        let lowercased = analysisText.lowercased()
        
        // ENHANCED: Specific content patterns with actual context
        
        // Animals & Biology
        if lowercased.contains("cat") || lowercased.contains("dog") || lowercased.contains("animal") {
            if lowercased.contains("eyes") || lowercased.contains("vision") || lowercased.contains("see") {
                return "Animal Biology & Vision"
            } else if lowercased.contains("behavior") || lowercased.contains("training") {
                return "Animal Behavior"
            } else {
                return "Animal Science"
            }
        }
        
        // Science & Nature
        if lowercased.contains("science") || lowercased.contains("biology") || lowercased.contains("physics") {
            return "Science Discussion"
        }
        
        if lowercased.contains("vision") || lowercased.contains("eyes") || lowercased.contains("sight") {
            return "Vision & Optics"
        }
        
        // Technology & Development
        if lowercased.contains("react") || lowercased.contains("component") || lowercased.contains("jsx") {
            return "React Development"
        }
        if lowercased.contains("swift") || lowercased.contains("ios") || lowercased.contains("xcode") {
            return "iOS Development"
        }
        if lowercased.contains("api") || lowercased.contains("endpoint") || lowercased.contains("backend") {
            return "API Development"
        }
        if lowercased.contains("database") || lowercased.contains("sql") || lowercased.contains("query") {
            return "Database Design"
        }
        
        // Design & Creative
        if lowercased.contains("design") || lowercased.contains("ui") || lowercased.contains("ux") {
            if lowercased.contains("app") || lowercased.contains("interface") {
                return "App Design"
            } else {
                return "Design Work"
            }
        }
        
        // Business & Client Work
        if lowercased.contains("client") || lowercased.contains("project") || lowercased.contains("deadline") {
            return "Client Work"
        }
        
        // Creative & Learning
        if lowercased.contains("story") || lowercased.contains("write") || lowercased.contains("blog") {
            return "Writing Project"
        }
        if lowercased.contains("learn") || lowercased.contains("tutorial") || lowercased.contains("course") {
            return "Learning Session"
        }
        
        // Education & Questions
        if lowercased.contains("why") || lowercased.contains("how") || lowercased.contains("explain") {
            if lowercased.contains("work") || lowercased.contains("function") {
                return "How Things Work"
            } else {
                return "Q&A Session"
            }
        }
        
        // Default to content-based classification
        if analysisText.count > 100 {
            return "Detailed Discussion"
        } else {
            return "General Chat"
        }
    }
    
    private func extractContextualKeywords(from fullText: String, recentContent: String) -> [String] {
        let analysisText = recentContent.isEmpty ? fullText : recentContent
        let words = analysisText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        // ENHANCED: Context-aware keyword extraction
        let contextualKeywords = [
            // Animals & Biology
            "cats", "dogs", "animals", "eyes", "vision", "sight", "biology", "anatomy",
            "behavior", "training", "pets", "veterinary", "science", "nature",
            
            // Technology
            "react", "swift", "ios", "api", "database", "frontend", "backend",
            "component", "function", "class", "interface", "endpoint", "query",
            "authentication", "deployment", "testing", "debugging", "optimization",
            
            // Design & Creative
            "design", "interface", "user", "experience", "visual", "layout",
            "color", "typography", "branding", "prototype", "wireframe",
            
            // Project & Business
            "client", "project", "deadline", "requirements", "deliverable",
            "milestone", "planning", "architecture", "prototype", "meeting",
            
            // Learning & Education
            "learn", "tutorial", "course", "education", "explain", "understand",
            "research", "study", "analysis", "knowledge", "information"
        ]
        
        let foundKeywords = words.filter { word in
            contextualKeywords.contains(word)
        }
        
        return Array(Set(foundKeywords)).prefix(10).map { $0 }
    }
    
    // MARK: - ENHANCED Context-Aware Project Name Generation
    
    private func generateContextAwareProjectName(topic: String, keywords: [String], recentContent: String) -> String {
        let lowercased = recentContent.lowercased()
        
        // ENHANCED: Generate names based on actual conversation content
        
        // Animal & Biology conversations
        if lowercased.contains("cat") && (lowercased.contains("eyes") || lowercased.contains("vision")) {
            return "Cat Vision Study"
        }
        if lowercased.contains("animal") && lowercased.contains("behavior") {
            return "Animal Behavior Research"
        }
        if lowercased.contains("pet") || lowercased.contains("dog") || lowercased.contains("cat") {
            return "Pet Care & Science"
        }
        
        // Science & Nature
        if lowercased.contains("biology") || lowercased.contains("science") {
            return "Science Exploration"
        }
        if lowercased.contains("vision") || lowercased.contains("eyes") || lowercased.contains("sight") {
            return "Vision Science"
        }
        
        // Technology based on actual content
        if lowercased.contains("react") || lowercased.contains("component") {
            return "React Development"
        }
        if lowercased.contains("swift") || lowercased.contains("ios") {
            return "iOS App Development"
        }
        if lowercased.contains("api") || lowercased.contains("backend") {
            return "API Development"
        }
        
        // Education & Learning
        if lowercased.contains("why") || lowercased.contains("how") || lowercased.contains("explain") {
            return "Learning & Q&A"
        }
        if lowercased.contains("research") || lowercased.contains("study") {
            return "Research Project"
        }
        
        // Use user's naming style preference
        switch userOrganizationPatterns.projectNamingStyle {
        case .descriptive:
            return generateDescriptiveName(topic: topic, keywords: keywords, content: recentContent)
        case .technical:
            return generateTechnicalName(keywords: keywords)
        case .creative:
            return generateCreativeName(topic: topic)
        case .minimal:
            return generateMinimalName(topic: topic)
        }
    }
    
    private func generateDescriptiveName(topic: String, keywords: [String], content: String) -> String {
        // Create descriptive names based on actual content
        if !keywords.isEmpty {
            let primaryKeyword = keywords.first?.capitalized ?? ""
            if content.contains("?") {
                return "\(primaryKeyword) Questions & Research"
            } else {
                return "\(primaryKeyword) \(topic)"
            }
        }
        return topic
    }
    
    private func generateTechnicalName(keywords: [String]) -> String {
        let technicalKeywords = keywords.filter { keyword in
            ["api", "database", "auth", "frontend", "backend", "ios", "react", "swift"].contains(keyword.lowercased())
        }
        
        if technicalKeywords.count >= 2 {
            return technicalKeywords.prefix(2).map { $0.capitalized }.joined(separator: "-")
        } else if let first = technicalKeywords.first {
            return "\(first.capitalized)-Project"
        }
        
        return "Technical-Project"
    }
    
    private func generateCreativeName(topic: String) -> String {
        let creativeWords = ["Journey", "Explorer", "Workshop", "Lab", "Studio", "Discoveries"]
        let randomWord = creativeWords.randomElement() ?? "Project"
        let topicWord = topic.components(separatedBy: " ").first ?? "General"
        return "\(topicWord) \(randomWord)"
    }
    
    private func generateMinimalName(topic: String) -> String {
        return topic.components(separatedBy: " ").first ?? "Project"
    }
    
    // MARK: - Rest of the implementation (complexity analysis, etc.)
    
    private func analyzeComplexity(_ messages: [ChatMessage]) -> ConversationComplexity {
        let messageCount = messages.count
        let totalLength = messages.reduce(0) { $0 + $1.content.count }
        let averageLength = totalLength / max(messageCount, 1)
        
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        let technicalTerms = countTechnicalTerms(conversationText)
        let codeBlocks = conversationText.components(separatedBy: "```").count - 1
        
        // Simple scoring system
        var complexityScore = 0
        
        // Message count factor
        if messageCount > 10 { complexityScore += 2 }
        else if messageCount > 5 { complexityScore += 1 }
        
        // Length factor
        if averageLength > 200 { complexityScore += 2 }
        else if averageLength > 100 { complexityScore += 1 }
        
        // Technical depth
        if technicalTerms > 5 { complexityScore += 2 }
        else if technicalTerms > 2 { complexityScore += 1 }
        
        // Code presence
        if codeBlocks > 0 { complexityScore += 2 }
        
        switch complexityScore {
        case 0...2: return .simple
        case 3...4: return .developing
        case 5...6: return .substantial
        default: return .projectWorthy
        }
    }
    
    private func countTechnicalTerms(_ text: String) -> Int {
        let technicalTerms = [
            "function", "class", "interface", "component", "api", "endpoint",
            "database", "query", "authentication", "authorization", "deployment",
            "testing", "debugging", "optimization", "architecture", "algorithm"
        ]
        
        return technicalTerms.reduce(0) { count, term in
            count + text.lowercased().components(separatedBy: term).count - 1
        }
    }
    
    // MARK: - Enhanced Organization Suggestions
    
    private func generateContextualOrganizationSuggestion(
        topic: String,
        complexity: ConversationComplexity,
        keywords: [String],
        messageCount: Int,
        recentContent: String
    ) -> OrganizationSuggestion? {
        
        // Check if conversation is worth organizing
        guard complexity != .simple else { return nil }
        
        // Check for existing related projects
        let relatedProject = findRelatedProject(topic: topic, keywords: keywords, content: recentContent)
        
        let suggestionType: SuggestionType
        let message: String
        let timing: SuggestionTiming
        
        if let related = relatedProject {
            suggestionType = .addToExistingProject
            message = "This conversation seems related to your '\(related.title)' project. Add it there?"
            timing = .nextPause
        } else {
            switch complexity {
            case .developing:
                suggestionType = .graduateToProject
                message = "This conversation is getting substantial. Should I create a project to keep track of it?"
                timing = .nextPause
            case .substantial, .projectWorthy:
                suggestionType = .createNewProject
                let contextAwareName = generateContextAwareProjectName(topic: topic, keywords: keywords, recentContent: recentContent)
                message = "This looks like project-worthy work! Create a '\(contextAwareName)' project?"
                timing = .immediate
            default:
                return nil
            }
        }
        
        return OrganizationSuggestion(
            type: suggestionType,
            message: message,
            projectName: generateContextAwareProjectName(topic: topic, keywords: keywords, recentContent: recentContent),
            existingProjectId: relatedProject?.id,
            confidence: calculateSuggestionConfidence(complexity, keywords),
            timing: timing,
            actionable: true
        )
    }
    
    private func findRelatedProject(topic: String, keywords: [String], content: String) -> Project? {
        return existingProjects.first { project in
            let projectText = "\(project.title) \(project.description)".lowercased()
            let contentLower = content.lowercased()
            
            // Enhanced matching with actual content
            let topicWords = topic.lowercased().components(separatedBy: " ")
            let contentWords = contentLower.components(separatedBy: " ").filter { $0.count > 3 }
            
            // Check if any topic words match project title/description
            let hasTopicMatch = topicWords.contains { word in
                projectText.contains(word) && word.count > 3
            }
            
            // Check if any content words match
            let hasContentMatch = contentWords.prefix(5).contains { word in
                projectText.contains(word)
            }
            
            // Check if any keywords match
            let hasKeywordMatch = keywords.contains { keyword in
                projectText.contains(keyword.lowercased())
            }
            
            return hasTopicMatch || hasContentMatch || hasKeywordMatch
        }
    }
    
    // MARK: - Context Shift Detection
    
    private func detectContextShift(_ messages: [ChatMessage]) -> ContextShift? {
        guard messages.count >= 4 else { return nil }
        
        let recentMessages = Array(messages.suffix(4))
        let earlierMessages = Array(messages.prefix(messages.count - 2))
        
        let recentTopic = extractActualTopic(
            from: recentMessages.map { $0.content }.joined(separator: " "),
            recentContent: recentMessages.map { $0.content }.joined(separator: " ")
        )
        let earlierTopic = extractActualTopic(
            from: earlierMessages.map { $0.content }.joined(separator: " "),
            recentContent: ""
        )
        
        if recentTopic != earlierTopic && recentTopic != "General Chat" {
            return ContextShift(
                fromTopic: earlierTopic,
                toTopic: recentTopic,
                confidence: 0.8,
                suggestedAction: "Are we switching to discussing \(recentTopic.lowercased()) now?"
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Functions
    
    private func calculateTopicConfidence(_ keywords: [String], _ text: String) -> Double {
        let keywordCount = keywords.count
        let textLength = text.count
        
        if keywordCount == 0 { return 0.3 }
        if keywordCount >= 5 && textLength > 500 { return 0.9 }
        if keywordCount >= 3 && textLength > 200 { return 0.7 }
        return 0.5
    }
    
    private func calculateSuggestionConfidence(_ complexity: ConversationComplexity, _ keywords: [String]) -> Double {
        switch complexity {
        case .simple: return 0.2
        case .developing: return 0.5
        case .substantial: return 0.8
        case .projectWorthy: return 0.95
        }
    }
    
    private func updateConversationMetrics(_ messages: [ChatMessage]) {
        conversationMetrics.messageCount = messages.count
        conversationMetrics.averageMessageLength = messages.isEmpty ? 0 :
            messages.reduce(0) { $0 + $1.content.count } / messages.count
        
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        conversationMetrics.technicalDepth = Double(countTechnicalTerms(conversationText)) / 10.0
        conversationMetrics.projectPotential = Double(currentInsight?.complexity == .projectWorthy ? 1 : 0)
    }
    
    private func generateContextualOrganizationSuggestions(_ insight: ConversationInsight, _ messages: [ChatMessage]) {
        var suggestions: [OrganizationSuggestion] = []
        
        if let orgSuggestion = insight.organizationSuggestion {
            suggestions.append(orgSuggestion)
        }
        
        // Add context shift suggestions
        if let contextShift = insight.contextShift {
            let contextSuggestion = OrganizationSuggestion(
                type: .splitConversation,
                message: contextShift.suggestedAction,
                projectName: nil,
                existingProjectId: nil,
                confidence: contextShift.confidence,
                timing: .nextPause,
                actionable: true
            )
            suggestions.append(contextSuggestion)
        }
        
        organizationSuggestions = suggestions
    }
    
    // MARK: - User Pattern Learning
    
    func recordUserAction(_ action: UserOrganizationAction) {
        switch action {
        case .acceptedSuggestion(let type):
            userOrganizationPatterns.organizationPreferences[type.rawValue] =
                (userOrganizationPatterns.organizationPreferences[type.rawValue] ?? 0.5) + 0.1
        case .dismissedSuggestion(let type):
            userOrganizationPatterns.organizationPreferences[type.rawValue] =
                (userOrganizationPatterns.organizationPreferences[type.rawValue] ?? 0.5) - 0.1
        case .createdProject(let name):
            analyzeProjectNamingPattern(name)
        }
        
        saveUserPatterns()
    }
    
    enum UserOrganizationAction {
        case acceptedSuggestion(SuggestionType)
        case dismissedSuggestion(SuggestionType)
        case createdProject(String)
    }
    
    private func analyzeProjectNamingPattern(_ name: String) {
        let hasNumbers = name.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = name.rangeOfCharacter(from: CharacterSet(charactersIn: "-_")) != nil
        let wordCount = name.components(separatedBy: " ").count
        
        if wordCount == 1 && !hasSpecialChars {
            userOrganizationPatterns.projectNamingStyle = .minimal
        } else if hasSpecialChars || hasNumbers {
            userOrganizationPatterns.projectNamingStyle = .technical
        } else if wordCount > 2 {
            userOrganizationPatterns.projectNamingStyle = .descriptive
        }
    }
    
    // MARK: - Persistence
    
    private func loadUserPatterns() {
        if let data = UserDefaults.standard.data(forKey: "userOrganizationPatterns"),
           let patterns = try? JSONDecoder().decode(UserPatterns.self, from: data) {
            userOrganizationPatterns = patterns
        }
    }
    
    private func saveUserPatterns() {
        if let data = try? JSONEncoder().encode(userOrganizationPatterns) {
            UserDefaults.standard.set(data, forKey: "userOrganizationPatterns")
        }
    }
}
