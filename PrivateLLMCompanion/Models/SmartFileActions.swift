import Foundation
import SwiftUI

// MARK: - Smart File Actions - Revolutionary AI-Powered Actions

enum SmartFileAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize Content"
    case extractKeyPoints = "Extract Key Points"
    case findRelated = "Find Related Files"
    case compareWith = "Compare With..."
    case generateQuestions = "Generate Questions"
    case createOutline = "Create Outline"
    case detectChanges = "Detect Changes"
    case suggestTags = "Suggest Tags"
    case analyzeComplexity = "Analyze Complexity"
    case extractEntities = "Extract Entities"
    case translateSummary = "Translate Summary"
    case generateMetadata = "Generate Metadata"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .summarize: return "text.alignleft"
        case .extractKeyPoints: return "list.bullet"
        case .findRelated: return "link.circle"
        case .compareWith: return "rectangle.split.2x1"
        case .generateQuestions: return "questionmark.circle"
        case .createOutline: return "list.number"
        case .detectChanges: return "arrow.triangle.2.circlepath"
        case .suggestTags: return "tag"
        case .analyzeComplexity: return "chart.bar"
        case .extractEntities: return "person.2"
        case .translateSummary: return "globe"
        case .generateMetadata: return "info.circle"
        }
    }
    
    var description: String {
        switch self {
        case .summarize: return "Create an AI summary of this file"
        case .extractKeyPoints: return "Extract the main points and insights"
        case .findRelated: return "Find files with similar content"
        case .compareWith: return "Compare this file with another"
        case .generateQuestions: return "Generate discussion questions"
        case .createOutline: return "Create a structured outline"
        case .detectChanges: return "Detect changes from last version"
        case .suggestTags: return "AI-suggest relevant tags"
        case .analyzeComplexity: return "Analyze content complexity"
        case .extractEntities: return "Extract people, places, concepts"
        case .translateSummary: return "Translate summary to other languages"
        case .generateMetadata: return "Generate comprehensive metadata"
        }
    }
}

// MARK: - Smart Action Results

enum SmartActionResult {
    case summary(String)
    case keyPoints([String])
    case relatedFiles([KnowledgeFile])
    case comparison(DocumentComparison)
    case questions([String])
    case outline(DocumentOutline)
    case changes([FileChange])
    case tags([String])
    case complexityAnalysis(ComplexityAnalysis)
    case entities([NamedEntity])
    case translation(String)
    case metadata(KnowledgeMetadata)
    case error(String)
}

// MARK: - Supporting Result Types

struct DocumentComparison {
    let similarities: [String]
    let differences: [String]
    let overallSimilarity: Double
    let recommendedAction: String
}

struct DocumentOutline {
    let sections: [OutlineSection]
    let totalSections: Int
    let estimatedReadingTime: Int
}

struct OutlineSection {
    let title: String
    let level: Int
    let content: String?
    let subsections: [OutlineSection]
}

struct FileChange {
    let type: ChangeType
    let description: String
    let lineNumber: Int?
    
    enum ChangeType {
        case addition, deletion, modification
    }
}

struct ComplexityAnalysis {
    let level: KnowledgeMetadata.ContentComplexity
    let factors: [String]
    let readingTime: Int
    let expertiseRequired: String
}

// MARK: - Smart Action Context

struct SmartActionContext {
    let compareWithFile: KnowledgeFile?
    let targetLanguage: String?
    let additionalParameters: [String: Any]?
}
