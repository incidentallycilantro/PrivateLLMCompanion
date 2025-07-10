import Foundation
import Combine

// MARK: - Intelligent Response Pipeline

class IntelligentResponsePipeline: ObservableObject {
    
    @Published var isProcessing = false
    @Published var responseLayer: ResponseLayer = .none
    @Published var estimatedWaitTime: Double = 0
    
    private let ollamaService = OllamaService()
    private let instantResponseEngine = InstantResponseEngine()
    private let smartPredictor = SmartPredictor()
    
    // Pre-warmed models
    private var fastModel = "phi3:mini"  // ~2GB, very fast
    private var powerModel = "mistral:latest"  // Your current model
    
    enum ResponseLayer {
        case none
        case instant       // 0-100ms - Templates & predictions
        case fast         // 200-800ms - Small model
        case intelligent  // 2-8s - Large model
    }
    
    // MARK: - Main Processing Pipeline
    
    func processQuery(_ query: String, context: [ChatMessage]) -> AsyncStream<IntelligentResponse> {
        return AsyncStream { continuation in
            Task {
                await processQueryIntelligently(query, context: context, continuation: continuation)
            }
        }
    }
    
    private func processQueryIntelligently(
        _ query: String,
        context: [ChatMessage],
        continuation: AsyncStream<IntelligentResponse>.Continuation
    ) async {
        
        await MainActor.run {
            isProcessing = true
            responseLayer = .instant
        }
        
        // LAYER 1: Instant Response (0-100ms)
        if let instantResponse = await instantResponseEngine.getInstantResponse(query, context: context) {
            continuation.yield(IntelligentResponse(
                content: instantResponse,
                isComplete: true,
                layer: .instant,
                processingTime: 0.05
            ))
            await MainActor.run { isProcessing = false }
            continuation.finish()
            return
        }
        
        // LAYER 2: Smart Prediction (0-200ms)
        if let predictedResponse = await smartPredictor.getPredictedResponse(query, context: context) {
            continuation.yield(IntelligentResponse(
                content: predictedResponse,
                isComplete: true,
                layer: .instant,
                processingTime: 0.15
            ))
            await MainActor.run { isProcessing = false }
            continuation.finish()
            return
        }
        
        // LAYER 3: Route to Appropriate Model
        let complexity = analyzeComplexity(query)
        let needsPowerModel = complexity == .complex || query.lowercased().contains("code")
        
        if needsPowerModel {
            await processWithPowerModel(query, context: context, continuation: continuation)
        } else {
            await processWithFastModel(query, context: context, continuation: continuation)
        }
    }
    
    // MARK: - Fast Model Processing
    
    private func processWithFastModel(
        _ query: String,
        context: [ChatMessage],
        continuation: AsyncStream<IntelligentResponse>.Continuation
    ) async {
        await MainActor.run {
            responseLayer = .fast
            estimatedWaitTime = 1.0
        }
        
        // Ensure fast model is available and warmed
        await ensureFastModelReady()
        
        // Process with fast model
        for await response in ollamaService.generateResponse(
            prompt: query,
            model: fastModel,
            context: context,
            stream: true
        ) {
            continuation.yield(IntelligentResponse(
                content: response.content,
                isComplete: response.isComplete,
                layer: .fast,
                processingTime: 0.8
            ))
            
            if response.isComplete {
                await MainActor.run { isProcessing = false }
                continuation.finish()
                break
            }
        }
    }
    
    // MARK: - Power Model Processing (With Smart Loading)
    
    private func processWithPowerModel(
        _ query: String,
        context: [ChatMessage],
        continuation: AsyncStream<IntelligentResponse>.Continuation
    ) async {
        await MainActor.run {
            responseLayer = .intelligent
            estimatedWaitTime = 5.0
        }
        
        // INNOVATION: Show immediate "thinking" response while loading
        continuation.yield(IntelligentResponse(
            content: generateThinkingResponse(for: query),
            isComplete: false,
            layer: .intelligent,
            processingTime: 0.1
        ))
        
        // Pre-warm power model if needed
        await ensurePowerModelReady()
        
        // Process with power model
        var fullResponse = ""
        for await response in ollamaService.generateResponse(
            prompt: query,
            model: powerModel,
            context: context,
            stream: true
        ) {
            fullResponse = response.content
            continuation.yield(IntelligentResponse(
                content: response.content,
                isComplete: response.isComplete,
                layer: .intelligent,
                processingTime: 4.0
            ))
            
            if response.isComplete {
                await MainActor.run { isProcessing = false }
                continuation.finish()
                break
            }
        }
    }
    
    // MARK: - Model Management & Pre-warming
    
    private var fastModelWarmed = false
    private var powerModelWarmed = false
    
