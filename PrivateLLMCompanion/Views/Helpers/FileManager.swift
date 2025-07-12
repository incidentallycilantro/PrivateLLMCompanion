import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ProjectFileManager: ObservableObject {
    static let shared = ProjectFileManager()
    
    private let documentsPath: URL
    
    private init() {
        // Create app's documents directory for file storage
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        documentsPath = paths[0].appendingPathComponent("PrivateLLMCompanion/Files", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
    }
    
    // MARK: - File Operations
    
    func saveFile(from url: URL, to project: Project, isProjectLevel: Bool = false, chatId: UUID? = nil) throws -> ProjectFile {
        let originalName = url.lastPathComponent
        let fileExtension = url.pathExtension
        let uniqueName = "\(UUID().uuidString).\(fileExtension)"
        let destinationURL = documentsPath.appendingPathComponent(uniqueName)
        
        // Copy file to app's directory
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return ProjectFile(
            name: String(originalName.dropLast(fileExtension.count + 1)), // Remove extension
            originalName: originalName,
            fileExtension: fileExtension,
            size: fileSize,
            isProjectLevel: isProjectLevel,
            chatId: chatId,
            localPath: uniqueName
        )
    }
    
    func deleteFile(_ file: ProjectFile) throws {
        let fileURL = documentsPath.appendingPathComponent(file.localPath)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func getFileURL(for file: ProjectFile) -> URL {
        return documentsPath.appendingPathComponent(file.localPath)
    }
    
    func readFileContent(for file: ProjectFile) throws -> String? {
        let fileURL = getFileURL(for: file)
        
        switch file.fileExtension.lowercased() {
        case "txt", "md", "py", "js", "json", "csv":
            return try String(contentsOf: fileURL, encoding: .utf8)
        default:
            return nil // Will handle other file types in future features
        }
    }
    
    // MARK: - Supported File Types
    
    static let supportedFileTypes: [UTType] = [
        .plainText, .text,
        .pdf,
        .image,
        .json,
        .commaSeparatedText,
        UTType(filenameExtension: "md") ?? .text,
        UTType(filenameExtension: "py") ?? .text,
        UTType(filenameExtension: "js") ?? .text,
        UTType(filenameExtension: "docx") ?? .text
    ]
    
    static func isFileTypeSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = ["txt", "md", "pdf", "docx", "csv", "json", "py", "js", "png", "jpg", "jpeg"]
        return supportedExtensions.contains(fileExtension)
    }
}
