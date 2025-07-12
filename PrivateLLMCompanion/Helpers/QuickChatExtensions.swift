import Foundation
import SwiftUI

// MARK: - Simple QuickChatManager Extensions
// Only contains enhanced command parsing - no problematic analyzer access

extension QuickChatManager {
    
    // Enhanced command parsing with natural language understanding
    func enhancedProcessConversationalCommand(_ message: String) -> ConversationalCommand? {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // More natural language patterns
        let createProjectPatterns = [
            "create a project", "make this a project", "turn this into a project",
            "organize this as a project", "save this as a project", "project this",
            "make a project called", "create project named", "new project for this"
        ]
        
        let moveToProjectPatterns = [
            "move this to", "add this to", "put this in", "save to project",
            "move to my", "add to my", "include in", "attach to project"
        ]
        
        let organizePatterns = [
            "organize this", "organize conversation", "clean this up",
            "structure this", "organize chat", "make this organized"
        ]
        
        let splitPatterns = [
            "split this", "divide conversation", "separate this discussion",
            "break this up", "split conversation", "divide this chat"
        ]
        
        // Check create project patterns
        for pattern in createProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern) ?? "New Project"
                return .createProject(name: projectName)
            }
        }
        
        // Check move to project patterns
        for pattern in moveToProjectPatterns {
            if lowercased.contains(pattern) {
                let projectName = extractProjectNameFromCommand(lowercased, pattern: pattern)
                return .moveToProject(name: projectName)
            }
        }
        
        // Check organize patterns
        for pattern in organizePatterns {
            if lowercased.contains(pattern) {
                return .organizeConversation
            }
        }
        
        // Check split patterns
        for pattern in splitPatterns {
            if lowercased.contains(pattern) {
                return .splitConversation
            }
        }
        
        return nil
    }
    
    private func extractProjectNameFromCommand(_ command: String, pattern: String) -> String? {
        // Find the pattern and extract text after it
        if let range = command.range(of: pattern) {
            let afterPattern = String(command[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Look for common connectors
            let connectors = ["called ", "named ", "for ", "to ", "as "]
            
            for connector in connectors {
                if let connectorRange = afterPattern.range(of: connector) {
                    let projectName = String(afterPattern[connectorRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: " ")
                        .prefix(4) // Limit to 4 words
                        .joined(separator: " ")
                    
                    return projectName.isEmpty ? nil : projectName.capitalized
                }
            }
            
            // If no connector found, take the next few words
            let words = afterPattern.components(separatedBy: " ").prefix(3)
            let projectName = String(words.joined(separator: " ")).trimmingCharacters(in: CharacterSet.punctuationCharacters)
            
            return projectName.isEmpty ? nil : projectName.capitalized
        }
        
        return nil
    }
}
