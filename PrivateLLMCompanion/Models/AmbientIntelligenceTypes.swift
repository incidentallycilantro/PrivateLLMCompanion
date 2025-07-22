import Foundation
import SwiftUI

// MARK: - Ambient Intelligence Types - Supporting Structures

// MARK: - Ambient Suggestions

struct AmbientSuggestion: Identifiable {
    let id: UUID = UUID()
    let type: SuggestionType
    let title: String
    let subtitle: String
    let actionText: String
    let fileId: UUID?
    let confidence: Double
    let showDelay: TimeInterval
    let displayDuration: TimeInterval
    
    enum SuggestionType {
        case relatedFile, graduateFile, compareFiles, summarizeFile, organizeFiles
    }
}

// MARK: - Contextual Recommendations

struct ContextualRecommendation: Identifiable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let recommendedFiles: [KnowledgeFile]
    let actionType: ActionType
    let confidence: Double
    
    enum ActionType {
        case reference, upload, compare, summarize
    }
}

// MARK: - Message Knowledge Context

struct MessageKnowledgeContext {
    let primaryFileId: UUID?
    let supportingFileIds: [UUID]
    let contextType: ContextType
    let relevanceScore: Double
    
    enum ContextType: String, CaseIterable {
        case directReference = "Direct Reference"
        case comparison = "Comparison"
        case contrast = "Contrast"
        case extension = "Building On"
        case contextual = "Contextual"
        
        var icon: String {
            switch self {
            case .directReference: return "link"
            case .comparison: return "equal"
            case .contrast: return "minus.plus.batteryblock"
            case .extension: return "plus.rectangle.on.rectangle"
            case .contextual: return "context.menu.and.cursorarrow"
            }
        }
        
        var color: Color {
            switch self {
            case .directReference: return .blue
            case .comparison: return .green
            case .contrast: return .orange
            case .extension: return .purple
            case .contextual: return .gray
            }
        }
    }
}

// MARK: - Project Knowledge Insights

struct ProjectKnowledgeInsights {
    let totalFiles: Int
    let activeCategories: [ContentCategory]
    let knowledgeConnections: Int
    let averageFileAge: TimeInterval
    let knowledgeCoverage: Double // 0.0 to 1.0
    
    var coverageDescription: String {
        switch knowledgeCoverage {
        case 0.0..<0.3: return "Just getting started"
        case 0.3..<0.6: return "Growing knowledge base"
        case 0.6..<0.9: return "Well documented"
        default: return "Comprehensive coverage"
        }
    }
    
    var coverageColor: Color {
        switch knowledgeCoverage {
        case 0.0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.9: return .blue
        default: return .green
        }
    }
}

// MARK: - Knowledge Health

enum KnowledgeHealth {
    case empty, minimal, active, mature
    
    var description: String {
        switch self {
        case .empty: return "No knowledge files yet"
        case .minimal: return "Getting started"
        case .active: return "Actively growing"
        case .mature: return "Rich knowledge base"
        }
    }
    
    var color: Color {
        switch self {
        case .empty: return .gray
        case .minimal: return .yellow
        case .active: return .green
        case .mature: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .empty: return "folder"
        case .minimal: return "folder.badge.plus"
        case .active: return "folder.fill.badge.plus"
        case .mature: return "brain.head.profile.fill"
        }
    }
}
