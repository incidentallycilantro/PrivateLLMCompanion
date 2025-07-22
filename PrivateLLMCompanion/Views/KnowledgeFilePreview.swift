.frame(minWidth: 250, maxWidth: 300)
            
            // Main content area
            Group {
                switch selectedTab {
                case .content:
                    FileContentView(file: file, knowledgeManager: knowledgeManager)
                case .insights:
                    AIInsightsView(file: file, knowledgeManager: knowledgeManager)
                case .relationships:
                    FileRelationshipsView(file: file, knowledgeManager: knowledgeManager)
                case .metadata:
                    FileMetadataView(file: file)
                }
            }
            .frame(minWidth: 500)
        }
        .navigationTitle(file.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Smart actions menu
                Menu {
                    ForEach([SmartFileAction.summarize, .extractKeyPoints, .findRelated, .compareWith, .generateQuestions], id: \.rawValue) { action in
                        Button(action.rawValue) {
                            executeSmartAction(action)
                        }
                    }
                } label: {
                    Label("Smart Actions", systemImage: "sparkles")
                }
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .sheet(item: $selectedSmartAction) { action in
            SmartActionResultView(
                action: action,
                result: smartActionResult,
                file: file,
                isExecuting: isExecutingAction
            )
        }
    }
    
    // MARK: - File Header Section
    
    private var fileHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // File icon with type coloring
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(file.knowledgeMetadata.detectedContentType.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: file.fileIcon)
                        .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.title2)
                        .bold()
                        .lineLimit(2)
                    
                    Text(file.knowledgeMetadata.detectedContentType.description)
                        .font(.subheadline)
                        .foregroundColor(file.knowledgeMetadata.detectedContentType.color)
                    
                    Text(file.displaySize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick stats
            HStack(spacing: 16) {
                if file.knowledgeMetadata.wordCount > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(file.knowledgeMetadata.wordCount)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("words")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if file.knowledgeMetadata.readingTimeMinutes > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(file.knowledgeMetadata.readingTimeMinutes)m")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("read time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !file.fileRelationships.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(file.fileRelationships.count)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("connections")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // AI-generated summary preview
            if let summary = file.aiGeneratedSummary {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text("AI Summary")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.purple)
                    }
                    
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(8)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Smart Actions Section
    
    private var smartActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smart Actions")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                SmartActionButton(
                    action: .summarize,
                    hasResult: file.aiGeneratedSummary != nil
                ) {
                    executeSmartAction(.summarize)
                }
                
                SmartActionButton(
                    action: .extractKeyPoints,
                    hasResult: !file.keyPoints.isEmpty
                ) {
                    executeSmartAction(.extractKeyPoints)
                }
                
                SmartActionButton(
                    action: .findRelated,
                    hasResult: !file.fileRelationships.isEmpty
                ) {
                    executeSmartAction(.findRelated)
                }
                
                SmartActionButton(
                    action: .suggestTags,
                    hasResult: !file.aiTags.isEmpty
                ) {
                    executeSmartAction(.suggestTags)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - Actions
    
    private func executeSmartAction(_ action: SmartFileAction) {
        selectedSmartAction = action
        isExecutingAction = true
        smartActionResult = nil
        
        Task {
            let result = await knowledgeManager.executeSmartAction(action, on: file)
            await MainActor.run {
                self.smartActionResult = result
                self.isExecutingAction = false
            }
        }
    }
}

// MARK: - Smart Action Button Component

