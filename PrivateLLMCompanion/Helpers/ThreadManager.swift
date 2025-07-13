import Foundation
import SwiftUI

// MARK: - Thread Manager - Revolutionary Chat Thread System
// Individual conversations as threads, projects as collections (like ChatGPT + Organization)

class ThreadManager: ObservableObject {
    
    // MARK: - Thread Structure
    
    struct ConversationThread: Identifiable, Codable {
        let id: UUID = UUID()
        var title: String
        var messages: [ChatMessage]
        var createdAt: Date
        var lastActivity: Date
        var projectId: UUID? // Which project this thread belongs to
        var topic: String? // AI-detected topic
        var isArchived: Bool = false
        var isPinned: Bool = false
        
        var summary: String {
            if messages.count <= 1 {
                return "New conversation"
            } else {
                let firstUserMessage = messages.first { $0.role == .user }?.content ?? "Chat"
                return String(firstUserMessage.prefix(40)) + (firstUserMessage.count > 40 ? "..." : "")
            }
        }
        
        var messageCount: Int {
            return messages.count
        }
        
        var lastMessage: ChatMessage? {
            return messages.last
        }
    }
    
    // MARK: - Published Properties
    
    @Published var allThreads: [ConversationThread] = []
    @Published var activeThread: ConversationThread?
    @Published var currentProjectId: UUID?
    
    // MARK: - Thread Management
    
    init() {
        loadThreads()
    }
    
    // Create new thread
    func createNewThread(title: String? = nil, projectId: UUID? = nil) -> ConversationThread {
        let thread = ConversationThread(
            title: title ?? "New Chat",
            messages: [],
            createdAt: Date(),
            lastActivity: Date(),
            projectId: projectId,
            topic: nil
        )
        
        allThreads.append(thread)
        activeThread = thread
        saveThreads()
        
        return thread
    }
    
    // Add message to active thread
    func addMessageToActiveThread(_ message: ChatMessage) {
        guard var thread = activeThread else {
            // Create new thread if none active
            let newThread = createNewThread()
            addMessageToThread(message, threadId: newThread.id)
            return
        }
        
        thread.messages.append(message)
        thread.lastActivity = Date()
        
        // Update thread title based on first user message
        if thread.title == "New Chat" && message.role == .user {
            thread.title = generateThreadTitle(from: message.content)
        }
        
        updateThread(thread)
    }
    
    // Add message to specific thread
    func addMessageToThread(_ message: ChatMessage, threadId: UUID) {
        guard let index = allThreads.firstIndex(where: { $0.id == threadId }) else { return }
        
        allThreads[index].messages.append(message)
        allThreads[index].lastActivity = Date()
        
        if allThreads[index] == activeThread {
            activeThread = allThreads[index]
        }
        
        saveThreads()
    }
    
    // Update existing thread
    func updateThread(_ thread: ConversationThread) {
        guard let index = allThreads.firstIndex(where: { $0.id == thread.id }) else { return }
        
        allThreads[index] = thread
        
        if activeThread?.id == thread.id {
            activeThread = thread
        }
        
        saveThreads()
    }
    
    // Switch to thread
    func switchToThread(_ threadId: UUID) {
        activeThread = allThreads.first { $0.id == threadId }
    }
    
    // Get threads for project
    func getThreadsForProject(_ projectId: UUID) -> [ConversationThread] {
        return allThreads.filter { $0.projectId == projectId }
            .sorted { $0.lastActivity > $1.lastActivity }
    }
    
    // Get unorganized threads (not in any project)
    func getUnorganizedThreads() -> [ConversationThread] {
        return allThreads.filter { $0.projectId == nil }
            .sorted { $0.lastActivity > $1.lastActivity }
    }
    
    // Move thread to project
    func moveThreadToProject(_ threadId: UUID, projectId: UUID?) {
        guard let index = allThreads.firstIndex(where: { $0.id == threadId }) else { return }
        
        allThreads[index].projectId = projectId
        
        if activeThread?.id == threadId {
            activeThread = allThreads[index]
            currentProjectId = projectId
        }
        
        saveThreads()
    }
    
    // Delete thread
    func deleteThread(_ threadId: UUID) {
        allThreads.removeAll { $0.id == threadId }
        
        if activeThread?.id == threadId {
            activeThread = nil
        }
        
        saveThreads()
    }
    
    // Archive/unarchive thread
    func toggleThreadArchive(_ threadId: UUID) {
        guard let index = allThreads.firstIndex(where: { $0.id == threadId }) else { return }
        
        allThreads[index].isArchived.toggle()
        saveThreads()
    }
    
    // Pin/unpin thread
    func toggleThreadPin(_ threadId: UUID) {
        guard let index = allThreads.firstIndex(where: { $0.id == threadId }) else { return }
        
        allThreads[index].isPinned.toggle()
        saveThreads()
    }
    
    // MARK: - Thread Title Generation
    
