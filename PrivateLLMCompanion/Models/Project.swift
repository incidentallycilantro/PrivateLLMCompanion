import Foundation

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var chats: [ChatMessage]
    var projectSummary: String
    var chatSummary: String
    
    // NEW: File system support (for upcoming file features)
    var files: [ProjectFile] = []
    var fileMetadata: [String: String] = [:] // fileId: metadata JSON
    
    // NEW: Organization features (for upcoming tagging/organization)
    var tags: [String] = []
    var isPinned: Bool = false
    var lastAccessed: Date = Date()
    
    static let example = Project(
        id: UUID(),
        title: "Example Project",
        description: "An example project for testing.",
        createdAt: Date(),
        chats: [],
        projectSummary: "Example summary",
        chatSummary: "Chat summary"
    )
}

// NEW: Add this struct AFTER the Project struct
struct ProjectFile: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    var name: String
    var originalName: String
    var fileExtension: String
    var size: Int64
    var createdAt: Date
    var isProjectLevel: Bool // true = project-wide, false = chat-specific
    var chatId: UUID? // which chat uploaded this (if chat-specific)
    var localPath: String // path in app's document directory
    
    init(name: String, originalName: String, fileExtension: String, size: Int64, isProjectLevel: Bool = false, chatId: UUID? = nil, localPath: String) {
        self.name = name
        self.originalName = originalName
        self.fileExtension = fileExtension
        self.size = size
        self.createdAt = Date()
        self.isProjectLevel = isProjectLevel
        self.chatId = chatId
        self.localPath = localPath
    }
}
