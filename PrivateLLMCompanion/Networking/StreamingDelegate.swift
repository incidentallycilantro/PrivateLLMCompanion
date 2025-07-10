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
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        print("📥 Received stream chunk: \(text)")
        buffer += text

        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""

        for line in lines.dropLast() {
            guard !line.isEmpty else { continue }

            // ⚠️ FIXED: Remove "data: " prefix expectation
            let jsonString = line

            if let jsonData = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let chunk = json["response"] as? String {
                print("✅ Parsed chunk: \(chunk)")
                onReceive(chunk)
            } else {
                print("❌ Failed to parse JSON chunk: \(jsonString)")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("🔚 Stream finished")
        if let error = error {
            print("❌ Stream error: \(error.localizedDescription)")
            onError(error)
        } else {
            onComplete()
        }
    }
}
