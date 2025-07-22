import SwiftUI

// MARK: - Knowledge File Card - Revolutionary File Display

struct KnowledgeFileCard: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    let onTap: () -> Void
    
    @State private var isHovering = false
    @State private var showingQuickActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // File header with intelligence
            HStack {
                // File type icon with smart coloring
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(file.knowledgeMetadata.detectedContentType.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: file.fileIcon)
                        .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(file.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Relevance indicator
                        if file.relevanceScore > 0.7 {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text(file.knowledgeMetadata.detectedContentType.description)
                            .font(.caption)
                            .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                        
                        Spacer()
                        
                        Text(file.displaySize)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Intelligent description
            if !file.intelligentDescription.isEmpty {
                Text(file.intelligentDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Key points preview
            if !file.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Points:")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    ForEach(file.keyPoints.prefix(2), id: \.self) { point in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 3, height: 3)
                                .padding(.top, 6)
                            
                            Text(point)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            
            // AI Tags
            if !file.aiTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(file.aiTags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            Divider()
            
            // Footer with metadata
            HStack {
                // Usage indicator
                if file.usageCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(file.usageCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Relationships indicator
                if !file.fileRelationships.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("\(file.fileRelationships.count)")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
                
                // Last accessed
                Text(formatRelativeDate(file.lastAccessed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Quick actions button
                Button(action: { showingQuickActions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.0)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isHovering ? 0.1 : 0.05), radius: isHovering ? 8 : 4, x: 0, y: 2)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            fileContextMenu
        }
        .popover(isPresented: $showingQuickActions) {
            QuickActionsPopover(
                file: file,
                knowledgeManager: knowledgeManager
            )
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var fileContextMenu: some View {
        Button("Preview") {
            onTap()
        }
        
        Divider()
        
        Button("Summarize") {
            Task {
                _ = await knowledgeManager.executeSmartAction(.summarize, on: file)
            }
        }
        
        Button("Extract Key Points") {
            Task {
                _ = await knowledgeManager.executeSmartAction(.extractKeyPoints, on: file)
            }
        }
        
        Button("Find Related Files") {
            Task {
                _ = await knowledgeManager.executeSmartAction(.findRelated, on: file)
            }
        }
        
        Divider()
        
        if !file.isProjectLevel && file.shouldGraduateToProject {
            Button("Promote to Project Level") {
                knowledgeManager.graduateFileToProject(file.id)
            }
        }
        
        Button("Show in Finder") {
            let fileURL = knowledgeManager.fileManager.getFileURL(for: convertToProjectFile(file))
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: fileURL.deletingLastPathComponent().path)
        }
        
        Divider()
        
        Button("Remove") {
            // TODO: Implement file removal
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

// MARK: - Quick Actions Popover

struct QuickActionsPopover: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach([SmartFileAction.summarize, .extractKeyPoints, .findRelated, .suggestTags], id: \.rawValue) { action in
                Button(action: {
                    executeAction(action)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: action.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(action.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 200)
    }
    
    private func executeAction(_ action: SmartFileAction) {
        Task {
            _ = await knowledgeManager.executeSmartAction(action, on: file)
        }
    }
}
