import Foundation
import SwiftUI

// MARK: - Simple Compilation Fixes
// Only essential fixes, no method duplications

// Fix 1: Add missing import for mach
#if canImport(Darwin)
import Darwin.Mach
#endif

// Fix 2: Add missing UserDefaults keys
extension UserDefaults {
    static let conversationAnalyzerKey = "conversationAnalyzerData"
    static let quickChatManagerKey = "quickChatManagerData"
}
