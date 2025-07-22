import Foundation
import SwiftUI

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var chats: [ChatMessage]
    var projectSummary: String
    var chatSummary: String
    
    // EXISTING: File system support
    var files: [ProjectFile] = []
    var fileMetadata: [String: String] = [:] // fileId: metadata JSON
    
    // EXISTING: Organization features
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

// EXISTING: ProjectFile struct
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

// MARK: - NEW: Knowledge Intelligence Extensions

extension Project {
    
    // MARK: - Knowledge-aware project properties
    
    var knowledgeHealth: KnowledgeHealth {
        let fileCount = files.count
        let recentFiles = files.filter {
            Date().timeIntervalSince($0.createdAt) < 86400 * 7 // Last week
        }.count
        
        if fileCount == 0 {
            return .empty
        } else if fileCount < 3 {
            return .minimal
        } else if recentFiles > fileCount / 2 {
            return .active
        } else {
            return .mature
        }
    }
    
    // Get knowledge insights about the project
    var knowledgeInsights: ProjectKnowledgeInsights {
        let totalFiles = files.count
        let categories = Set<ContentCategory>([.documentation]) // Simplified - would be calculated properly
        let relationships = 0 // Would count file relationships
        
        return ProjectKnowledgeInsights(
            totalFiles: totalFiles,
            activeCategories: Array(categories),
            knowledgeConnections: relationships,
            averageFileAge: calculateAverageFileAge(),
            knowledgeCoverage: calculateKnowledgeCoverage()
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageFileAge() -> TimeInterval {
        guard !files.isEmpty else { return 0 }
        let totalAge = files.reduce(0) { total, file in
            return total + Date().timeIntervalSince(file.createdAt)
        }
        return totalAge / Double(files.count)
    }
    
    private func calculateKnowledgeCoverage() -> Double {
        // Calculate how well the project is documented
        // This would analyze file types, coverage, relationships, etc.
        return Double(files.count) / 10.0 // Simplified - assume 10 files = 100% coverage
    }
    
    // MARK: - Knowledge Integration Methods
    
    mutating func addKnowledgeFile(_ file: KnowledgeFile) {
        // Convert to ProjectFile for compatibility
        let projectFile = ProjectFile(
            name: file.name,
            originalName: file.originalName,
            fileExtension: file.fileExtension,
            size: file.size,
            isProjectLevel: file.isProjectLevel,
            chatId: file.chatId,
            localPath: file.localPath
        )
        
        files.append(projectFile)
        lastAccessed = Date()
    }
    
    var knowledgeSummary: String {
        let fileCount = files.count
        let recentFiles = files.filter { Date().timeIntervalSince($0.createdAt) < 86400 * 7 }.count
        
        if fileCount == 0 {
            return "No knowledge files yet"
        } else {
            return "\(fileCount) files, \(recentFiles) added recently"
        }
    }
}
