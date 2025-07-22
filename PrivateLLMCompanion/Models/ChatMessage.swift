import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date = Date()
    
    // EXISTING: Message operations support (for upcoming edit/copy/delete features)
    var isEdited: Bool = false
    var editHistory: [MessageEdit] = []
    
    // EXISTING: File references (for upcoming file integration)
    var referencedFiles: [UUID] = [] // IDs of files referenced in this message
    
    // EXISTING: Threading support (for upcoming chat forking)
    var threadId: UUID? = nil
    var parentMessageId: UUID? = nil

    var isUser: Bool {
        role == .user
    }

    static let example = ChatMessage(id: UUID(), role: .user, content: "Example message")
}

// EXISTING: MessageEdit struct
struct MessageEdit: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let originalContent: String
    let editedContent: String
    let editReason: String // "typo", "clarification", "more detail", etc.
    let timestamp: Date = Date()
}

// MARK: - NEW: Knowledge Intelligence Extensions

extension ChatMessage {
    
    // MARK: - Knowledge-aware message properties
    
    var referencedKnowledgeFiles: [UUID] {
        return referencedFiles // Use existing property but treat as knowledge files
    }
    
    var knowledgeContext: MessageKnowledgeContext? {
        guard !referencedKnowledgeFiles.isEmpty else { return nil }
        
        return MessageKnowledgeContext(
            primaryFileId: referencedKnowledgeFiles.first,
            supportingFileIds: Array(referencedKnowledgeFiles.dropFirst()),
            contextType: inferContextType(),
            relevanceScore: calculateRelevanceScore()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func inferContextType() -> MessageKnowledgeContext.ContextType {
        let content = self.content.lowercased()
        
        if content.contains("according to") || content.contains("based on") {
            return .directReference
        } else if content.contains("similar to") || content.contains("like in") {
            return .comparison
        } else if content.contains("unlike") || content.contains("different") {
            return .contrast
        } else if content.contains("building on") || content.contains("extending") {
            return .extension
        } else {
            return .contextual
        }
    }
    
    private func calculateRelevanceScore() -> Double {
        // Calculate how relevant the knowledge files are to this message
        // Would analyze content overlap, semantic similarity, etc.
        return 0.8 // Placeholder
    }
}
