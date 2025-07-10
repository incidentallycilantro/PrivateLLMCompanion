import Foundation

struct PersistenceManager {
    static let fileName = "projects.json"

    static private var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = directory.appendingPathComponent("PrivateLLMCompanion", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }

        return appFolder.appendingPathComponent(fileName)
    }

    static func saveProjects(_ projects: [Project]) {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("❌ Failed to save projects:", error)
        }
    }

    static func loadProjects() -> [Project] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("⚠️ No saved projects or failed to load:", error)
            return [Project.example]
        }
    }
}
