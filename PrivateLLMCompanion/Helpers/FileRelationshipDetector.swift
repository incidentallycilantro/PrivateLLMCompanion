import Foundation

// MARK: - File Relationship Detector

class FileRelationshipDetector {
    
    func detectRelationships(
        between file1: KnowledgeFile,
        and file2: KnowledgeFile
    ) async -> [FileRelationship] {
        
        var relationships: [FileRelationship] = []
        
        // Get content for both files
        guard let content1 = file1.knowledgeMetadata.extractedText,
              let content2 = file2.knowledgeMetadata.extractedText else {
            return relationships
        }
        
        // Check for similar topics
        let topicSimilarity = calculateTopicSimilarity(file1, file2)
        if topicSimilarity > 0.6 {
            relationships.append(FileRelationship(
                relatedFileId: file2.id,
                relationshipType: .similar_topic,
                strength: topicSimilarity,
                discoveredAt: Date(),
                evidence: ["Similar topics detected", "Shared keywords found"]
            ))
        }
        
        // Check for references
        if content1.lowercased().contains(file2.name.lowercased()) ||
           content2.lowercased().contains(file1.name.lowercased()) {
            relationships.append(FileRelationship(
                relatedFileId: file2.id,
                relationshipType: .references,
                strength: 0.9,
                discoveredAt: Date(),
                evidence: ["File name mentioned in content"]
            ))
        }
        
        // Check for version relationship
        let versionSimilarity = calculateVersionSimilarity(file1, file2)
        if versionSimilarity > 0.8 {
            relationships.append(FileRelationship(
                relatedFileId: file2.id,
                relationshipType: .version_of,
                strength: versionSimilarity,
                discoveredAt: Date(),
                evidence: ["High content similarity suggests version relationship"]
            ))
        }
        
        // Check for implementation relationship
        if detectImplementationRelationship(content1, content2) {
            relationships.append(FileRelationship(
                relatedFileId: file2.id,
                relationshipType: .implements,
                strength: 0.8,
                discoveredAt: Date(),
                evidence: ["Implementation patterns detected"]
            ))
        }
        
        return relationships
    }
    
    private func calculateTopicSimilarity(_ file1: KnowledgeFile, _ file2: KnowledgeFile) -> Double {
        let topics1 = Set(file1.knowledgeMetadata.primaryTopics)
        let topics2 = Set(file2.knowledgeMetadata.primaryTopics)
        
        let intersection = topics1.intersection(topics2)
        let union = topics1.union(topics2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateVersionSimilarity(_ file1: KnowledgeFile, _ file2: KnowledgeFile) -> Double {
        // Simplified version similarity based on content overlap
        guard let content1 = file1.knowledgeMetadata.extractedText,
              let content2 = file2.knowledgeMetadata.extractedText else {
            return 0.0
        }
        
        let words1 = Set(content1.lowercased().components(separatedBy: .whitespacesAndPunctuationCharacters))
        let words2 = Set(content2.lowercased().components(separatedBy: .whitespacesAndPunctuationCharacters))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func detectImplementationRelationship(_ content1: String, _ content2: String) -> Bool {
        // Look for patterns that suggest one file implements concepts from another
        let implementationKeywords = ["implements", "extends", "based on", "according to", "following"]
        
        let combinedContent = (content1 + " " + content2).lowercased()
        
        return implementationKeywords.contains { keyword in
            combinedContent.contains(keyword)
        }
    }
}
