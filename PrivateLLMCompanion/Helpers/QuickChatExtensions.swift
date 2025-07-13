import Foundation
import SwiftUI

// MARK: - Enhanced QuickChatManager Extensions
// Conversational commands that actually work + thread management

extension QuickChatManager {
    
    // ENHANCED: Conversational command detection that actually works
    func enhancedProcessConversationalCommand(_ message: String) -> ConversationalCommand? {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ENHANCED: More comprehensive natural language patterns
        let createProjectPatterns = [
            "create a project", "make this a project", "turn this into a project",
            "organize this as a project", "save this as a project", "project this",
            "make a project called", "create project named", "new project for this",
            "turn this into", "make this into", "organize this into"
        ]
        
        let moveToProjectPatterns = [
            "move this to", "add this to", "put this in", "save to project",
            "move to my", "add to my", "include in", "attach to project",
            "send this to", "transfer to"
        ]
        
        let organizePatterns = [
            "organize this", "organize conversation", "clean this up",
            "structure this", "organize chat", "make this organized",
            "sort this out", "categorize this"
        ]
        
        let splitPatterns = [
            "split this", "divide conversation", "separate this discussion",
            "break this up", "split conversation", "divide this chat"
        ]
        
        // Check create project patterns with enhanced extraction
        for pattern in createProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern) ??
                    generateContextualProjectName()
                return .createProject(name: projectName)
            }
        }
        
        // Check move to project patterns
        for pattern in moveToProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern)
                return .moveToProject(name: projectName)
            }
        }
        
        // Check organize patterns
        for pattern in organizePatterns {
            if lowercased.contains(pattern) {
                return .organizeConversation
            }
        }
        
        // Check split patterns
        for pattern in splitPatterns {
            if lowercased.contains(pattern) {
                return .splitConversation
            }
        }
        
        return nil
    }
    
    // ENHANCED: Generate contextual project name based on actual conversation
    private func generateContextualProjectName() -> String {
        // Get recent conversation content for context-aware naming
        let recentMessages = Array(currentConversation.messages.suffix(3))
        let conversationContent = recentMessages.map { $0.content }.joined(separator: " ").lowercased()
        
        // Enhanced context-aware project naming
        if conversationContent.contains("cat") && (conversationContent.contains("eyes") || conversationContent.contains("vision")) {
            return "Cat Vision Study"
        }
        if conversationContent.contains("animal") && conversationContent.contains("behavior") {
            return "Animal Behavior Research"
        }
        if conversationContent.contains("design") && conversationContent.contains("app") {
            return "App Design Project"
        }
        if conversationContent.contains("react") || conversationContent.contains("component") {
            return "React Development"
        }
        if conversationContent.contains("swift") || conversationContent.contains("ios") {
            return "iOS Development"
        }
        if conversationContent.contains("api") || conversationContent.contains("backend") {
            return "API Development"
        }
        if conversationContent.contains("why") || conversationContent.contains("how") || conversationContent.contains("explain") {
            return "Learning & Q&A"
        }
        
        // Fallback to date-based naming
        let currentDate = DateFormatter()
        currentDate.dateFormat = "MMM dd"
        let dateString = currentDate.string(from: Date())
        
        return "Chat Session - \(dateString)"
    }
    
    private func extractProjectNameFromCommand(_ command: String, pattern: String) -> String? {
        // Find the pattern and extract text after it
        if let range = command.range(of: pattern) {
            let afterPattern = String(command[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Look for common connectors
            let connectors = ["called ", "named ", "for ", "to ", "as ", "about "]
            
            for connector in connectors {
                if let connectorRange = afterPattern.range(of: connector) {
                    let projectName = String(afterPattern[connectorRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: " ")
                        .prefix(4) // Limit to 4 words
                        .joined(separator: " ")
                    
                    return projectName.isEmpty ? nil : projectName.capitalized
                }
            }
            
            // If no connector found, take the next few words
            let words = afterPattern.components(separatedBy: " ").prefix(3)
            let projectName = String(words.joined(separator: " ")).trimmingCharacters(in: CharacterSet.punctuationCharacters)
            
            return projectName.isEmpty ? nil : projectName.capitalized
        }
        
        return nil
    }
}

// MARK: - REVOLUTIONARY: Thread Management System
// Individual conversations as threads, projects as collections

extension QuickChatManager {
    
    // ENHANCED: Thread-based conversation management
    struct ConversationThread {
        let id: UUID = UUID()
        var title: String
        var messages: [ChatMessage]
        var createdAt: Date
        var lastActivity: Date
        var projectId: UUID? // Which project this thread belongs to
        var topic: String? // AI-detected topic
        var isArchived: Bool = false
        
        var summary: String {
            if messages.count <= 2 {
                return "New conversation"
            } else {
                let firstUserMessage = messages.first { $0.role == .user }?.content ?? "Chat"
                return String(firstUserMessage.prefix(50)) + (firstUserMessage.count > 50 ? "..." : "")
            }
        }
    }
    
    // ENHANCED: Project as collection of threads
    struct EnhancedProject {
        let id: UUID
        var title: String
        var description: String
        var threadIds: [UUID] // References to conversation threads
        var createdAt: Date
        var tags: [String]
        var color: ProjectColor
        
        enum ProjectColor: String, CaseIterable {
            case blue, green, orange, purple, red, yellow
        }
    }
    
    // Get all conversation threads
    func getAllConversationThreads() -> [ConversationThread] {
        // This would be loaded from persistence
        // For now, return current conversation as a thread
        if !currentConversation.messages.isEmpty {
            return [ConversationThread(
                title: generateThreadTitle(),
                messages: currentConversation.messages,
                createdAt: currentConversation.sessionStartTime,
                lastActivity: Date(),
                projectId: extractProjectId(),
                topic: analyzer.currentInsight?.topic
            )]
        }
        return []
    }
    
    // Get threads for specific project
    func getThreadsForProject(_ projectId: UUID) -> [ConversationThread] {
        return getAllConversationThreads().filter { $0.projectId == projectId }
    }
    
    // Generate smart thread titles
    private func generateThreadTitle() -> String {
        guard !currentConversation.messages.isEmpty else { return "New Chat" }
        
        let firstUserMessage = currentConversation.messages.first { $0.role == .user }
        let recentContent = currentConversation.messages.suffix(3).map { $0.content }.joined(separator: " ")
        
        if let insight = analyzer.currentInsight {
            return insight.topic
        } else if let firstMessage = firstUserMessage {
            // Generate title from first user message
            let content = firstMessage.content
            if content.count <= 30 {
                return content
            } else {
                return String(content.prefix(30)) + "..."
            }
        } else {
            return "New Conversation"
        }
    }
    
    private func extractProjectId() -> UUID? {
        if case .projectChat(let id) = currentConversation.mode {
            return id
        }
        return nil
    }
}

// MARK: - ENHANCED: Command Processing with Immediate Action
extension QuickChatManager {
    
    // Process conversational commands with immediate execution
    func processAndExecuteConversationalCommand(
        _ message: String,
        projects: inout [Project]
    ) -> CommandExecutionResult {
        
        // First check if this is a command
        guard let command = enhancedProcessConversationalCommand(message) else {
            return .notACommand
        }
        
        // Execute the command immediately
        switch command {
        case .createProject(let name):
            return executeCreateProject(name: name, projects: &projects)
            
        case .moveToProject(let name):
            return executeMoveToProject(name: name, projects: &projects)
            
        case .organizeConversation:
            return executeOrganizeConversation()
            
        case .splitConversation:
            return executeSplitConversation()
        }
    }
    
    enum CommandExecutionResult {
        case notACommand
        case projectCreated(Project)
        case movedToProject(Project)
        case organizationTriggered
        case splitInitiated
        case error(String)
    }
    
    private func executeCreateProject(name: String, projects: inout [Project]) -> CommandExecutionResult {
        // Create the project immediately
        let newProject = graduateToProject(
            projectName: name,
            description: "Created via conversational command",
            projects: &projects
        )
        
        return .projectCreated(newProject)
    }
    
    private func executeMoveToProject(name: String?, projects: inout [Project]) -> CommandExecutionResult {
        guard let projectName = name else {
            return .error("Project name not specified")
        }
        
        // Find matching project
        if let targetProject = projects.first(where: {
            $0.title.lowercased().contains(projectName.lowercased())
        }) {
            let success = moveToExistingProject(projectId: targetProject.id, projects: &projects)
            return success ? .movedToProject(targetProject) : .error("Failed to move to project")
        } else {
            return .error("Project '\(projectName)' not found")
        }
    }
    
    private func executeOrganizeConversation() -> CommandExecutionResult {
        triggerOrganizationSuggestion()
        return .organizationTriggered
    }
    
    private func executeSplitConversation() -> CommandExecutionResult {
        // For now, just trigger organization
        triggerOrganizationSuggestion()
        return .splitInitiated
    }
}
import SwiftUI

// MARK: - Simple QuickChatManager Extensions
// Only contains enhanced command parsing - no problematic analyzer access

extension QuickChatManager {
    
    // Enhanced command parsing with natural language understanding
    func enhancedProcessConversationalCommand(_ message: String) -> ConversationalCommand? {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // More natural language patterns
        let createProjectPatterns = [
            "create a project", "make this a project", "turn this into a project",
            "organize this as a project", "save this as a project", "project this",
            "make a project called", "create project named", "new project for this"
        ]
        
        let moveToProjectPatterns = [
            "move this to", "add this to", "put this in", "save to project",
            "move to my", "add to my", "include in", "attach to project"
        ]
        
        let organizePatterns = [
            "organize this", "organize conversation", "clean this up",
            "structure this", "organize chat", "make this organized"
        ]
        
        let splitPatterns = [
            "split this", "divide conversation", "separate this discussion",
            "break this up", "split conversation", "divide this chat"
        ]
        
        // Check create project patterns
        for pattern in createProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern) ?? "New Project"
                return .createProject(name: projectName)
            }
        }
        
        // Check move to project patterns
        for pattern in moveToProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern)
                return .moveToProject(name: projectName)
            }
        }
        
        // Check organize patterns
        for pattern in organizePatterns {
            if lowercased.contains(pattern) {
                return .organizeConversation
            }
        }
        
        // Check split patterns
        for pattern in splitPatterns {
            if lowercased.contains(pattern) {
                return .splitConversation
            }
        }
        
        return nil
    }
    
    private func extractProjectNameFromCommand(_ command: String, pattern: String) -> String? {
        // Find the pattern and extract text after it
        if let range = command.range(of: pattern) {
            let afterPattern = String(command[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Look for common connectors
            let connectors = ["called ", "named ", "for ", "to ", "as "]
            
            for connector in connectors {
                if let connectorRange = afterPattern.range(of: connector) {
                    let projectName = String(afterPattern[connectorRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: " ")
                        .prefix(4) // Limit to 4 words
                        .joined(separator: " ")
                    
                    return projectName.isEmpty ? nil : projectName.capitalized
                }
            }
            
            // If no connector found, take the next few words
            let words = afterPattern.components(separatedBy: " ").prefix(3)
            let projectName = String(words.joined(separator: " ")).trimmingCharacters(in: CharacterSet.punctuationCharacters)
            
            return projectName.isEmpty ? nil : projectName.capitalized
        }
        
        return nil
    }
}
