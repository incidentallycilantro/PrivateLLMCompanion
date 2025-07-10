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

    var isUser: Bool {
        role == .user
    }

    static let example = ChatMessage(id: UUID(), role: .user, content: "Example message")
}
