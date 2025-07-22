import Foundation
import SwiftUI

// MARK: - KnowledgeFile - Revolutionary File Intelligence Model

struct KnowledgeFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var originalName: String
    var fileExtension: String
    var size: Int64
    var createdAt: Date
    var lastAccessed: Date
    var isProjectLevel: Bool
    var chatId: UUID?
    var localPath: String
    
    // REVOLUTIONARY: Knowledge Intelligence Properties
    var knowledgeMetadata: KnowledgeMetadata
    var aiGeneratedSummary: String?
    var keyPoints: [String] = []
    var relatedFileIds: [UUID] = []
    var relevanceScore: Double = 0.0 // How relevant to current context
    var usageCount: Int = 0
    var lastReferencedInChat: Date?
    var fileRelationships: [FileRelationship] = []
    var aiTags: [String] = []
    var contentCategories: [ContentCategory] = []
    
    // REVOLUTIONARY: Evolution Tracking
    var conversationInfluence: [ConversationInfluence] = []
    var graduationHistory: [GraduationEvent] = []
    
    init(
        name: String,
        originalName: String,
        fileExtension: String,
        size: Int64,
        isProjectLevel: Bool = false,
        chatId: UUID? = nil,
        localPath: String,
        knowledgeMetadata: KnowledgeMetadata
    ) {
        self.id = UUID()
        self.name = name
        self.originalName = originalName
        self.fileExtension = fileExtension
        self.size = size
        self.createdAt = Date()
        self.lastAccessed = Date()
        self.isProjectLevel = isProjectLevel
        self.chatId = chatId
        self.localPath = localPath
        self.knowledgeMetadata = knowledgeMetadata
    }
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isRecentlyUsed: Bool {
        guard let lastReferenced = lastReferencedInChat else { return false }
        return Date().timeIntervalSince(lastReferenced) < 86400 // 24 hours
    }
    
    var shouldGraduateToProject: Bool {
        return !isProjectLevel && usageCount >= 3 && relevanceScore > 0.7
    }
    
    var fileIcon: String {
        switch fileExtension.lowercased() {
        case "txt", "md": return "doc.text.fill"
        case "pdf": return "doc.fill"
        case "docx": return "doc.richtext.fill"
        case "csv": return "tablecells.fill"
        case "json": return "curlybraces"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "js": return "chevron.left.forwardslash.chevron.right"
        case "jpg", "jpeg", "png": return "photo.fill"
        default: return "doc.fill"
        }
    }
    
    var intelligentDescription: String {
        if let summary = aiGeneratedSummary, !summary.isEmpty {
            return summary
        } else if !keyPoints.isEmpty {
            return keyPoints.prefix(2).joined(separator: ", ")
        } else {
            return knowledgeMetadata.detectedContentType.description
        }
    }
}

// MARK: - Content Categories - Smart Categorization

enum ContentCategory: String, Codable, CaseIterable {
    case architecture = "Architecture"
    case design = "Design"
    case implementation = "Implementation"
    case documentation = "Documentation"
    case requirements = "Requirements"
    case testing = "Testing"
    case deployment = "Deployment"
    case research = "Research"
    case planning = "Planning"
    case reference = "Reference"
    case data = "Data"
    case assets = "Assets"
    
    var icon: String {
        switch self {
        case .architecture: return "building.columns.fill"
        case .design: return "paintbrush.fill"
        case .implementation: return "hammer.fill"
        case .documentation: return "book.fill"
        case .requirements: return "checklist"
        case .testing: return "checkmark.circle.fill"
        case .deployment: return "arrow.up.circle.fill"
        case .research: return "magnifyingglass"
        case .planning: return "calendar"
        case .reference: return "bookmark.fill"
        case .data: return "chart.bar.fill"
        case .assets: return "photo.stack.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .architecture: return .blue
        case .design: return .purple
        case .implementation: return .green
        case .documentation: return .orange
        case .requirements: return .red
        case .testing: return .cyan
        case .deployment: return .pink
        case .research: return .yellow
        case .planning: return .indigo
        case .reference: return .gray
        case .data: return .teal
        case .assets: return .mint
        }
    }
}

// MARK: - Conversation Influence - Track File Impact

struct ConversationInfluence: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let chatId: UUID
    let messageIds: [UUID]
    let influenceType: InfluenceType
    let impactScore: Double // How much this file influenced the conversation
    let timestamp: Date
    let contextSummary: String
    
    enum InfluenceType: String, Codable {
        case directReference = "Directly Referenced"
        case contextualHelp = "Provided Context"
        case basedDiscussion = "Based Discussion"
        case clarifiedConcept = "Clarified Concept"
        case contradictedInfo = "Contradicted Info"
        case inspiredIdea = "Inspired Idea"
    }
}

// MARK: - Graduation Events - Track File Evolution

struct GraduationEvent: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let timestamp: Date
    let fromChatId: UUID
    let reason: GraduationReason
    let triggerMetrics: GraduationMetrics
    let userConfirmed: Bool
    
    enum GraduationReason: String, Codable {
        case highUsage = "Frequently Referenced"
        case crossChatReference = "Used Across Chats"
        case aiSuggestion = "AI Recommendation"
        case userPromotion = "User Promoted"
        case projectRelevance = "Project Relevant"
    }
}

struct GraduationMetrics: Codable, Hashable {
    let usageCount: Int
    let uniqueChatsReferenced: Int
    let averageRelevanceScore: Double
    let daysSinceLastUse: Int
    let crossProjectReferences: Int
}
