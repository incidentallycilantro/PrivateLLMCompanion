import Foundation
import Combine

// MARK: - Ollama Service - Handles all communication with Ollama API

class OllamaService: ObservableObject {
    
    // MARK: - Model Information Structure
    
    struct OllamaModelInfo {
        let name: String
        let size: Int
        let digest: String
        let modified: Date
    }
    
    // MARK: - Response Structures
    
    struct StreamResponse {
        let content: String
        let isComplete: Bool
        let modelUsed: String
    }
    
    // MARK: - API Configuration
    
    private let baseURL = "http://127.0.0.1:11434"
    private let session = URLSession.shared
    
    // MARK: - Published Properties
    
    @Published var isConnected: Bool = false
    @Published var currentlyRunningModels: [String] = []
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkConnection()
        }
    }
    
    // MARK: - Connection Management
    
    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            await updateConnectionStatus(false)
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let connected = httpResponse.statusCode == 200
                await updateConnectionStatus(connected)
                return connected
            }
        } catch {
            print("❌ Ollama connection failed: \(error.localizedDescription)")
            await updateConnectionStatus(false)
        }
        
        return false
    }
    
    private func updateConnectionStatus(_ connected: Bool) async {
        await MainActor.run {
            self.isConnected = connected
        }
    }
    
    // MARK: - Model Discovery
    
    func listInstalledModels() async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            print("❌ Invalid URL for listing models")
            return []
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let models = response?["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { model in
                    model["name"] as? String
                }
                print("✅ Found \(modelNames.count) installed models: \(modelNames)")
                return modelNames
            }
        } catch {
            print("❌ Failed to fetch installed models: \(error)")
        }
        
        return []
    }
    
    func getModelInfo(_ modelName: String) async -> OllamaModelInfo? {
        guard let url = URL(string: "\(baseURL)/api/show") else {
            print("❌ Invalid URL for model info")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["name": modelName]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, _) = try await session.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let details = response?["details"] as? [String: Any],
               let size = details["size"] as? Int {
                return OllamaModelInfo(
                    name: modelName,
                    size: size / (1024 * 1024), // Convert to MB
                    digest: details["digest"] as? String ?? "",
                    modified: Date() // Would parse from response in production
                )
            }
        } catch {
            print("❌ Failed to get model info for \(modelName): \(error)")
        }
        
        return nil
    }
    
    func getRunningModels() async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/ps") else {
            return []
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let models = response?["models"] as? [[String: Any]] {
                let runningNames = models.compactMap { model in
                    model["name"] as? String
                }
                
                await MainActor.run {
                    self.currentlyRunningModels = runningNames
                }
                
                return runningNames
            }
        } catch {
            print("❌ Failed to check running models: \(error)")
        }
        
        return []
    }
    
    // MARK: - Chat Generation
    
    func generateResponse(
        prompt: String,
        model: String,
        context: [ChatMessage] = [],
        stream: Bool = true
    ) -> AsyncStream<StreamResponse> {
        
        return AsyncStream { continuation in
            Task {
                guard let url = URL(string: "\(baseURL)/api/generate") else {
                    print("❌ Invalid Ollama URL")
                    continuation.finish()
                    return
                }
                
                // Build context-aware prompt
                let fullPrompt = buildContextPrompt(newMessage: prompt, context: context)
                
                let payload: [String: Any] = [
                    "model": model,
                    "prompt": fullPrompt,
                    "stream": stream
                ]
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    
                    if stream {
                        await handleStreamingResponse(
                            request: request,
                            model: model,
                            continuation: continuation
                        )
                    } else {
                        await handleSingleResponse(
                            request: request,
                            model: model,
                            continuation: continuation
                        )
                    }
                } catch {
                    print("❌ Failed to encode request: \(error)")
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Response Handling
    
    private func handleStreamingResponse(
        request: URLRequest,
        model: String,
        continuation: AsyncStream<StreamResponse>.Continuation
    ) async {
        do {
            let (asyncBytes, _) = try await session.bytes(for: request)
            var fullResponse = ""
            
            for try await line in asyncBytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseChunk = json["response"] as? String {
                    
                    fullResponse += responseChunk
                    
                    // Yield each chunk
                    continuation.yield(StreamResponse(
                        content: fullResponse,
                        isComplete: false,
                        modelUsed: model
                    ))
                    
                    // Check if done
                    if let done = json["done"] as? Bool, done {
                        continuation.yield(StreamResponse(
                            content: fullResponse,
                            isComplete: true,
                            modelUsed: model
                        ))
                        continuation.finish()
                        break
                    }
                }
            }
        } catch {
            print("❌ Streaming error: \(error)")
            continuation.finish()
        }
    }
    
    private func handleSingleResponse(
        request: URLRequest,
        model: String,
        continuation: AsyncStream<StreamResponse>.Continuation
    ) async {
        do {
            let (data, _) = try await session.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let response = json["response"] as? String {
                
                continuation.yield(StreamResponse(
                    content: response,
                    isComplete: true,
                    modelUsed: model
                ))
            }
            
            continuation.finish()
        } catch {
            print("❌ Single response error: \(error)")
            continuation.finish()
        }
    }
    
    // MARK: - Context Management
    
    private func buildContextPrompt(newMessage: String, context: [ChatMessage]) -> String {
        if context.isEmpty {
            return newMessage
        }
        
        // Build conversation context (keep last 10 messages to avoid token limits)
        let recentContext = Array(context.suffix(10))
        var contextString = ""
        
        for message in recentContext {
            let role = message.role == .user ? "User" : "Assistant"
            contextString += "\(role): \(message.content)\n"
        }
        
        contextString += "User: \(newMessage)"
        return contextString
    }
    
    // MARK: - Model Management
    
    func installModel(_ modelName: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/pull") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["name": modelName]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                if success {
                    print("✅ Successfully initiated download of \(modelName)")
                } else {
                    print("❌ Failed to initiate download of \(modelName), status: \(httpResponse.statusCode)")
                }
                return success
            }
        } catch {
            print("❌ Failed to install model \(modelName): \(error)")
        }
        
        return false
    }
    
    func removeModel(_ modelName: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/delete") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["name": modelName]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                if success {
                    print("✅ Successfully removed \(modelName)")
                } else {
                    print("❌ Failed to remove \(modelName), status: \(httpResponse.statusCode)")
                }
                return success
            }
        } catch {
            print("❌ Failed to remove model \(modelName): \(error)")
        }
        
        return false
    }
    
    // MARK: - Health Checks
    
    func isModelAvailable(_ modelName: String) async -> Bool {
        let installedModels = await listInstalledModels()
        return installedModels.contains(modelName)
    }
    
    func warmUpModel(_ modelName: String) async -> Bool {
        // Send a simple prompt to "warm up" the model
        let warmupPrompt = "Hi"
        
        for await response in generateResponse(prompt: warmupPrompt, model: modelName, stream: false) {
            if response.isComplete {
                print("✅ Model \(modelName) warmed up successfully")
                return true
            }
        }
        
        print("❌ Failed to warm up model \(modelName)")
        return false
    }
    
    // MARK: - Utility Methods
    
    func getModelSize(_ modelName: String) async -> Int? {
        let info = await getModelInfo(modelName)
        return info?.size
    }
    
    func getAllModelSizes() async -> [String: Int] {
        let models = await listInstalledModels()
        var sizes: [String: Int] = [:]
        
        for model in models {
            if let size = await getModelSize(model) {
                sizes[model] = size
            }
        }
        
        return sizes
    }
}