    private func ensureFastModelReady() async {
        guard !fastModelWarmed else { return }
        
        if await ollamaService.isModelAvailable(fastModel) {
            await ollamaService.warmUpModel(fastModel)
            fastModelWarmed = true
        } else {
            // Fallback to any available small model
            let availableModels = await ollamaService.listInstalledModels()
            if let smallModel = availableModels.first(where: { $0.contains("phi") || $0.contains("gemma") }) {
                fastModel = smallModel
                await ollamaService.warmUpModel(fastModel)
                fastModelWarmed = true
            }
        }
    }
    
    private func ensurePowerModelReady() async {
        guard !powerModelWarmed else { return }
        await ollamaService.warmUpModel(powerModel)
        powerModelWarmed = true
    }
    
    // MARK: - Background Pre-warming
    
    func startBackgroundOptimization() async {
        // Pre-warm fast model immediately
        Task.detached(priority: .background) {
            await self.ensureFastModelReady()
        }
        
        // Pre-warm power model after a delay
        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            await self.ensurePowerModelReady()
        }
    }
    
    // MARK: - Helper Methods
    
    private func analyzeComplexity(_ query: String) -> QueryComplexity {
        let complexPatterns = ["explain", "analyze", "design", "architecture", "algorithm"]
        let codePatterns = ["function", "class", "def ", "import", "```"]
        
        if complexPatterns.contains(where: query.lowercased().contains) {
            return .complex
        }
        
        if codePatterns.contains(where: query.contains) {
            return .standard
        }
        
        return query.count > 50 ? .standard : .simple
    }
    
    private func generateThinkingResponse(for query: String) -> String {
        let thinkingPhrases = [
            "Let me think about this...",
            "I'm analyzing your question...",
            "Processing this request...",
            "Working on this for you...",
            "Considering the best approach..."
        ]
        
        return thinkingPhrases.randomElement() ?? "Thinking..."
    }
}

// MARK: - Instant Response Engine

class InstantResponseEngine {
    
    private let commonResponses: [String: String] = [
        "hello": "Hello! How can I help you today?",
        "hi": "Hi there! What can I assist you with?",
        "thanks": "You're welcome! Is there anything else I can help with?",
        "thank you": "You're very welcome! Feel free to ask me anything else.",
        "bye": "Goodbye! Have a great day!",
        "good morning": "Good morning! How can I assist you today?",
        "good afternoon": "Good afternoon! What can I help you with?",
        "good evening": "Good evening! How may I assist you?",
        "how are you": "I'm doing well, thank you! How can I help you today?",
        "what's up": "Hello! I'm here and ready to help. What's on your mind?"
    ]
    
    private let helpResponses: [String: String] = [
        "help": "I'm here to help! You can ask me questions, request coding assistance, explanations, or just have a conversation. What would you like to know?",
        "what can you do": "I can help with coding, answer questions, explain concepts, assist with writing, and much more. What are you working on?",
        "commands": "Just type naturally! Ask questions, request help with code, or tell me what you're trying to accomplish."
    ]
    
    func getInstantResponse(_ query: String, context: [ChatMessage]) async -> String? {
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct matches
        if let response = commonResponses[cleanQuery] {
            return response
        }
        
        if let response = helpResponses[cleanQuery] {
            return response
        }
        
        // Pattern matches
        if cleanQuery.contains("hello") || cleanQuery.contains("hi") {
            return "Hello! How can I help you today?"
        }
        
        if cleanQuery.contains("thank") {
            return "You're welcome! Anything else I can help with?"
        }
        
        return nil
    }
}

// MARK: - Smart Predictor

class SmartPredictor {
    
    func getPredictedResponse(_ query: String, context: [ChatMessage]) async -> String? {
        // Simple query patterns that can be predicted
        let queryLower = query.lowercased()
        
        // Quick factual responses
        if queryLower.contains("what is") || queryLower.contains("what's") {
            if queryLower.contains("time") {
                return "The current time is \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short))"
            }
            if queryLower.contains("date") {
                return "Today is \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))"
            }
        }
        
        // Programming help patterns
        if queryLower.contains("how to") && queryLower.contains("python") {
            return "I'd be happy to help with Python! Could you be more specific about what you're trying to accomplish?"
        }
        
        if queryLower.contains("how to") && queryLower.contains("swift") {
            return "I can help with Swift development! What specific aspect are you working on?"
        }
        
        // Context-aware predictions
        if let lastMessage = context.last, lastMessage.role == .assistant {
            if queryLower.contains("more") || queryLower.contains("explain") {
                return "I'll provide more detail on that topic..."
            }
            
            if queryLower.contains("example") {
                return "Let me give you a practical example..."
            }
        }
        
        return nil
    }
}

// MARK: - Response Structure

struct IntelligentResponse {
    let content: String
    let isComplete: Bool
    let layer: IntelligentResponsePipeline.ResponseLayer
    let processingTime: Double
}
