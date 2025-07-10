import Foundation
import Combine

// MARK: - Dynamic Model Manager - Handles all model discovery and selection

class DynamicModelManager: ObservableObject {
    
    // MARK: - Model Information Structure
    
    struct ModelInfo {
        let name: String
        let size: Int // MB
        let capabilities: Set<ModelCapability>
        let loadTime: TimeInterval
        let memoryFootprint: Int
        let specialty: ModelSpecialty?
        let parameters: String // e.g., "7B", "13B", "70B"
        let quantization: String? // e.g., "Q4_K_M", "Q8_0"
    }
    
    enum ModelCapability: CaseIterable {
        case basicQA, codeGeneration, complexReasoning, mathematics, translation,
             multimodal, function_calling, creative_writing, analysis
    }
    
    enum ModelSpecialty: String, CaseIterable {
        case coding, math, general, creative, instruct, chat, embedding
    }
    
    // MARK: - Published Properties
    
    @Published var availableModels: [ModelInfo] = []
    @Published var userPreferredModel: String?
    @Published var autoOptimizationEnabled: Bool = true
    @Published var isRefreshing: Bool = false
    
    // MARK: - Private Properties
    
    private let ollamaService = OllamaService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load preferences from UserDefaults
        loadPreferences()
        
        // Refresh models on startup
        Task {
            await refreshAvailableModels()
        }
    }
    
    // MARK: - Model Discovery
    
    func refreshAvailableModels() async {
        DispatchQueue.main.async {
            self.isRefreshing = true
        }
        
        // Query Ollama for all installed models
        let installedModels = await ollamaService.listInstalledModels()
        
        // Auto-detect capabilities and characteristics
        var detectedModels: [ModelInfo] = []
        
        for modelName in installedModels {
            let info = await analyzeModelCapabilities(modelName)
            detectedModels.append(info)
        }
        
        DispatchQueue.main.async {
            self.availableModels = detectedModels.sorted { $0.size < $1.size }
            self.isRefreshing = false
        }
    }
    
    private func analyzeModelCapabilities(_ modelName: String) async -> ModelInfo {
        // Smart model analysis based on name patterns and testing
        let lowercased = modelName.lowercased()
        var capabilities: Set<ModelCapability> = [.basicQA]
        var specialty: ModelSpecialty = .general
        var estimatedSize = 4000 // Default estimate
        var parameters = "Unknown"
        var quantization: String?
        
        // Pattern-based capability detection
        if lowercased.contains("code") || lowercased.contains("llama") {
            capabilities.insert(.codeGeneration)
            specialty = .coding
        }
        
        if lowercased.contains("instruct") {
            capabilities.insert(.complexReasoning)
            specialty = .instruct
        }
        
        if lowercased.contains("math") || lowercased.contains("wizard") {
            capabilities.insert(.mathematics)
            specialty = .math
        }
        
        if lowercased.contains("chat") || lowercased.contains("vicuna") {
            specialty = .chat
        }
        
        if lowercased.contains("creative") || lowercased.contains("story") {
            capabilities.insert(.creative_writing)
            specialty = .creative
        }
        
        // Size estimation from model name
        if lowercased.contains("7b") {
            parameters = "7B"
            estimatedSize = lowercased.contains("q4") ? 4000 : 7000
        } else if lowercased.contains("13b") {
            parameters = "13B"
            estimatedSize = lowercased.contains("q4") ? 8000 : 13000
        } else if lowercased.contains("70b") {
            parameters = "70B"
            estimatedSize = lowercased.contains("q4") ? 40000 : 70000
        } else if lowercased.contains("3b") || lowercased.contains("phi") {
            parameters = "3B"
            estimatedSize = 2000
        } else if lowercased.contains("2b") || lowercased.contains("gemma") {
            parameters = "2B"
            estimatedSize = 1500
        }
        
        // Quantization detection
        if lowercased.contains("q4") {
            quantization = "Q4_K_M"
        } else if lowercased.contains("q8") {
            quantization = "Q8_0"
        } else if lowercased.contains("q5") {
            quantization = "Q5_K_M"
        }
        
        // Get actual model info from Ollama if possible
        if let actualInfo = await ollamaService.getModelInfo(modelName) {
            estimatedSize = actualInfo.size
        }
        
        return ModelInfo(
            name: modelName,
            size: estimatedSize,
            capabilities: capabilities,
            loadTime: Double(estimatedSize) / 1000.0, // Rough estimate
            memoryFootprint: estimatedSize + 1000, // Model + overhead
            specialty: specialty,
            parameters: parameters,
            quantization: quantization
        )
    }
    
    // MARK: - Intelligent Model Selection
    
    func selectOptimalModel(
        for query: String,
        complexity: QueryComplexity = .standard,
        domain: QueryDomain = .generalChat,
        userOverride: String? = nil
    ) async -> ModelInfo {
        
        // If user manually selected a model, use it
        if let override = userOverride,
           let userModel = availableModels.first(where: { $0.name == override }) {
            return userModel
        }
        
        // If auto-optimization is disabled, use user's preferred model
        if !autoOptimizationEnabled,
           let preferred = userPreferredModel,
           let preferredModel = availableModels.first(where: { $0.name == preferred }) {
            return preferredModel
        }
        
        // Smart automatic selection
        let availableMemory = SystemResourceMonitor.shared.availableMemory
        let suitableModels = filterModelsBySystemCapability(availableMemory: availableMemory)
        
        return selectBestModelForTask(
            complexity: complexity,
            domain: domain,
            candidates: suitableModels
        )
    }
    
    private func filterModelsBySystemCapability(availableMemory: Int) -> [ModelInfo] {
        return availableModels.filter { model in
            model.memoryFootprint < availableMemory / 2 // Leave room for OS and other apps
        }
    }
    
    private func selectBestModelForTask(
        complexity: QueryComplexity,
        domain: QueryDomain,
        candidates: [ModelInfo]
    ) -> ModelInfo {
        
        // Score each model for this specific task
        let scoredModels = candidates.map { model in
            (model: model, score: calculateModelScore(model, complexity: complexity, domain: domain))
        }.sorted { $0.score > $1.score }
        
        // Return the highest scoring model, or fallback
        return scoredModels.first?.model ?? createFallbackModel()
    }
    
    private func calculateModelScore(_ model: ModelInfo, complexity: QueryComplexity, domain: QueryDomain) -> Double {
        var score = 0.0
        
        // Base capability matching
        switch domain {
        case .codeGeneration, .codeIteration, .debugging:
            if model.capabilities.contains(.codeGeneration) { score += 50 }
            if model.specialty == .coding { score += 30 }
        case .generalChat:
            if model.specialty == .chat || model.specialty == .general { score += 40 }
        case .mathematics:
            if model.capabilities.contains(.mathematics) { score += 50 }
            if model.specialty == .math { score += 30 }
        case .creativeWriting:
            if model.capabilities.contains(.creative_writing) { score += 50 }
            if model.specialty == .creative { score += 30 }
        }
        
        // Complexity matching
        switch complexity {
        case .simple:
            score += max(0, 30 - Double(model.size) / 200) // Prefer smaller models
        case .standard:
            if model.size > 1000 && model.size < 8000 { score += 20 }
        case .complex:
            if model.size > 4000 { score += 30 }
        }
        
        return score
    }
    
    private func createFallbackModel() -> ModelInfo {
        // Emergency fallback if no models are suitable
        return ModelInfo(
            name: "mistral", // Assume mistral as safe default
            size: 4000,
            capabilities: [.basicQA, .codeGeneration],
            loadTime: 8.0,
            memoryFootprint: 4000,
            specialty: .general,
            parameters: "7B",
            quantization: "Q4_K_M"
        )
    }
    
    // MARK: - User Preferences
    
    func setPreferredModel(_ modelName: String) {
        userPreferredModel = modelName
        savePreferences()
    }
    
    func toggleAutoOptimization() {
        autoOptimizationEnabled.toggle()
        savePreferences()
    }
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        userPreferredModel = UserDefaults.standard.string(forKey: "userPreferredModel")
        autoOptimizationEnabled = UserDefaults.standard.object(forKey: "autoOptimizationEnabled") as? Bool ?? true
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(userPreferredModel, forKey: "userPreferredModel")
        UserDefaults.standard.set(autoOptimizationEnabled, forKey: "autoOptimizationEnabled")
    }
}

// MARK: - Supporting Enums

enum QueryComplexity {
    case simple      // Basic Q&A, definitions
    case standard    // Normal coding, explanations
    case complex     // Architecture, complex reasoning
}

enum QueryDomain {
    case generalChat
    case codeGeneration
    case codeIteration
    case debugging
    case mathematics
    case creativeWriting
}

// MARK: - System Resource Monitor

class SystemResourceMonitor: ObservableObject {
    static let shared = SystemResourceMonitor()
    
    @Published var currentLoad: SystemLoad = .normal
    
    var availableMemory: Int {
        // Get actual available system memory in MB
        let host = mach_host_self()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var hostInfo = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size
            let freeMemory = UInt64(hostInfo.free_count) * UInt64(pageSize)
            return Int(freeMemory / (1024 * 1024)) // Convert to MB
        }
        
        return 4000 // Fallback estimate
    }
    
    private init() {}
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateSystemLoad()
        }
    }
    
    private func updateSystemLoad() {
        let memory = availableMemory
        if memory < 2000 {
            currentLoad = .high
        } else if memory < 4000 {
            currentLoad = .medium
        } else {
            currentLoad = .normal
        }
    }
}

enum SystemLoad {
    case normal, medium, high
}
