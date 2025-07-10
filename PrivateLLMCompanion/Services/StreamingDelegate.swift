import Foundation

class StreamingDelegate: NSObject, URLSessionDataDelegate {
    private let onReceive: (String) -> Void
    private let onComplete: () -> Void
    private let onError: (Error) -> Void
    private var buffer = ""
    
    init(
        onReceive: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onReceive = onReceive
        self.onComplete = onComplete
        self.onError = onError
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        buffer += text
        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""
        
        for line in lines.dropLast() {
            guard !line.isEmpty else { continue }
            
            // Parse each line as JSON (Ollama streaming format)
            if let jsonData = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let chunk = json["response"] as? String {
                onReceive(chunk)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onError(error)
        } else {
            onComplete()
        }
    }
}
