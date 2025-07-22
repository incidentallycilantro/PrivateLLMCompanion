import Foundation
import SwiftUI

// MARK: - File Relationships - Revolutionary Connection Intelligence

struct FileRelationship: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let relatedFileId: UUID
    let relationshipType: RelationshipType
    let strength: Double // 0.0 to 1.0
    let discoveredAt: Date
    let evidence: [String] // What suggested this relationship
    
    enum RelationshipType: String, Codable, CaseIterable {
        case references = "References"
        case builds_on = "Builds On"
        case similar_topic = "Similar Topic"
        case same_project = "Same Project"
        case version_of = "Version Of"
        case supplements = "Supplements"
        case contradicts = "Contradicts"
        case implements = "Implements"
        
        func reversedType() -> RelationshipType {
            switch self {
            case .references: return .references
            case .builds_on: return .builds_on
            case .similar_topic: return .similar_topic
            case .same_project: return .same_project
            case .version_of: return .version_of
            case .supplements: return .supplements
            case .contradicts: return .contradicts
            case .implements: return .implements
            }
        }
    }
    
    // Custom CodingKeys to handle the id properly
    enum CodingKeys: String, CodingKey {
        case id, relatedFileId, relationshipType, strength, discoveredAt, evidence
    }
}
