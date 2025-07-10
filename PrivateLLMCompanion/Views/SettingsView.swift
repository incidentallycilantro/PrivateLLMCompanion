import SwiftUI

struct SettingsView: View {
    @StateObject private var modelManager = DynamicModelManager()
    @StateObject private var ollamaService = OllamaService()
    @State private var showingModelDetails = false
    @State private var selectedModel: DynamicModelManager.ModelInfo?
    @State private var showingInstallSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Ollama Connection Status
                    connectionStatusSection
                    
                    Divider()
                    
                    // Model Management
                    modelManagementSection
                    
                    Divider()
                    
                    // Auto-Optimization Settings
                    optimizationSection
                    
                    Divider()
                    
                    // System Information
                    systemInfoSection
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingModelDetails) {
            if let model = selectedModel {
                ModelDetailSheet(model: model, modelManager: modelManager, ollamaService: ollamaService)
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            ModelInstallationSheet(modelManager: modelManager, ollamaService: ollamaService)
        }
        .onAppear {
            Task {
                await ollamaService.checkConnection()
                await modelManager.refreshAvailableModels()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Settings")
                        .font(.title2)
                        .bold()
                    Text("Configure AI models and optimization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh Models") {
                    Task {
                        await modelManager.refreshAvailableModels()
                        await ollamaService.checkConnection()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(modelManager.isRefreshing)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ollama Connection", systemImage: "network")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(ollamaService.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(ollamaService.isConnected ? "Connected to Ollama" : "Ollama not available")
                    .font(.subheadline)
                    .foregroundColor(ollamaService.isConnected ? .primary : .secondary)
                
                Spacer()
                
                if !ollamaService.isConnected {
                    Button("Retry") {
                        Task {
                            await ollamaService.checkConnection()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if !ollamaService.isConnected {
                Text("Make sure Ollama is installed and running. Visit ollama.ai for installation instructions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Model Management Section
    
    private var modelManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Models", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Spacer()
                
                Button("Install Model") {
                    showingInstallSheet = true
                }
                .buttonStyle(.bordered)
                .disabled(!ollamaService.isConnected)
            }
            
            if modelManager.isRefreshing {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Discovering models...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if modelManager.availableModels.isEmpty {
                emptyModelsView
            } else {
                modelListView
            }
        }
    }
    
    private var emptyModelsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No models detected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Install models using Ollama CLI or the install button above")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Learn How to Install Models") {
                if let url = URL(string: "https://ollama.ai/library") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var modelListView: some View {
        VStack(spacing: 8) {
            ForEach(modelManager.availableModels, id: \.name) { model in
                ModelRowView(
                    model: model,
                    isPreferred: model.name == modelManager.userPreferredModel,
                    onSelect: {
                        selectedModel = model
                        showingModelDetails = true
                    },
                    onSetPreferred: {
                        modelManager.setPreferredModel(model.name)
                    }
                )
            }
        }
    }
    
    // MARK: - Optimization Section
    
    private var optimizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Smart Optimization", systemImage: "cpu")
                .font(.headline)
            
            Toggle("Auto-select best model for each task", isOn: $modelManager.autoOptimizationEnabled)
                .onChange(of: modelManager.autoOptimizationEnabled) { _ in
                    modelManager.toggleAutoOptimization()
                }
            
            if modelManager.autoOptimizationEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("System automatically chooses optimal models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Simple questions → Fast, small models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Complex reasoning → Powerful models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "curlybraces")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Code tasks → Specialized coding models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading)
                .padding(.top, 4)
            } else {
                HStack {
                    Text("Default Model:")
                        .font(.subheadline)
                    
                    Picker("Default Model", selection: $modelManager.userPreferredModel) {
                        Text("Auto-select").tag(nil as String?)
                        ForEach(modelManager.availableModels, id: \.name) { model in
                            Text(model.name).tag(model.name as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - System Information Section
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("System Resources", systemImage: "memorychip")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Available Memory:")
                        .font(.subheadline)
                    Text(formatMemory(SystemResourceMonitor.shared.availableMemory))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                GridRow {
                    Text("System Load:")
                        .font(.subheadline)
                    HStack {
                        Circle()
                            .fill(loadColor)
                            .frame(width: 8, height: 8)
                        Text(loadText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                GridRow {
                    Text("Installed Models:")
                        .font(.subheadline)
                    Text("\(modelManager.availableModels.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if !modelManager.availableModels.isEmpty {
                let totalSize = modelManager.availableModels.reduce(0) { $0 + $1.size }
                
                HStack {
                    Text("Total Model Storage:")
                        .font(.subheadline)
                    Text(formatMemory(totalSize))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Properties
    
    private var loadColor: Color {
        switch SystemResourceMonitor.shared.currentLoad {
        case .normal: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    private var loadText: String {
        switch SystemResourceMonitor.shared.currentLoad {
        case .normal: return "Normal"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatMemory(_ sizeInMB: Int) -> String {
        if sizeInMB < 1024 {
            return "\(sizeInMB) MB"
        } else {
            let sizeInGB = Double(sizeInMB) / 1024.0
            return String(format: "%.1f GB", sizeInGB)
        }
    }
}

// MARK: - Model Row Component

struct ModelRowView: View {
    let model: DynamicModelManager.ModelInfo
    let isPreferred: Bool
    let onSelect: () -> Void
    let onSetPreferred: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Model icon based on specialty
            Image(systemName: modelIcon)
                .font(.title2)
                .foregroundColor(modelColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                    
                    if isPreferred {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(formatSize(model.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(model.parameters)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    if let quantization = model.quantization {
                        Text(quantization)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(model.specialty?.rawValue.capitalized ?? "General")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 8) {
                Button("Details") {
                    onSelect()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if !isPreferred {
                    Button("Set Default") {
                        onSetPreferred()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPreferred ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var modelIcon: String {
        switch model.specialty {
        case .coding: return "curlybraces"
        case .math: return "function"
        case .creative: return "paintbrush"
        case .chat: return "bubble.left.and.bubble.right"
        default: return "brain.head.profile"
        }
    }
    
    private var modelColor: Color {
        switch model.specialty {
        case .coding: return .green
        case .math: return .blue
        case .creative: return .purple
        case .chat: return .orange
        default: return .primary
        }
    }
    
    private func formatSize(_ sizeInMB: Int) -> String {
        if sizeInMB < 1024 {
            return "\(sizeInMB) MB"
        } else {
            let sizeInGB = Double(sizeInMB) / 1024.0
            return String(format: "%.1f GB", sizeInGB)
        }
    }
}

// MARK: - Model Detail Sheet

struct ModelDetailSheet: View {
    let model: DynamicModelManager.ModelInfo
    let modelManager: DynamicModelManager
    let ollamaService: OllamaService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model header
            HStack {
                Image(systemName: modelIcon)
                    .font(.largeTitle)
                    .foregroundColor(modelColor)
                
                VStack(alignment: .leading) {
                    Text(model.name)
                        .font(.title)
                        .bold()
                    Text("\(model.parameters) • \(formatSize(model.size))")
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
            
            // Capabilities
            VStack(alignment: .leading, spacing: 8) {
                Text("Capabilities")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(model.capabilities), id: \.self) { capability in
                        HStack {
                            Image(systemName: capabilityIcon(capability))
                            Text(capabilityName(capability))
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            // Performance Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Load Time:")
                        Text("\(String(format: "%.1f", model.loadTime))s")
                            .foregroundColor(.secondary)
                    }
                    GridRow {
                        Text("Memory Usage:")
                        Text(formatSize(model.memoryFootprint))
                            .foregroundColor(.secondary)
                    }
                    if let quantization = model.quantization {
                        GridRow {
                            Text("Quantization:")
                            Text(quantization)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Set as Default") {
                    modelManager.setPreferredModel(model.name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Remove Model", role: .destructive) {
                    showingDeleteAlert = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .alert("Remove Model", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    let success = await ollamaService.removeModel(model.name)
                    if success {
                        await modelManager.refreshAvailableModels()
                    }
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to remove \(model.name)? This will free up \(formatSize(model.size)) of disk space.")
        }
    }
    
    private var modelIcon: String {
        switch model.specialty {
        case .coding: return "curlybraces"
        case .math: return "function"
        case .creative: return "paintbrush"
        case .chat: return "bubble.left.and.bubble.right"
        default: return "brain.head.profile"
        }
    }
    
    private var modelColor: Color {
        switch model.specialty {
        case .coding: return .green
        case .math: return .blue
        case .creative: return .purple
        case .chat: return .orange
        default: return .primary
        }
    }
    
    private func formatSize(_ sizeInMB: Int) -> String {
        if sizeInMB < 1024 {
            return "\(sizeInMB) MB"
        } else {
            let sizeInGB = Double(sizeInMB) / 1024.0
            return String(format: "%.1f GB", sizeInGB)
        }
    }
    
    private func capabilityIcon(_ capability: DynamicModelManager.ModelCapability) -> String {
        switch capability {
        case .basicQA: return "questionmark.circle"
        case .codeGeneration: return "curlybraces"
        case .complexReasoning: return "brain"
        case .mathematics: return "function"
        case .translation: return "globe"
        case .multimodal: return "photo.on.rectangle"
        case .function_calling: return "gear"
        case .creative_writing: return "paintbrush"
        case .analysis: return "chart.bar"
        }
    }
    
    private func capabilityName(_ capability: DynamicModelManager.ModelCapability) -> String {
        switch capability {
        case .basicQA: return "Q&A"
        case .codeGeneration: return "Code Generation"
        case .complexReasoning: return "Complex Reasoning"
        case .mathematics: return "Mathematics"
        case .translation: return "Translation"
        case .multimodal: return "Multimodal"
        case .function_calling: return "Function Calling"
        case .creative_writing: return "Creative Writing"
        case .analysis: return "Analysis"
        }
    }
}

// MARK: - Model Installation Sheet

struct ModelInstallationSheet: View {
    let modelManager: DynamicModelManager
    let ollamaService: OllamaService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedModelToInstall = ""
    @State private var isInstalling = false
    @State private var installationStatus = ""
    
    private let popularModels = [
        ("llama3:8b", "Meta's latest Llama 3 - 8B parameters", "General purpose, very capable", "~5GB"),
        ("codellama:7b", "Code-specialized Llama model", "Best for programming tasks", "~4GB"),
        ("phi3:mini", "Microsoft's compact model", "Fast responses, basic tasks", "~2GB"),
        ("mistral:latest", "Mistral AI's flagship model", "Balanced performance and efficiency", "~4GB"),
        ("gemma:7b", "Google's open model", "Strong reasoning capabilities", "~5GB")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Install New Model")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Choose from popular models optimized for different use cases:")
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(popularModels, id: \.0) { model in
                        ModelInstallCard(
                            name: model.0,
                            description: model.1,
                            useCase: model.2,
                            size: model.3,
                            isSelected: selectedModelToInstall == model.0,
                            onSelect: {
                                selectedModelToInstall = model.0
                            }
                        )
                    }
                }
            }
            
            if !installationStatus.isEmpty {
                Text(installationStatus)
                    .font(.caption)
                    .foregroundColor(isInstalling ? .blue : .green)
                    .padding(.top)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isInstalling)
                
                Spacer()
                
                Button(isInstalling ? "Installing..." : "Install Selected") {
                    installModel()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedModelToInstall.isEmpty || isInstalling)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    private func installModel() {
        isInstalling = true
        installationStatus = "Starting installation of \(selectedModelToInstall)..."
        
        Task {
            let success = await ollamaService.installModel(selectedModelToInstall)
            
            await MainActor.run {
                self.isInstalling = false
                if success {
                    self.installationStatus = "✅ Successfully installed \(selectedModelToInstall)"
                    Task {
                        await self.modelManager.refreshAvailableModels()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.dismiss()
                        }
                    }
                } else {
                    self.installationStatus = "❌ Failed to install \(selectedModelToInstall). Please try using Ollama CLI."
                }
            }
        }
    }
}

struct ModelInstallCard: View {
    let name: String
    let description: String
    let useCase: String
    let size: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Best for: \(useCase)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
