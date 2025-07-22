import Foundation
import SwiftUI

// MARK: - Knowledge Metadata - Deep File Understanding

struct KnowledgeMetadata: Codable, Hashable {
    var detectedContentType: DetectedContentType
    var extractedText: String?
    var wordCount: Int = 0
    var readingTimeMinutes: Int = 0
    var complexity: ContentComplexity = .simple
    var primaryTopics: [String] = []
    var entities: [NamedEntity] = []
    var sentiment: SentimentAnalysis?
    var codeLanguages: [String] = [] // For code files
    var imageMetadata: ImageMetadata? // For images
    var documentStructure: DocumentStructure? // For structured docs
    
    enum DetectedContentType: String, Codable {
        case technicalDocumentation
        case codeFile
        case businessDocument
        case creativeWriting
        case dataFile
        case imageFile
        case reference
        case tutorial
        case specification
        case unknown
        
        var description: String {
            switch self {
            case .technicalDocumentation: return "Technical Documentation"
            case .codeFile: return "Code File"
            case .businessDocument: return "Business Document"
            case .creativeWriting: return "Creative Writing"
            case .dataFile: return "Data File"
            case .imageFile: return "Image"
            case .reference: return "Reference Material"
            case .tutorial: return "Tutorial"
            case .specification: return "Specification"
            case .unknown: return "Document"
            }
        }
        
        var color: Color {
            switch self {
            case .technicalDocumentation: return .blue
            case .codeFile: return .green
            case .businessDocument: return .orange
            case .creativeWriting: return .purple
            case .dataFile: return .cyan
            case .imageFile: return .pink
            case .reference: return .gray
            case .tutorial: return .yellow
            case .specification: return .red
            case .unknown: return .secondary
            }
        }
    }
    
    enum ContentComplexity: String, Codable {
        case simple, moderate, complex, expert
        
        var description: String {
            switch self {
            case .simple: return "Simple"
            case .moderate: return "Moderate"
            case .complex: return "Complex"
            case .expert: return "Expert Level"
            }
        }
    }
}

// MARK: - Named Entity Recognition

struct NamedEntity: Codable, Hashable {
    let text: String
    let type: EntityType
    let confidence: Double
    
    enum EntityType: String, Codable {
        case person, organization, location, technology, concept, date, number
    }
}

// MARK: - Sentiment Analysis

struct SentimentAnalysis: Codable, Hashable {
    let polarity: Double // -1.0 to 1.0
    let subjectivity: Double // 0.0 to 1.0
    let overallTone: Tone
    
    enum Tone: String, Codable {
        case positive, neutral, negative, technical, formal, casual
    }
}

// MARK: - Image Metadata

struct ImageMetadata: Codable, Hashable {
    let width: Int
    let height: Int
    let colorSpace: String?
    let hasText: Bool
    let dominantColors: [String]
    let detectedObjects: [String]
}

// MARK: - Document Structure Analysis

struct DocumentStructure: Codable, Hashable {
    let hasHeadings: Bool
    let sectionCount: Int
    let listCount: Int
    let tableCount: Int
    let hasCodeBlocks: Bool
    let outlineDepth: Int
}
