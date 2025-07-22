import Foundation
import NaturalLanguage
import Vision
import CoreML

// MARK: - Natural Language Processor - AI-Powered Content Analysis

class NaturalLanguageProcessor {
    
    private let tokenizer = NLTokenizer(unit: .sentence)
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language])
    // Remove the MLModel initialization that might fail
    // private let sentimentPredictor = NLModel(mlModel: try! MLModel(contentsOf: Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc")!))
    
    // MARK: - Core Analysis Functions
    
    func generateSummary(from content: String) async -> String {
        // Extract key sentences using TF-IDF scoring
        let sentences = extractSentences(from: content)
        guard sentences.count > 3 else { return content }
        
        let keyPoints = await extractKeyPoints(from: content)
        let topSentences = extractTopSentences(from: sentences, count: min(3, sentences.count / 3))
        
        // Combine key points with important sentences
        var summary = "Key insights: " + keyPoints.prefix(2).joined(separator: ". ")
        if !topSentences.isEmpty {
            summary += "\n\nImportant details: " + topSentences.joined(separator: " ")
        }
        
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func extractKeyPoints(from content: String) async -> [String] {
        let sentences = extractSentences(from: content)
        var keyPoints: [String] = []
        
        // Score sentences based on keyword frequency and position
        var sentenceScores: [(String, Double)] = []
        
        for (index, sentence) in sentences.enumerated() {
            var score = 0.0
            
            // Position scoring (beginning and end are more important)
            let positionScore = index < 2 ? 0.3 : (index >= sentences.count - 2 ? 0.2 : 0.1)
            score += positionScore
            
            // Keyword scoring
            let keywordScore = scoreKeywords(in: sentence)
            score += keywordScore
            
            // Length scoring (avoid very short or very long sentences)
            let wordCount = sentence.components(separatedBy: .whitespaces).count
            let lengthScore = wordCount >= 8 && wordCount <= 25 ? 0.2 : 0.0
            score += lengthScore
            
            sentenceScores.append((sentence, score))
        }
        
        // Get top scoring sentences as key points
        keyPoints = sentenceScores
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
        
        return keyPoints
    }
    
    func extractTopics(from content: String) async -> [String] {
        var topics: [String] = []
        
        // Extract named entities as potential topics
        tagger.string = content
        let range = content.startIndex..<content.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let token = String(content[tokenRange])
                switch tag {
                case .personalName, .organizationName, .placeName:
                    if token.count > 2 {
                        topics.append(token)
                    }
                default:
                    break
                }
            }
            return true
        }
        
        // Extract technical terms and important concepts
        let technicalTerms = extractTechnicalTerms(from: content)
        topics.append(contentsOf: technicalTerms)
        
        // Remove duplicates and return top topics
        return Array(Set(topics)).prefix(10).map { $0 }
    }
    
    func extractEntities(from content: String) async -> [NamedEntity] {
        var entities: [NamedEntity] = []
        
        tagger.string = content
        let range = content.startIndex..<content.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let token = String(content[tokenRange])
                let entityType: NamedEntity.EntityType
                
                switch tag {
                case .personalName:
                    entityType = .person
                case .organizationName:
                    entityType = .organization
                case .placeName:
                    entityType = .location
                default:
                    entityType = .concept
                }
                
                let entity = NamedEntity(
                    text: token,
                    type: entityType,
                    confidence: 0.8 // Simplified confidence
                )
                
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    func analyzeSentiment(of content: String) async -> SentimentAnalysis {
        // Use NaturalLanguage framework for basic sentiment
        let sentiment = NLTagger(tagSchemes: [.sentimentScore])
        sentiment.string = content
        
        let (sentimentScore, _) = sentiment.tag(at: content.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        let polarity = Double(sentimentScore?.rawValue ?? "0.0") ?? 0.0
        let tone: SentimentAnalysis.Tone
        
        // Determine tone based on content analysis
        if content.lowercased().contains(where: { ["technical", "implementation", "algorithm", "function"].contains(String($0)) }) {
            tone = .technical
        } else if polarity > 0.1 {
            tone = .positive
        } else if polarity < -0.1 {
            tone = .negative
        } else {
            tone = .neutral
        }
        
        return SentimentAnalysis(
            polarity: polarity,
            subjectivity: 0.5, // Simplified
            overallTone: tone
        )
    }
    
    // MARK: - Advanced Analysis Functions
    
    func compareDocuments(_ content1: String, _ content2: String) async -> DocumentComparison {
        let sentences1 = Set(extractSentences(from: content1))
        let sentences2 = Set(extractSentences(from: content2))
        
        let commonSentences = sentences1.intersection(sentences2)
        let uniqueToFirst = sentences1.subtracting(sentences2)
        let uniqueToSecond = sentences2.subtracting(sentences1)
        
        let similarities = Array(commonSentences).prefix(5).map { $0 }
        let differences = Array(uniqueToFirst.union(uniqueToSecond)).prefix(5).map { $0 }
        
        let totalSentences = sentences1.union(sentences2).count
        let similarityScore = Double(commonSentences.count) / Double(totalSentences)
        
        let recommendedAction: String
        if similarityScore > 0.7 {
            recommendedAction = "Consider merging these documents as they cover similar content"
        } else if similarityScore > 0.3 {
            recommendedAction = "These documents complement each other well"
        } else {
            recommendedAction = "These documents cover different topics"
        }
        
        return DocumentComparison(
            similarities: similarities,
            differences: differences,
            overallSimilarity: similarityScore,
            recommendedAction: recommendedAction
        )
    }
    
    func generateQuestions(from content: String) async -> [String] {
        let keyPoints = await extractKeyPoints(from: content)
        var questions: [String] = []
        
        // Generate questions from key points
        for point in keyPoints.prefix(5) {
            if point.contains("because") || point.contains("due to") {
                let question = "Why " + point.components(separatedBy: " because ").first?.lowercased() + "?"
                questions.append(question.prefix(1).uppercased() + question.dropFirst())
            } else if point.contains("when") || point.contains("during") {
                questions.append("When does " + point.lowercased() + "?")
            } else if point.contains("how") || point.contains("method") || point.contains("process") {
                questions.append("How does " + point.lowercased() + "?")
            } else {
                questions.append("What is the significance of " + point.lowercased() + "?")
            }
        }
        
        // Add general questions based on content type
        if content.lowercased().contains("code") || content.lowercased().contains("function") {
            questions.append("What are the potential improvements to this implementation?")
            questions.append("What edge cases should be considered?")
        }
        
        if content.lowercased().contains("design") || content.lowercased().contains("architecture") {
            questions.append("What are the trade-offs of this design approach?")
            questions.append("How does this design scale?")
        }
        
        return questions.prefix(7).map { $0 }
    }
    
    func createOutline(from content: String) async -> DocumentOutline {
        let lines = content.components(separatedBy: .newlines)
        var sections: [OutlineSection] = []
        var currentSection: OutlineSection?
        
        // Detect headings and structure
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Markdown heading detection
            if trimmedLine.hasPrefix("#") {
                let level = trimmedLine.prefix { $0 == "#" }.count
                let title = String(trimmedLine.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                
                if let current = currentSection {
                    sections.append(current)
                }
                
                currentSection = OutlineSection(
                    title: title,
                    level: level,
                    content: nil,
                    subsections: []
                )
            } else if !trimmedLine.isEmpty && currentSection != nil {
                // Add content to current section
                if currentSection!.content == nil {
                    currentSection = OutlineSection(
                        title: currentSection!.title,
                        level: currentSection!.level,
                        content: trimmedLine,
                        subsections: currentSection!.subsections
                    )
                }
            }
        }
        
        // Add the last section
        if let current = currentSection {
            sections.append(current)
        }
        
        // If no markdown headings found, create sections based on paragraphs
        if sections.isEmpty {
            let paragraphs = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for (index, paragraph) in paragraphs.enumerated() {
                let firstSentence = extractSentences(from: paragraph).first ?? "Section \(index + 1)"
                let title = String(firstSentence.prefix(50)) + (firstSentence.count > 50 ? "..." : "")
                
                sections.append(OutlineSection(
                    title: title,
                    level: 1,
                    content: paragraph,
                    subsections: []
                ))
            }
        }
        
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let readingTime = max(1, wordCount / 200)
        
        return DocumentOutline(
            sections: sections,
            totalSections: sections.count,
            estimatedReadingTime: readingTime
        )
    }
    
    func suggestTags(from content: String) async -> [String] {
        var tags: [String] = []
        let lowercaseContent = content.lowercased()
        
        // Technical tags
        let technicalTerms = [
            "api", "database", "algorithm", "architecture", "framework",
            "frontend", "backend", "mobile", "web", "cloud", "security",
            "testing", "deployment", "devops", "ui", "ux", "design"
        ]
        
        for term in technicalTerms {
            if lowercaseContent.contains(term) {
                tags.append(term.capitalized)
            }
        }
        
        // Programming language tags
        let languages = ["swift", "python", "javascript", "java", "cpp", "go", "rust", "kotlin"]
        for language in languages {
            if lowercaseContent.contains(language) {
                tags.append(language.capitalized)
            }
        }
        
        // Content type tags
        if lowercaseContent.contains("tutorial") || lowercaseContent.contains("how to") {
            tags.append("Tutorial")
        }
        if lowercaseContent.contains("documentation") || lowercaseContent.contains("docs") {
            tags.append("Documentation")
        }
        if lowercaseContent.contains("specification") || lowercaseContent.contains("spec") {
            tags.append("Specification")
        }
        if lowercaseContent.contains("research") || lowercaseContent.contains("analysis") {
            tags.append("Research")
        }
        
        // Extract entities as tags
        let entities = await extractEntities(from: content)
        let entityTags = entities.filter { $0.confidence > 0.7 }.map { $0.text }
        tags.append(contentsOf: entityTags)
        
        // Remove duplicates and return top tags
        return Array(Set(tags)).prefix(10).map { $0 }
    }
    
    func translate(_ text: String, to language: String) async -> String {
        // This is a placeholder - in a real app, you'd use a translation service
        // For now, just add a prefix indicating translation
        return "[\(language.uppercased()) Translation] \(text)"
    }
    
    func generateComprehensiveMetadata(from content: String, file: KnowledgeFile) async -> KnowledgeMetadata {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let readingTime = max(1, wordCount / 200)
        
        let topics = await extractTopics(from: content)
        let entities = await extractEntities(from: content)
        let sentiment = await analyzeSentiment(of: content)
        
        let complexity = analyzeContentComplexity(content: content)
        let contentType = detectContentType(content: content, extension: file.fileExtension)
        let documentStructure = analyzeDocumentStructure(content: content)
        
        return KnowledgeMetadata(
            detectedContentType: contentType,
            extractedText: content,
            wordCount: wordCount,
            readingTimeMinutes: readingTime,
            complexity: complexity,
            primaryTopics: topics,
            entities: entities,
            sentiment: sentiment,
            codeLanguages: extractCodeLanguages(from: content),
            imageMetadata: nil, // Would be populated for image files
            documentStructure: documentStructure
        )
    }
    
    // MARK: - Helper Functions
    
    private func extractSentences(from content: String) -> [String] {
        tokenizer.string = content
        var sentences: [String] = []
        
        tokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { tokenRange, _ in
            let sentence = String(content[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty && sentence.count > 10 { // Filter out very short sentences
                sentences.append(sentence)
            }
            return true
        }
        
        return sentences
    }
    
    private func extractTopSentences(from sentences: [String], count: Int) -> [String] {
        // Score sentences based on word frequency and importance
        var sentenceScores: [(String, Double)] = []
        
        // Calculate word frequencies
        let allWords = sentences.joined(separator: " ").lowercased()
            .components(separatedBy: .whitespacesAndPunctuationCharacters)
            .filter { $0.count > 3 }
        
        var wordFreq: [String: Int] = [:]
        for word in allWords {
            wordFreq[word, default: 0] += 1
        }
        
        // Score each sentence
        for sentence in sentences {
            let words = sentence.lowercased()
                .components(separatedBy: .whitespacesAndPunctuationCharacters)
                .filter { $0.count > 3 }
            
            let score = words.reduce(0.0) { total, word in
                return total + Double(wordFreq[word] ?? 0)
            } / Double(words.count)
            
            sentenceScores.append((sentence, score))
        }
        
        return sentenceScores
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { $0.0 }
    }
    
    private func scoreKeywords(in sentence: String) -> Double {
        let importantKeywords = [
            "important", "key", "main", "primary", "essential", "critical",
            "significant", "major", "fundamental", "core", "central",
            "conclusion", "result", "finding", "insight", "discovery"
        ]
        
        let lowercaseSentence = sentence.lowercased()
        var score = 0.0
        
        for keyword in importantKeywords {
            if lowercaseSentence.contains(keyword) {
                score += 0.1
            }
        }
        
        return min(0.5, score) // Cap at 0.5
    }
    
    private func extractTechnicalTerms(from content: String) -> [String] {
        let technicalPatterns = [
            "API", "SDK", "UI", "UX", "HTTP", "REST", "JSON", "XML",
            "database", "algorithm", "framework", "library", "module",
            "function", "method", "class", "interface", "protocol"
        ]
        
        var terms: [String] = []
        let lowercaseContent = content.lowercased()
        
        for pattern in technicalPatterns {
            if lowercaseContent.contains(pattern.lowercased()) {
                terms.append(pattern)
            }
        }
        
        return terms
    }
    
    private func detectContentType(content: String, extension: String) -> KnowledgeMetadata.DetectedContentType {
        let lowercaseContent = content.lowercased()
        
        // Code file detection
        if ["py", "js", "swift", "java", "cpp", "c", "go", "rs"].contains(extension.lowercased()) {
            return .codeFile
        }
        
        // Technical documentation patterns
        if lowercaseContent.contains("api") || lowercaseContent.contains("documentation") ||
           lowercaseContent.contains("technical") || lowercaseContent.contains("specification") {
            return .technicalDocumentation
        }
        
        // Tutorial patterns
        if lowercaseContent.contains("tutorial") || lowercaseContent.contains("how to") ||
           lowercaseContent.contains("step by step") || lowercaseContent.contains("guide") {
            return .tutorial
        }
        
        // Business document patterns
        if lowercaseContent.contains("meeting") || lowercaseContent.contains("proposal") ||
           lowercaseContent.contains("requirements") || lowercaseContent.contains("business") {
            return .businessDocument
        }
        
        // Creative writing patterns
        if lowercaseContent.contains("story") || lowercaseContent.contains("chapter") ||
           lowercaseContent.contains("creative") || lowercaseContent.contains("narrative") {
            return .creativeWriting
        }
        
        return .unknown
    }
    
    private func analyzeContentComplexity(content: String) -> KnowledgeMetadata.ContentComplexity {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        let sentenceCount = content.components(separatedBy: ".").count
        let averageWordsPerSentence = Double(wordCount) / Double(max(1, sentenceCount))
        
        let technicalTermCount = extractTechnicalTerms(from: content).count
        let hasCodeBlocks = content.contains("```") || content.contains("function") || content.contains("class")
        
        var complexityScore = 0
        
        // Sentence length factor
        if averageWordsPerSentence > 20 { complexityScore += 1 }
        if averageWordsPerSentence > 30 { complexityScore += 1 }
        
        // Technical content factor
        if technicalTermCount > 5 { complexityScore += 1 }
        if technicalTermCount > 10 { complexityScore += 1 }
        
        // Code presence factor
        if hasCodeBlocks { complexityScore += 1 }
        
        // Document length factor
        if wordCount > 1000 { complexityScore += 1 }
        if wordCount > 5000 { complexityScore += 1 }
        
        switch complexityScore {
        case 0...1: return .simple
        case 2...3: return .moderate
        case 4...5: return .complex
        default: return .expert
        }
    }
    
    private func analyzeDocumentStructure(content: String) -> DocumentStructure {
        let lines = content.components(separatedBy: .newlines)
        
        var hasHeadings = false
        var sectionCount = 0
        var listCount = 0
        var tableCount = 0
        var hasCodeBlocks = false
        var maxHeadingLevel = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for markdown headings
            if trimmedLine.hasPrefix("#") {
                hasHeadings = true
                sectionCount += 1
                let headingLevel = trimmedLine.prefix { $0 == "#" }.count
                maxHeadingLevel = max(maxHeadingLevel, headingLevel)
            }
            
            // Check for lists
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") ||
               trimmedLine.hasPrefix("+ ") || trimmedLine.range(of: "^\\d+\\.", options: .regularExpression) != nil {
                listCount += 1
            }
            
            // Check for tables
            if trimmedLine.contains("|") && trimmedLine.components(separatedBy: "|").count > 2 {
                tableCount += 1
            }
            
            // Check for code blocks
            if trimmedLine.hasPrefix("```") || trimmedLine.hasPrefix("    ") {
                hasCodeBlocks = true
            }
        }
        
        return DocumentStructure(
            hasHeadings: hasHeadings,
            sectionCount: sectionCount,
            listCount: listCount,
            tableCount: tableCount,
            hasCodeBlocks: hasCodeBlocks,
            outlineDepth: maxHeadingLevel
        )
    }
    
    private func extractCodeLanguages(from content: String) -> [String] {
        var languages: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Look for code block language specifiers
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("```") {
                let languageSpec = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if !languageSpec.isEmpty && languageSpec.count < 20 {
                    languages.append(languageSpec)
                }
            }
        }
        
        // Look for common programming language patterns
        let languagePatterns = [
            ("swift", ["func ", "var ", "let ", "class ", "struct ", "import Foundation"]),
            ("python", ["def ", "import ", "from ", "class ", "__init__"]),
            ("javascript", ["function", "const ", "let ", "var ", "=> "]),
            ("java", ["public class", "private ", "public ", "import java"]),
            ("cpp", ["#include", "using namespace", "int main", "std::"]),
            ("go", ["func ", "package ", "import (", "type "]),
            ("rust", ["fn ", "let ", "use ", "struct ", "impl "])
        ]
        
        let lowercaseContent = content.lowercased()
        for (language, patterns) in languagePatterns {
            let matchCount = patterns.reduce(0) { count, pattern in
                return count + (lowercaseContent.contains(pattern.lowercased()) ? 1 : 0)
            }
            
            if matchCount >= 2 { // Need at least 2 pattern matches
                languages.append(language)
            }
        }
        
        return Array(Set(languages)) // Remove duplicates
    }
}

// MARK: - REMOVED: FileRelationshipDetector class (this was the duplicate causing the error)
// The FileRelationshipDetector class has been moved to its own file

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
