import SwiftUI

struct MainSidebarView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                NavigationLink("Chat", destination:
                    ChatView(
                        projects: $projects,
                        selectedProject: $selectedProject
                    )
                )
                .tag("Chat")

                NavigationLink("Projects", destination:
                    ProjectsView(
                        projects: $projects,
                        selectedProject: $selectedProject
                    )
                )
                .tag("Projects")

                NavigationLink("Settings", destination: SettingsView())
                    .tag("Settings")
            }
            .navigationTitle("PrivateLLMCompanion")
        } detail: {
            if selectedProject != nil {
                ChatView(
                    projects: $projects,
                    selectedProject: $selectedProject
                )
            } else {
                VStack {
                    Spacer()
                    Label("No Project Selected", systemImage: "folder.fill.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Choose or create a project to begin chatting.")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
    }
}
