import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine
import NaturalLanguage
import Vision

// MARK: - Revolutionary Knowledge Manager - The Brain Behind File Intelligence

class KnowledgeManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allKnowledgeFiles: [KnowledgeFile] = []
    @Published var ambientSuggestions: [AmbientSuggestion] = []
    @Published var isProcessingFile = false
    @Published var processingProgress: Double = 0.0
    @Published var fileRelationshipGraph: FileRelationshipGraph = FileRelationshipGraph()
    @Published var contextualRecommendations: [ContextualRecommendation] = []
    
    // MARK: - Core Dependencies
    
    private let fileManager = ProjectFileManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let processingQueue = DispatchQueue(label: "knowledge-processing", qos: .userInitiated)
    private let nlProcessor = NaturalLanguageProcessor()
    private let relationshipDetector = FileRelationshipDetector()
    private let ambientIntelligence = AmbientIntelligenceEngine()
    
    // MARK: - Initialization
    
    init() {
        loadKnowledgeFiles()
        setupAmbientIntelligence()
        startPeriodicRelationshipDetection()
    }
    
    // MARK: - REVOLUTIONARY: Ambient File Intelligence
    
    func processFileWithAmbientIntelligence(
        from url: URL,
        project: Project,
        isProjectLevel: Bool = false,
        chatId: UUID? = nil
    ) async throws -> KnowledgeFile {
        
        await MainActor.run {
            self.isProcessingFile = true
            self.processingProgress = 0.0
        }
        
        // Step 1: Basic file processing (10%)
        let basicFile = try fileManager.saveFile(
            from: url,
            to: project,
            isProjectLevel: isProjectLevel,
            chatId: chatId
        )
        
        await updateProgress(0.1)
        
        // Step 2: Content extraction and analysis (40%)
        let knowledgeMetadata = try await extractKnowledgeMetadata(from: url)
        await updateProgress(0.5)
        
        // Step 3: Create knowledge file with intelligence (20%)
        var knowledgeFile = KnowledgeFile(
            name: basicFile.name,
            originalName: basicFile.originalName,
            fileExtension: basicFile.fileExtension,
            size: basicFile.size,
            isProjectLevel: isProjectLevel,
            chatId: chatId,
            localPath: basicFile.localPath,
            knowledgeMetadata: knowledgeMetadata
        )
        
        await updateProgress(0.7)
        
        // Step 4: REVOLUTIONARY - Ambient relationship detection (20%)
        await detectAmbientRelationships(for: &knowledgeFile, in: project)
        await updateProgress(0.9)
        
        // Step 5: Generate ambient suggestions (10%)
        await generateAmbientSuggestions(for: knowledgeFile, in: project)
        await updateProgress(1.0)
        
        // Save and add to knowledge base
        allKnowledgeFiles.append(knowledgeFile)
        saveKnowledgeFiles()
        
        await MainActor.run {
            self.isProcessingFile = false
            self.processingProgress = 0.0
        }
        
        return knowledgeFile
    }
    
    // MARK: - REVOLUTIONARY: Ambient Relationship Detection
    
    private func detectAmbientRelationships(
        for newFile: inout KnowledgeFile,
        in project: Project
    ) async {
        
        let existingFiles = getKnowledgeFiles(for: project)
        
        for existingFile in existingFiles {
            let relationships = await relationshipDetector.detectRelationships(
                between: newFile,
                and: existingFile
            )
            
            // Add discovered relationships
            for relationship in relationships {
                newFile.fileRelationships.append(relationship)
                
                // REVOLUTIONARY: Add reverse relationship
                if var existingFileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == existingFile.id }) {
                    let reverseRelationship = FileRelationship(
                        relatedFileId: newFile.id,
                        relationshipType: relationship.relationshipType.reverse(),
                        strength: relationship.strength,
                        discoveredAt: Date(),
                        evidence: relationship.evidence
                    )
                    allKnowledgeFiles[existingFileIndex].fileRelationships.append(reverseRelationship)
                }
            }
        }
    }
    
    // MARK: - REVOLUTIONARY: Ambient Suggestions
    
    private func generateAmbientSuggestions(
        for newFile: KnowledgeFile,
        in project: Project
    ) async {
        
        let suggestions = await ambientIntelligence.generateSuggestions(
            for: newFile,
            in: project,
            existingFiles: getKnowledgeFiles(for: project)
        )
        
        await MainActor.run {
            // Add to ambient suggestions with subtle timing
            for suggestion in suggestions {
                DispatchQueue.main.asyncAfter(deadline: .now() + suggestion.showDelay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.ambientSuggestions.append(suggestion)
                    }
                    
                    // Auto-dismiss after some time
                    DispatchQueue.main.asyncAfter(deadline: .now() + suggestion.displayDuration) {
                        self.dismissAmbientSuggestion(suggestion)
                    }
                }
            }
        }
    }
    
    // MARK: - Core File Operations
    
    func getKnowledgeFiles(for project: Project) -> [KnowledgeFile] {
        return allKnowledgeFiles.filter { file in
            if file.isProjectLevel {
                // Would need project ID comparison - simplified for now
                return true
            } else {
                // Chat-level files belong to chats in this project
                return project.chats.contains { chat in
                    file.chatId == chat.id
                }
            }
        }
    }
    
    func getContextualFiles(
        for query: String,
        in project: Project,
        limit: Int = 5
    ) -> [KnowledgeFile] {
        
        let projectFiles = getKnowledgeFiles(for: project)
        
        // REVOLUTIONARY: Semantic similarity scoring
        let scoredFiles = projectFiles.compactMap { file -> (KnowledgeFile, Double)? in
            let relevanceScore = calculateSemanticRelevance(query: query, file: file)
            return relevanceScore > 0.1 ? (file, relevanceScore) : nil
        }
        
        return scoredFiles
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    // MARK: - REVOLUTIONARY: Smart File Actions
    
    func executeSmartAction(
        _ action: SmartFileAction,
        on file: KnowledgeFile,
        with context: SmartActionContext? = nil
    ) async -> SmartActionResult {
        
        switch action {
        case .summarize:
            return await generateFileSummary(file)
            
        case .extractKeyPoints:
            return await extractKeyPoints(from: file)
            
        case .findRelated:
            return await findRelatedFiles(to: file)
            
        case .compareWith:
            guard let compareFile = context?.compareWithFile else {
                return .error("No comparison file specified")
            }
            return await compareFiles(file, with: compareFile)
            
        case .generateQuestions:
            return await generateDiscussionQuestions(for: file)
            
        case .createOutline:
            return await createFileOutline(for: file)
            
        case .detectChanges:
            return await detectFileChanges(for: file)
            
        case .suggestTags:
            return await suggestTags(for: file)
            
        case .analyzeComplexity:
            return await analyzeContentComplexity(of: file)
            
        case .extractEntities:
            return await extractNamedEntities(from: file)
            
        case .translateSummary:
            guard let targetLanguage = context?.targetLanguage else {
                return .error("No target language specified")
            }
            return await translateSummary(of: file, to: targetLanguage)
            
        case .generateMetadata:
            return await generateComprehensiveMetadata(for: file)
        }
    }
    
    // MARK: - REVOLUTIONARY: Contextual Recommendations
    
    func generateContextualRecommendations(
        for conversation: [ChatMessage],
        in project: Project
    ) async {
        
        let recommendations = await ambientIntelligence.generateContextualRecommendations(
            conversation: conversation,
            project: project,
            availableFiles: getKnowledgeFiles(for: project)
        )
        
        await MainActor.run {
            self.contextualRecommendations = recommendations
        }
    }
    
    // MARK: - File Graduation System
    
    func checkForGraduationOpportunities() {
        let chatLevelFiles = allKnowledgeFiles.filter { !$0.isProjectLevel }
        
        for file in chatLevelFiles {
            if file.shouldGraduateToProject {
                let suggestion = AmbientSuggestion(
                    type: .graduateFile,
                    title: "Promote '\(file.name)' to Project Level?",
                    subtitle: "This file has been referenced \(file.usageCount) times across conversations",
                    actionText: "Promote File",
                    fileId: file.id,
                    confidence: 0.8,
                    showDelay: 2.0,
                    displayDuration: 15.0
                )
                
                ambientSuggestions.append(suggestion)
            }
        }
    }
    
    func graduateFileToProject(_ fileId: UUID) {
        guard let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == fileId }) else { return }
        
        let graduationEvent = GraduationEvent(
            timestamp: Date(),
            fromChatId: allKnowledgeFiles[fileIndex].chatId ?? UUID(),
            reason: .aiSuggestion,
            triggerMetrics: GraduationMetrics(
                usageCount: allKnowledgeFiles[fileIndex].usageCount,
                uniqueChatsReferenced: 1, // Simplified
                averageRelevanceScore: allKnowledgeFiles[fileIndex].relevanceScore,
                daysSinceLastUse: 0, // Simplified
                crossProjectReferences: 0
            ),
            userConfirmed: true
        )
        
        allKnowledgeFiles[fileIndex].isProjectLevel = true
        allKnowledgeFiles[fileIndex].chatId = nil
        allKnowledgeFiles[fileIndex].graduationHistory.append(graduationEvent)
        
        saveKnowledgeFiles()
        
        // Remove the suggestion
        ambientSuggestions.removeAll { $0.fileId == fileId }
    }
    
    // MARK: - Smart Action Implementations
    
    private func generateFileSummary(_ file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let summary = await nlProcessor.generateSummary(from: content)
        
        // Update file with generated summary
        if let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == file.id }) {
            allKnowledgeFiles[fileIndex].aiGeneratedSummary = summary
            saveKnowledgeFiles()
        }
        
        return .summary(summary)
    }
    
    private func extractKeyPoints(from file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let keyPoints = await nlProcessor.extractKeyPoints(from: content)
        
        // Update file with key points
        if let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == file.id }) {
            allKnowledgeFiles[fileIndex].keyPoints = keyPoints
            saveKnowledgeFiles()
        }
        
        return .keyPoints(keyPoints)
    }
    
    private func findRelatedFiles(to file: KnowledgeFile) async -> SmartActionResult {
        let relatedFiles = allKnowledgeFiles.filter { otherFile in
            otherFile.id != file.id &&
            file.fileRelationships.contains { $0.relatedFileId == otherFile.id }
        }
        
        let sortedFiles = relatedFiles.sorted { file1, file2 in
            let relationship1 = file.fileRelationships.first { $0.relatedFileId == file1.id }
            let relationship2 = file.fileRelationships.first { $0.relatedFileId == file2.id }
            return (relationship1?.strength ?? 0) > (relationship2?.strength ?? 0)
        }
        
        return .relatedFiles(sortedFiles)
    }
    
    private func compareFiles(_ file1: KnowledgeFile, with file2: KnowledgeFile) async -> SmartActionResult {
        guard let content1 = try? fileManager.readFileContent(for: convertToProjectFile(file1)),
              let content2 = try? fileManager.readFileContent(for: convertToProjectFile(file2)) else {
            return .error("Could not read file contents")
        }
        
        let comparison = await nlProcessor.compareDocuments(content1, content2)
        return .comparison(comparison)
    }
    
    private func generateDiscussionQuestions(for file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let questions = await nlProcessor.generateQuestions(from: content)
        return .questions(questions)
    }
    
    private func createFileOutline(for file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let outline = await nlProcessor.createOutline(from: content)
        return .outline(outline)
    }
    
    private func detectFileChanges(for file: KnowledgeFile) async -> SmartActionResult {
        // This would compare with previous versions if available
        // For now, return a placeholder
        return .changes([])
    }
    
    private func suggestTags(for file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let tags = await nlProcessor.suggestTags(from: content)
        
        // Update file with suggested tags
        if let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == file.id }) {
            allKnowledgeFiles[fileIndex].aiTags = tags
            saveKnowledgeFiles()
        }
        
        return .tags(tags)
    }
    
    private func analyzeContentComplexity(of file: KnowledgeFile) async -> SmartActionResult {
        let complexity = file.knowledgeMetadata.complexity
        let analysis = ComplexityAnalysis(
            level: complexity,
            factors: analyzeComplexityFactors(file),
            readingTime: file.knowledgeMetadata.readingTimeMinutes,
            expertiseRequired: inferExpertiseLevel(complexity)
        )
        
        return .complexityAnalysis(analysis)
    }
    
    private func extractNamedEntities(from file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let entities = await nlProcessor.extractEntities(from: content)
        
        // Update file with entities
        if let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == file.id }) {
            allKnowledgeFiles[fileIndex].knowledgeMetadata.entities = entities
            saveKnowledgeFiles()
        }
        
        return .entities(entities)
    }
    
    private func translateSummary(of file: KnowledgeFile, to language: String) async -> SmartActionResult {
        guard let summary = file.aiGeneratedSummary else {
            // Generate summary first
            let summaryResult = await generateFileSummary(file)
            guard case .summary(let newSummary) = summaryResult else {
                return .error("Could not generate summary for translation")
            }
            
            let translation = await nlProcessor.translate(newSummary, to: language)
            return .translation(translation)
        }
        
        let translation = await nlProcessor.translate(summary, to: language)
        return .translation(translation)
    }
    
    private func generateComprehensiveMetadata(for file: KnowledgeFile) async -> SmartActionResult {
        guard let content = try? fileManager.readFileContent(for: convertToProjectFile(file)) else {
            return .error("Could not read file content")
        }
        
        let metadata = await nlProcessor.generateComprehensiveMetadata(from: content, file: file)
        
        // Update file with comprehensive metadata
        if let fileIndex = allKnowledgeFiles.firstIndex(where: { $0.id == file.id }) {
            allKnowledgeFiles[fileIndex].knowledgeMetadata = metadata
            saveKnowledgeFiles()
        }
        
        return .metadata(metadata)
    }
    
    // MARK: - Helper Functions
    
    private func extractKnowledgeMetadata(from url: URL) async throws -> KnowledgeMetadata {
        let content = try String(contentsOf: url, encoding: .utf8)
        let fileExtension = url.pathExtension.lowercased()
        
        let detectedType = detectContentType(content: content, extension: fileExtension)
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let readingTime = max(1, wordCount / 200) // Assume 200 words per minute
        let complexity = analyzeComplexity(content: content)
        let topics = await nlProcessor.extractTopics(from: content)
        
        return KnowledgeMetadata(
            detectedContentType: detectedType,
            extractedText: content,
            wordCount: wordCount,
            readingTimeMinutes: readingTime,
            complexity: complexity,
            primaryTopics: topics
        )
    }
    
    private func detectContentType(content: String, extension: String) -> KnowledgeMetadata.DetectedContentType {
        let lowercaseContent = content.lowercased()
        
        // Code file detection
        if ["py", "js", "swift", "java", "cpp", "c", "go", "rs"].contains(extension) {
            return .codeFile
        }
        
        // Technical documentation patterns
        if lowercaseContent.contains("api") || lowercaseContent.contains("documentation") ||
           lowercaseContent.contains("technical") || lowercaseContent.contains("specification") {
            return .technicalDocumentation
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
        
        // Tutorial patterns
        if lowercaseContent.contains("tutorial") || lowercaseContent.contains("how to") ||
           lowercaseContent.contains("step by step") || lowercaseContent.contains("guide") {
            return .tutorial
        }
        
        // Data file detection
        if extension == "csv" || extension == "json" || lowercaseContent.contains("data") {
            return .dataFile
        }
        
        return .unknown
    }
    
    private func analyzeComplexity(content: String) -> KnowledgeMetadata.ContentComplexity {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        let sentenceCount = content.components(separatedBy: ".").count
        let averageWordsPerSentence = wordCount / max(1, sentenceCount)
        
        let technicalTerms = countTechnicalTerms(in: content)
        let complexityScore = Double(averageWordsPerSentence) / 15.0 + Double(technicalTerms) / 10.0
        
        switch complexityScore {
        case 0.0..<1.0: return .simple
        case 1.0..<2.0: return .moderate
        case 2.0..<3.0: return .complex
        default: return .expert
        }
    }
    
    private func countTechnicalTerms(in content: String) -> Int {
        let technicalPatterns = [
            "algorithm", "implementation", "architecture", "framework", "methodology",
            "optimization", "configuration", "deployment", "integration", "specification"
        ]
        
        return technicalPatterns.reduce(0) { count, term in
            count + content.lowercased().components(separatedBy: term).count - 1
        }
    }
    
    private func calculateSemanticRelevance(query: String, file: KnowledgeFile) -> Double {
        // Simplified semantic relevance calculation
        // In a real implementation, this would use vector embeddings or similar
        
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let fileContent = file.knowledgeMetadata.extractedText?.lowercased() ?? ""
        let fileWords = Set(fileContent.components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = queryWords.intersection(fileWords)
        let union = queryWords.union(fileWords)
        
        let jaccardSimilarity = Double(intersection.count) / Double(union.count)
        
        // Boost relevance based on recent usage
        let recencyBoost = file.isRecentlyUsed ? 0.2 : 0.0
        
        // Boost relevance based on file relationships
        let relationshipBoost = file.fileRelationships.isEmpty ? 0.0 : 0.1
        
        return min(1.0, jaccardSimilarity + recencyBoost + relationshipBoost)
    }
    
    private func analyzeComplexityFactors(_ file: KnowledgeFile) -> [String] {
        var factors: [String] = []
        
        let metadata = file.knowledgeMetadata
        
        if metadata.wordCount > 5000 {
            factors.append("Long document (\(metadata.wordCount) words)")
        }
        
        if !metadata.entities.isEmpty {
            factors.append("Contains \(metadata.entities.count) named entities")
        }
        
        if metadata.documentStructure?.hasCodeBlocks == true {
            factors.append("Contains code examples")
        }
        
        if !metadata.codeLanguages.isEmpty {
            factors.append("Multiple programming languages")
        }
        
        return factors
    }
    
    private func inferExpertiseLevel(_ complexity: KnowledgeMetadata.ContentComplexity) -> String {
        switch complexity {
        case .simple: return "Beginner friendly"
        case .moderate: return "Some experience helpful"
        case .complex: return "Intermediate to advanced"
        case .expert: return "Expert level knowledge required"
        }
    }
    
    private func convertToProjectFile(_ knowledgeFile: KnowledgeFile) -> ProjectFile {
        return ProjectFile(
            name: knowledgeFile.name,
            originalName: knowledgeFile.originalName,
            fileExtension: knowledgeFile.fileExtension,
            size: knowledgeFile.size,
            isProjectLevel: knowledgeFile.isProjectLevel,
            chatId: knowledgeFile.chatId,
            localPath: knowledgeFile.localPath
        )
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.processingProgress = progress
        }
    }
    
    // MARK: - Ambient Intelligence Management
    
    private func setupAmbientIntelligence() {
        // Monitor file usage patterns
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task {
                await self.updateFileRelevanceScores()
                self.checkForGraduationOpportunities()
            }
        }
    }
    
    private func startPeriodicRelationshipDetection() {
        // Periodically discover new relationships
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in // Every hour
            Task {
                await self.discoverNewRelationships()
            }
        }
    }
    
    private func updateFileRelevanceScores() async {
        for (index, file) in allKnowledgeFiles.enumerated() {
            let newScore = calculateDynamicRelevanceScore(for: file)
            allKnowledgeFiles[index].relevanceScore = newScore
        }
        saveKnowledgeFiles()
    }
    
    private func calculateDynamicRelevanceScore(for file: KnowledgeFile) -> Double {
        var score = 0.0
        
        // Usage frequency factor
        score += min(0.4, Double(file.usageCount) / 10.0)
        
        // Recency factor
        if let lastReferenced = file.lastReferencedInChat {
            let daysSince = Date().timeIntervalSince(lastReferenced) / 86400
            score += max(0.0, 0.3 - daysSince / 30.0) // Decay over 30 days
        }
        
        // Relationship factor
        let strongRelationships = file.fileRelationships.filter { $0.strength > 0.7 }.count
        score += min(0.3, Double(strongRelationships) / 5.0)
        
        return min(1.0, score)
    }
    
    private func discoverNewRelationships() async {
        // Compare all files to find new relationships
        for i in 0..<allKnowledgeFiles.count {
            for j in (i+1)..<allKnowledgeFiles.count {
                let file1 = allKnowledgeFiles[i]
                let file2 = allKnowledgeFiles[j]
                
                // Check if relationship already exists
                let hasExistingRelationship = file1.fileRelationships.contains {
                    $0.relatedFileId == file2.id
                }
                
                if !hasExistingRelationship {
                    let relationships = await relationshipDetector.detectRelationships(
                        between: file1,
                        and: file2
                    )
                    
                    // Add any discovered relationships
                    for relationship in relationships {
                        allKnowledgeFiles[i].fileRelationships.append(relationship)
                        
                        let reverseRelationship = FileRelationship(
                            relatedFileId: file1.id,
                            relationshipType: relationship.relationshipType.reverse(),
                            strength: relationship.strength,
                            discoveredAt: Date(),
                            evidence: relationship.evidence
                        )
                        allKnowledgeFiles[j].fileRelationships.append(reverseRelationship)
                    }
                }
            }
        }
        
        saveKnowledgeFiles()
    }
    
    func dismissAmbientSuggestion(_ suggestion: AmbientSuggestion) {
        withAnimation(.easeOut(duration: 0.3)) {
            ambientSuggestions.removeAll { $0.id == suggestion.id }
        }
    }
    
    // MARK: - Persistence
    
    private func loadKnowledgeFiles() {
        guard let data = UserDefaults.standard.data(forKey: "knowledgeFiles") else { return }
        
        do {
            allKnowledgeFiles = try JSONDecoder().decode([KnowledgeFile].self, from: data)
        } catch {
            print("❌ Failed to load knowledge files: \(error)")
            allKnowledgeFiles = []
        }
    }
    
    private func saveKnowledgeFiles() {
        do {
            let data = try JSONEncoder().encode(allKnowledgeFiles)
            UserDefaults.standard.set(data, forKey: "knowledgeFiles")
        } catch {
            print("❌ Failed to save knowledge files: \(error)")
        }
    }
}

// MARK: - Supporting Types

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

struct SmartActionContext {
    let compareWithFile: KnowledgeFile?
    let targetLanguage: String?
    let additionalParameters: [String: Any]?
}

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

struct FileRelationshipGraph {
    var nodes: [FileNode] = []
    var edges: [RelationshipEdge] = []
}

struct FileNode {
    let fileId: UUID
    let position: CGPoint
    let strength: Double
}

struct RelationshipEdge {
    let fromFileId: UUID
    let toFileId: UUID
    let relationshipType: FileRelationship.RelationshipType
    let strength: Double
}

// MARK: - Extension for Relationship Type Reversal

extension FileRelationship.RelationshipType {
    func reverse() -> FileRelationship.RelationshipType {
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
