import Foundation

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var chats: [ChatMessage]
    var projectSummary: String
    var chatSummary: String

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
