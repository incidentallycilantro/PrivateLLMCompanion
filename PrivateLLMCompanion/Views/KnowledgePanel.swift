import SwiftUI
import UniformTypeIdentifiers

// MARK: - Revolutionary Knowledge Panel - The Main File Interface

struct KnowledgePanel: View {
    @ObservedObject var knowledgeManager: KnowledgeManager
    @Binding var project: Project
    @State private var selectedFile: KnowledgeFile?
    @State private var showingFilePreview = false
    @State private var showingSmartActions = false
    @State private var isDropTargeted = false
    @State private var searchText = ""
    @State private var selectedCategory: ContentCategory?
    @State private var showingUploadSheet = false
    
    var filteredFiles: [KnowledgeFile] {
        let projectFiles = knowledgeManager.getKnowledgeFiles(for: project)
        var filtered = projectFiles
        
        if !searchText.isEmpty {
            filtered = filtered.filter { file in
                file.name.localizedCaseInsensitiveContains(searchText) ||
                file.intelligentDescription.localizedCaseInsensitiveContains(searchText) ||
                file.aiTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.contentCategories.contains(category) }
        }
        
        return filtered.sorted { $0.lastAccessed > $1.lastAccessed }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Revolutionary Header with Intelligence
            knowledgeHeader
            
            Divider()
            
            // Smart Search and Filters
            searchAndFilters
            
            // Main Content Area
            if knowledgeManager.isProcessingFile {
                processingView
            } else if filteredFiles.isEmpty {
                emptyStateView
            } else {
                filesGridView
            }
            
            // Ambient Suggestions Overlay
            if !knowledgeManager.ambientSuggestions.isEmpty {
                ambientSuggestionsOverlay
            }
        }
        .onDrop(of: ProjectFileManager.supportedFileTypes, isTargeted: $isDropTargeted) { providers in
            handleFileDrop(providers)
        }
        .overlay(
            // Drop target visual feedback
            Rectangle()
                .stroke(Color.blue, lineWidth: 3)
                .fill(Color.blue.opacity(0.1))
                .opacity(isDropTargeted ? 1 : 0)
                .animation(.spring(response: 0.3), value: isDropTargeted)
        )
        .sheet(isPresented: $showingFilePreview) {
            if let file = selectedFile {
                KnowledgeFilePreview(
                    file: file,
                    knowledgeManager: knowledgeManager
                )
            }
        }
        .sheet(isPresented: $showingUploadSheet) {
            FileUploadSheet(
                project: $project,
                knowledgeManager: knowledgeManager
            )
        }
    }
    
    // MARK: - Revolutionary Knowledge Header
    
    private var knowledgeHeader: some View {
        HStack(spacing: 16) {
            // Knowledge Status Indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: project.knowledgeHealth.icon)
                        .foregroundColor(project.knowledgeHealth.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Knowledge Base")
                            .font(.headline)
                            .bold()
                        
                        Text(project.knowledgeHealth.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Knowledge Insights
            knowledgeInsightsIndicator
            
            // Actions
            HStack(spacing: 8) {
                Button(action: { showingUploadSheet = true }) {
                    Label("Add Files", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Menu {
                    Button("Organize All Files") {
                        Task {
                            await organizeAllFiles()
                        }
                    }
                    
                    Button("Generate Summaries") {
                        Task {
                            await generateAllSummaries()
                        }
                    }
                    
                    Button("Detect Relationships") {
                        Task {
                            await detectAllRelationships()
                        }
                    }
                    
                    Divider()
                    
                    Button("Export Knowledge Map") {
                        // TODO: Export functionality
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Knowledge Insights Indicator
    
    private var knowledgeInsightsIndicator: some View {
        HStack(spacing: 12) {
            // File count with animation
            VStack(spacing: 2) {
                Text("\(filteredFiles.count)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                    .contentTransition(.numericText())
                
                Text("files")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if project.knowledgeInsights.knowledgeConnections > 0 {
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 2) {
                    Text("\(project.knowledgeInsights.knowledgeConnections)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Text("links")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if project.knowledgeInsights.knowledgeCoverage > 0 {
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 2) {
                    Text("\(Int(project.knowledgeInsights.knowledgeCoverage * 100))%")
                        .font(.title2)
                        .bold()
                        .foregroundColor(project.knowledgeInsights.coverageColor)
                    
                    Text("coverage")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            HStack {
                // Smart Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search files, content, or tags...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Category Filters
            if !project.knowledgeInsights.activeCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All filter
                        FilterChip(
                            title: "All",
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil,
                            count: filteredFiles.count
                        ) {
                            selectedCategory = nil
                        }
                        
                        // Category filters
                        ForEach(project.knowledgeInsights.activeCategories, id: \.self) { category in
                            let categoryCount = knowledgeManager.getKnowledgeFiles(for: project)
                                .filter { $0.contentCategories.contains(category) }.count
                            
                            FilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                count: categoryCount
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Animated processing indicator
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: knowledgeManager.processingProgress)
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: knowledgeManager.processingProgress)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Processing File with AI")
                        .font(.headline)
                        .bold()
                    
                    Text("Analyzing content, detecting relationships, generating insights...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    ProgressView(value: knowledgeManager.processingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    
                    Text("\(Int(knowledgeManager.processingProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Revolutionary empty state design
            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .opacity(0.8)
                }
                
                VStack(spacing: 12) {
                    Text("Ready for Knowledge")
                        .font(.title)
                        .bold()
                    
                    Text("Drag files here or click 'Add Files' to start building your intelligent knowledge base")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: 400)
                }
            }
            
            // Quick actions
            VStack(spacing: 16) {
                Button(action: { showingUploadSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Your First Files")
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3), value: UUID())
                
                // Supported file types
                VStack(spacing: 8) {
                    Text("Supported file types:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(["PDF", "Word", "Text", "Code", "Images", "Data"], id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Files Grid View
    
    private var filesGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 280)), count: 2), spacing: 16) {
                ForEach(filteredFiles) { file in
                    KnowledgeFileCard(
                        file: file,
                        knowledgeManager: knowledgeManager
                    ) {
                        selectedFile = file
                        showingFilePreview = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Ambient Suggestions Overlay
    
    private var ambientSuggestionsOverlay: some View {
        VStack {
            Spacer()
            
            ForEach(knowledgeManager.ambientSuggestions) { suggestion in
                AmbientSuggestionCard(
                    suggestion: suggestion,
                    onAccept: {
                        handleAmbientSuggestionAccepted(suggestion)
                    },
                    onDismiss: {
                        knowledgeManager.dismissAmbientSuggestion(suggestion)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    
                    Task {
                        do {
                            _ = try await knowledgeManager.processFileWithAmbientIntelligence(
                                from: url,
                                project: project,
                                isProjectLevel: true
                            )
                        } catch {
                            print("❌ Failed to process dropped file: \(error)")
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func organizeAllFiles() async {
        // TODO: Implement bulk organization
        print("Organizing all files...")
    }
    
    private func generateAllSummaries() async {
        for file in filteredFiles where file.aiGeneratedSummary == nil {
            _ = await knowledgeManager.executeSmartAction(.summarize, on: file)
        }
    }
    
    private func detectAllRelationships() async {
        // TODO: Implement relationship detection for all files
        print("Detecting relationships...")
    }
    
    private func handleAmbientSuggestionAccepted(_ suggestion: AmbientSuggestion) {
        switch suggestion.type {
        case .graduateFile:
            if let fileId = suggestion.fileId {
                knowledgeManager.graduateFileToProject(fileId)
            }
        case .summarizeFile:
            if let fileId = suggestion.fileId,
               let file = knowledgeManager.allKnowledgeFiles.first(where: { $0.id == fileId }) {
                Task {
                    _ = await knowledgeManager.executeSmartAction(.summarize, on: file)
                }
            }
        default:
            break
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .bold()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.3))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

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

// MARK: - Ambient Suggestion Card

struct AmbientSuggestionCard: View {
    let suggestion: AmbientSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // AI indicator
            VStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("AI")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(suggestion.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(spacing: 6) {
                Button(suggestion.actionText) {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - File Upload Sheet

struct FileUploadSheet: View {
    @Binding var project: Project
    @ObservedObject var knowledgeManager: KnowledgeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isFileImporterPresented = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Add Knowledge Files")
                        .font(.title2)
                        .bold()
                    
                    Text("Upload files to enhance your project's knowledge base")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Upload options
            VStack(spacing: 16) {
                Button(action: { isFileImporterPresented = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Choose Files")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Select files from your Mac")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Text("or drag files into the Knowledge Panel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Supported formats
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported formats:")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach([
                        ("PDF Documents", "doc.fill", Color.red),
                        ("Word Documents", "doc.richtext.fill", Color.blue),
                        ("Text Files", "doc.text.fill", Color.green),
                        ("Code Files", "curlybraces", Color.purple),
                        ("CSV Data", "tablecells.fill", Color.orange),
                        ("Images", "photo.fill", Color.pink)
                    ], id: \.0) { format in
                        HStack(spacing: 8) {
                            Image(systemName: format.1)
                                .foregroundColor(format.2)
                            
                            Text(format.0)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: ProjectFileManager.supportedFileTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    Task {
                        do {
                            _ = try await knowledgeManager.processFileWithAmbientIntelligence(
                                from: url,
                                project: project,
                                isProjectLevel: true
                            )
                        } catch {
                            print("❌ Failed to process file: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("❌ File selection failed: \(error)")
            }
        }
    }
}