    private func generateThreadTitle(from content: String) -> String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanContent.count <= 30 {
            return cleanContent
        } else {
            // Take first sentence or first 30 characters
            let sentences = cleanContent.components(separatedBy: [".", "!", "?"])
            if let firstSentence = sentences.first, firstSentence.count <= 40 {
                return firstSentence.trimmingCharacters(in: .whitespaces)
            } else {
                return String(cleanContent.prefix(30)) + "..."
            }
        }
    }
    
    // MARK: - Smart Thread Organization
    
    func suggestThreadOrganization(_ threadId: UUID, basedOn analyzer: ConversationAnalyzer) -> [ThreadOrganizationSuggestion] {
        guard let thread = allThreads.first(where: { $0.id == threadId }) else { return [] }
        
        var suggestions: [ThreadOrganizationSuggestion] = []
        
        // Analyze thread content
        let conversationText = thread.messages.map { $0.content }.joined(separator: " ")
        
        // Suggest project based on content
        if let insight = analyzer.currentInsight {
            suggestions.append(ThreadOrganizationSuggestion(
                type: .createProject,
                title: "Create '\(insight.suggestedProjectName)' project",
                reason: "Based on conversation topic: \(insight.topic)",
                confidence: insight.confidence
            ))
        }
        
        return suggestions
    }
    
    struct ThreadOrganizationSuggestion {
        let type: SuggestionType
        let title: String
        let reason: String
        let confidence: Double
        
        enum SuggestionType {
            case createProject, moveToProject, archiveThread, pinThread
        }
    }
    
    // MARK: - Persistence
    
    private func saveThreads() {
        do {
            let data = try JSONEncoder().encode(allThreads)
            UserDefaults.standard.set(data, forKey: "conversationThreads")
        } catch {
            print("❌ Failed to save threads: \(error)")
        }
    }
    
    private func loadThreads() {
        guard let data = UserDefaults.standard.data(forKey: "conversationThreads") else {
            print("ℹ️ No saved threads found")
            return
        }
        
        do {
            allThreads = try JSONDecoder().decode([ConversationThread].self, from: data)
            print("✅ Loaded \(allThreads.count) conversation threads")
        } catch {
            print("❌ Failed to load threads: \(error)")
            allThreads = []
        }
    }
    
    // MARK: - Integration with Projects
    
    func migrateQuickChatToThread(_ messages: [ChatMessage], title: String = "Quick Chat") -> ConversationThread {
        let thread = ConversationThread(
            title: title,
            messages: messages,
            createdAt: messages.first?.timestamp ?? Date(),
            lastActivity: messages.last?.timestamp ?? Date(),
            projectId: nil,
            topic: nil
        )
        
        allThreads.append(thread)
        activeThread = thread
        saveThreads()
        
        return thread
    }
    
    func getProjectThreadCount(_ projectId: UUID) -> Int {
        return allThreads.filter { $0.projectId == projectId }.count
    }
    
    func getTotalMessageCount(for projectId: UUID) -> Int {
        return allThreads
            .filter { $0.projectId == projectId }
            .reduce(0) { $0 + $1.messageCount }
    }
}

// MARK: - Thread Display Helpers

extension ThreadManager {
    
    func getRecentThreads(limit: Int = 10) -> [ConversationThread] {
        return allThreads
            .filter { !$0.isArchived }
            .sorted { $0.lastActivity > $1.lastActivity }
            .prefix(limit)
            .map { $0 }
    }
    
    func getPinnedThreads() -> [ConversationThread] {
        return allThreads
            .filter { $0.isPinned && !$0.isArchived }
            .sorted { $0.lastActivity > $1.lastActivity }
    }
    
    func searchThreads(query: String) -> [ConversationThread] {
        let lowercaseQuery = query.lowercased()
        
        return allThreads.filter { thread in
            thread.title.lowercased().contains(lowercaseQuery) ||
            thread.messages.contains { message in
                message.content.lowercased().contains(lowercaseQuery)
            }
        }.sorted { $0.lastActivity > $1.lastActivity }
    }
    
    func getThreadStatistics() -> ThreadStatistics {
        let totalThreads = allThreads.count
        let totalMessages = allThreads.reduce(0) { $0 + $1.messageCount }
        let organizedThreads = allThreads.filter { $0.projectId != nil }.count
        let averageMessagesPerThread = totalThreads > 0 ? totalMessages / totalThreads : 0
        
        return ThreadStatistics(
            totalThreads: totalThreads,
            totalMessages: totalMessages,
            organizedThreads: organizedThreads,
            unorganizedThreads: totalThreads - organizedThreads,
            averageMessagesPerThread: averageMessagesPerThread
        )
    }
    
    struct ThreadStatistics {
        let totalThreads: Int
        let totalMessages: Int
        let organizedThreads: Int
        let unorganizedThreads: Int
        let averageMessagesPerThread: Int
    }
}
