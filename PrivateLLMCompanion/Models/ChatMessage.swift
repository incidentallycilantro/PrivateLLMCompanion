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
    
    // NEW: Message operations support (for upcoming edit/copy/delete features)
    var isEdited: Bool = false
    var editHistory: [MessageEdit] = []
    
    // NEW: File references (for upcoming file integration)
    var referencedFiles: [UUID] = [] // IDs of files referenced in this message
    
    // NEW: Threading support (for upcoming chat forking)
    var threadId: UUID? = nil
    var parentMessageId: UUID? = nil

    var isUser: Bool {
        role == .user
    }

    static let example = ChatMessage(id: UUID(), role: .user, content: "Example message")
}

// NEW: Add this struct AFTER the ChatMessage struct
struct MessageEdit: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let originalContent: String
    let editedContent: String
    let editReason: String // "typo", "clarification", "more detail", etc.
    let timestamp: Date = Date()
}