struct SmartActionButton: View {
    let action: SmartFileAction
    let hasResult: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: action.icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(action.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hasResult {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - File Content View

struct FileContentView: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    @State private var content: String = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Content header
            HStack {
                Text("File Content")
                    .font(.headline)
                
                Spacer()
                
                Button("Show in Finder") {
                    let fileURL = knowledgeManager.fileManager.getFileURL(for: convertToProjectFile(file))
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: fileURL.deletingLastPathComponent().path)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            
            Divider()
            
            // Content display
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading content...")
                    Spacer()
                }
            } else if content.isEmpty {
                VStack {
                    Spacer()
                    Text("Content preview not available for this file type")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Content with syntax highlighting for code files
                        if file.fileExtension.lowercased().contains(where: { ["py", "js", "swift", "java"].contains($0) }) {
                            CodeContentView(content: content, language: file.fileExtension)
                        } else {
                            Text(content)
                                .textSelection(.enabled)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFileContent()
        }
    }
    
    private func loadFileContent() {
        Task {
            do {
                if let fileContent = try knowledgeManager.fileManager.readFileContent(for: convertToProjectFile(file)) {
                    await MainActor.run {
                        self.content = fileContent
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.content = ""
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.content = ""
                    self.isLoading = false
                }
            }
        }
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

// MARK: - Code Content View with Syntax Highlighting

struct CodeContentView: View {
    let content: String
    let language: String
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with language
                HStack {
                    Text(language.uppercased())
                        .font(.caption)
                        .bold()
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                
                Divider()
                
                // Code content with line numbers
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...content.components(separatedBy: .newlines).count, id: \.self) { lineNumber in
                            Text("\(lineNumber)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                                .padding(.vertical, 1)
                        }
                    }
                    .padding(.leading)
                    .background(Color.gray.opacity(0.05))
                    
                    // Code content
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - AI Insights View

struct AIInsightsView: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("AI Insights")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Refresh Insights") {
                        Task {
                            _ = await knowledgeManager.executeSmartAction(.generateMetadata, on: file)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Summary section
                if let summary = file.aiGeneratedSummary {
                    InsightSection(title: "AI Summary", icon: "text.alignleft", color: .blue) {
                        Text(summary)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                )
                
            case .keyPoints(let points):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Points")
                            .font(.headline)
                        
                        ForEach(points, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(point)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                )
                
            case .relatedFiles(let files):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Files")
                            .font(.headline)
                        
                        ForEach(files, id: \.id) { relatedFile in
                            HStack {
                                Image(systemName: relatedFile.fileIcon)
                                    .foregroundColor(relatedFile.knowledgeMetadata.detectedContentType.color)
                                
                                VStack(alignment: .leading) {
                                    Text(relatedFile.name)
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Text(relatedFile.intelligentDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                )
                
            case .questions(let questions):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discussion Questions")
                            .font(.headline)
                        
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.blue)
                                
                                Text(question)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                )
                
            case .tags(let tags):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Tags")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                )
                
            case .entities(let entities):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Named Entities")
                            .font(.headline)
                        
                        ForEach(entities, id: \.text) { entity in
                            HStack {
                                Text(entity.text)
                                    .font(.subheadline)
                                    .bold()
                                
                                Text(entity.type.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(entityColor(entity.type).opacity(0.2))
                                    .foregroundColor(entityColor(entity.type))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                Text("\(Int(entity.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                )
                
            case .error(let message):
                AnyView(
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(message)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                )
                
            default:
                AnyView(
                    Text("Result type not implemented")
                        .foregroundColor(.secondary)
                )
            }
        }
    }
    
    private func entityColor(_ type: NamedEntity.EntityType) -> Color {
        switch type {
        case .person: return .blue
        case .organization: return .green
        case .location: return .red
        case .technology: return .purple
        case .concept: return .orange
        case .date: return .pink
        case .number: return .cyan
        }
    }
}

extension SmartFileAction: Identifiable {
    public var id: String { rawValue }
}
                            .textSelection(.enabled)
                    }
                } else {
                    InsightSection(title: "AI Summary", icon: "text.alignleft", color: .blue) {
                        Button("Generate Summary") {
                            Task {
                                _ = await knowledgeManager.executeSmartAction(.summarize, on: file)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Key points
                if !file.keyPoints.isEmpty {
                    InsightSection(title: "Key Points", icon: "list.bullet", color: .green) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(file.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    
                                    Text(point)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                
                // Topics and entities
                if !file.knowledgeMetadata.primaryTopics.isEmpty {
                    InsightSection(title: "Topics", icon: "tag", color: .purple) {
                        FlowLayout(spacing: 8) {
                            ForEach(file.knowledgeMetadata.primaryTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // AI Tags
                if !file.aiTags.isEmpty {
                    InsightSection(title: "AI Tags", icon: "sparkles", color: .orange) {
                        FlowLayout(spacing: 8) {
                            ForEach(file.aiTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Complexity analysis
                InsightSection(title: "Complexity Analysis", icon: "chart.bar", color: .red) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level:")
                                .fontWeight(.semibold)
                            Text(file.knowledgeMetadata.complexity.description)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Reading Time:")
                                .fontWeight(.semibold)
                            Text("\(file.knowledgeMetadata.readingTimeMinutes) minutes")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        if file.knowledgeMetadata.wordCount > 0 {
                            HStack {
                                Text("Word Count:")
                                    .fontWeight(.semibold)
                                Text("\(file.knowledgeMetadata.wordCount)")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Sentiment analysis
                if let sentiment = file.knowledgeMetadata.sentiment {
                    InsightSection(title: "Content Sentiment", icon: "heart", color: .pink) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tone:")
                                    .fontWeight(.semibold)
                                Text(sentiment.overallTone.rawValue.capitalized)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("Polarity:")
                                    .fontWeight(.semibold)
                                
                                Rectangle()
                                    .fill(sentiment.polarity > 0 ? Color.green : sentiment.polarity < 0 ? Color.red : Color.gray)
                                    .frame(width: abs(sentiment.polarity) * 100, height: 4)
                                    .cornerRadius(2)
                                
                                Text(String(format: "%.2f", sentiment.polarity))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - File Relationships View

struct FileRelationshipsView: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("File Connections")
                    .font(.headline)
                
                Spacer()
                
                Button("Discover New") {
                    Task {
                        _ = await knowledgeManager.executeSmartAction(.findRelated, on: file)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            
            Divider()
            
            if file.fileRelationships.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "link.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                    
                    Text("No connections found yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("AI will discover relationships as you add more files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(file.fileRelationships) { relationship in
                            if let relatedFile = knowledgeManager.allKnowledgeFiles.first(where: { $0.id == relationship.relatedFileId }) {
                                FileRelationshipCard(
                                    relationship: relationship,
                                    relatedFile: relatedFile
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - File Relationship Card

struct FileRelationshipCard: View {
    let relationship: FileRelationship
    let relatedFile: KnowledgeFile
    
    var body: some View {
        HStack(spacing: 12) {
            // Related file icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(relatedFile.knowledgeMetadata.detectedContentType.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: relatedFile.fileIcon)
                    .foregroundColor(relatedFile.knowledgeMetadata.detectedContentType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(relatedFile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(relationship.relationshipType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if !relationship.evidence.isEmpty {
                    Text(relationship.evidence.first ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Strength indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(relationship.strength * 100))%")
                    .font(.caption)
                    .bold()
                    .foregroundColor(strengthColor(relationship.strength))
                
                Rectangle()
                    .fill(strengthColor(relationship.strength))
                    .frame(width: 30, height: 4)
                    .cornerRadius(2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func strengthColor(_ strength: Double) -> Color {
        switch strength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - File Metadata View

struct FileMetadataView: View {
    let file: KnowledgeFile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("File Details")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Basic info
                    MetadataSection(title: "Basic Information") {
                        MetadataRow(label: "Name", value: file.originalName)
                        MetadataRow(label: "Type", value: file.knowledgeMetadata.detectedContentType.description)
                        MetadataRow(label: "Size", value: file.displaySize)
                        MetadataRow(label: "Extension", value: file.fileExtension.uppercased())
                    }
                    
                    // Timestamps
                    MetadataSection(title: "Timeline") {
                        MetadataRow(label: "Created", value: formatDate(file.createdAt))
                        MetadataRow(label: "Last Accessed", value: formatDate(file.lastAccessed))
                        if let lastReferenced = file.lastReferencedInChat {
                            MetadataRow(label: "Last Referenced", value: formatDate(lastReferenced))
                        }
                    }
                    
                    // Usage statistics
                    MetadataSection(title: "Usage Statistics") {
                        MetadataRow(label: "Reference Count", value: "\(file.usageCount)")
                        MetadataRow(label: "Relevance Score", value: String(format: "%.1f%%", file.relevanceScore * 100))
                        MetadataRow(label: "Project Level", value: file.isProjectLevel ? "Yes" : "No")
                    }
                    
                    // Content analysis
                    if file.knowledgeMetadata.wordCount > 0 {
                        MetadataSection(title: "Content Analysis") {
                            MetadataRow(label: "Word Count", value: "\(file.knowledgeMetadata.wordCount)")
                            MetadataRow(label: "Reading Time", value: "\(file.knowledgeMetadata.readingTimeMinutes) min")
                            MetadataRow(label: "Complexity", value: file.knowledgeMetadata.complexity.description)
                        }
                    }
                    
                    // Code languages (if applicable)
                    if !file.knowledgeMetadata.codeLanguages.isEmpty {
                        MetadataSection(title: "Programming Languages") {
                            ForEach(file.knowledgeMetadata.codeLanguages, id: \.self) { language in
                                Text(language.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

struct InsightSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            content
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MetadataSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                content
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
        
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(subviewSize))
            
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

// MARK: - Smart Action Result View

struct SmartActionResultView: View {
    let action: SmartFileAction
    let result: SmartActionResult?
    let file: KnowledgeFile
    let isExecuting: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(action.rawValue)
                        .font(.title2)
                        .bold()
                    
                    Text("for \(file.name)")
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
            
            // Content
            if isExecuting {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Processing...")
                        .font(.headline)
                        .padding(.top)
                }
            } else if let result = result {
                ScrollView {
                    resultContent(result)
                }
            } else {
                Text("No result available")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    @ViewBuilder
    private func resultContent(_ result: SmartActionResult) -> VStack<AnyView> {
        VStack(alignment: .leading, spacing: 16) {
            switch result {
            case .summary(let summary):
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI-Generated Summary")
                            .font(.headline)
                        
                        Text(summary)import SwiftUI
import QuickLook
import PDFKit

// MARK: - Knowledge File Preview - Revolutionary File Viewer

struct KnowledgeFilePreview: View {
    let file: KnowledgeFile
    @ObservedObject var knowledgeManager: KnowledgeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: PreviewTab = .content
    @State private var showingSmartActions = false
    @State private var selectedSmartAction: SmartFileAction?
    @State private var smartActionResult: SmartActionResult?
    @State private var isExecutingAction = false
    
    enum PreviewTab: String, CaseIterable {
        case content = "Content"
        case insights = "AI Insights"
        case relationships = "Connections"
        case metadata = "Details"
        
        var icon: String {
            switch self {
            case .content: return "doc.text"
            case .insights: return "brain.head.profile"
            case .relationships: return "link.circle"
            case .metadata: return "info.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar with tabs
            VStack(alignment: .leading, spacing: 0) {
                // File header
                fileHeaderSection
                
                Divider()
                
                // Tab navigation
                List(PreviewTab.allCases, id: \.rawValue, selection: $selectedTab) { tab in
                    HStack {
                        Image(systemName: tab.icon)
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Text(tab.rawValue)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    }
                    .tag(tab)
                }
                .listStyle(SidebarListStyle())
                
                Spacer()
                
                // Smart Actions
                smartActionsSection
            }
            .frame(
