import Foundation

// MARK: - Ambient Intelligence Engine

class AmbientIntelligenceEngine {
    
    func generateSuggestions(
        for newFile: KnowledgeFile,
        in project: Project,
        existingFiles: [KnowledgeFile]
    ) async -> [AmbientSuggestion] {
        
        var suggestions: [AmbientSuggestion] = []
        
        // Look for similar files
        let similarFiles = findSimilarFiles(to: newFile, in: existingFiles)
        if !similarFiles.isEmpty {
            let suggestion = AmbientSuggestion(
                type: .relatedFile,
                title: "Similar files detected",
                subtitle: "Found \(similarFiles.count) files with related content",
                actionText: "Show Related",
                fileId: newFile.id,
                confidence: 0.8,
                showDelay: 3.0,
                displayDuration: 12.0
            )
            suggestions.append(suggestion)
        }
        
        // Suggest summarization for large files
        if newFile.knowledgeMetadata.wordCount > 1000 && newFile.aiGeneratedSummary == nil {
            let suggestion = AmbientSuggestion(
                type: .summarizeFile,
                title: "Generate summary?",
                subtitle: "This is a large document (\(newFile.knowledgeMetadata.wordCount) words)",
                actionText: "Summarize",
                fileId: newFile.id,
                confidence: 0.9,
                showDelay: 5.0,
                displayDuration: 15.0
            )
            suggestions.append(suggestion)
        }
        
        return suggestions
    }
    
    func generateContextualRecommendations(
        conversation: [ChatMessage],
        project: Project,
        availableFiles: [KnowledgeFile]
    ) async -> [ContextualRecommendation] {
        
        var recommendations: [ContextualRecommendation] = []
        
        // Analyze recent conversation content
        let recentMessages = conversation.suffix(5)
        let conversationText = recentMessages.map { $0.content }.joined(separator: " ")
        
        // Find relevant files based on conversation content
        let relevantFiles = findRelevantFiles(for: conversationText, in: availableFiles)
        
        if !relevantFiles.isEmpty {
            let recommendation = ContextualRecommendation(
                title: "Relevant files found",
                description: "These files might be helpful for your current discussion",
                recommendedFiles: relevantFiles,
                actionType: .reference,
                confidence: 0.75
            )
            recommendations.append(recommendation)
        }
        
        // Suggest uploading missing files
        if shouldSuggestFileUpload(for: conversationText) {
            let recommendation = ContextualRecommendation(
                title: "Consider uploading supporting files",
                description: "Your discussion might benefit from additional documentation",
                recommendedFiles: [],
                actionType: .upload,
                confidence: 0.6
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    private func findSimilarFiles(to file: KnowledgeFile, in files: [KnowledgeFile]) -> [KnowledgeFile] {
        return files.filter { otherFile in
            otherFile.id != file.id &&
            calculateContentSimilarity(file, otherFile) > 0.6
        }
    }
    
    private func findRelevantFiles(for conversationText: String, in files: [KnowledgeFile]) -> [KnowledgeFile] {
        let conversationWords = Set(conversationText.lowercased()
            .components(separatedBy: .whitespacesAndPunctuationCharacters)
            .filter { $0.count > 3 })
        
        return files.compactMap { file in
            let fileWords = Set((file.knowledgeMetadata.extractedText ?? "").lowercased()
                .components(separatedBy: .whitespacesAndPunctuationCharacters)
                .filter { $0.count > 3 })
            
            let intersection = conversationWords.intersection(fileWords)
            let similarity = Double(intersection.count) / Double(conversationWords.union(fileWords).count)
            
            return similarity > 0.3 ? file : nil
        }
        .sorted { file1, file2 in
            // Sort by relevance score
            file1.relevanceScore > file2.relevanceScore
        }
        .prefix(3)
        .map { $0 }
    }
    
    private func calculateContentSimilarity(_ file1: KnowledgeFile, _ file2: KnowledgeFile) -> Double {
        let topics1 = Set(file1.knowledgeMetadata.primaryTopics)
        let topics2 = Set(file2.knowledgeMetadata.primaryTopics)
        
        let intersection = topics1.intersection(topics2)
        let union = topics1.union(topics2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func shouldSuggestFileUpload(for conversationText: String) -> Bool {
        let uploadTriggers = [
            "documentation", "spec", "requirements", "design", "diagram",
            "screenshot", "example", "reference", "attachment", "file"
        ]
        
        let lowercaseText = conversationText.lowercased()
        return uploadTriggers.contains { trigger in
            lowercaseText.contains(trigger)
        }
    }
}
