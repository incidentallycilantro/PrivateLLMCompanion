import SwiftUI

struct ProjectsView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $selectedProject) {
                ForEach(projects) { project in
                    Text(project.title)
                        .tag(project) // Correctly tags the project
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                delete(project: project)
                            }
                        }
                }
            }
            .frame(minWidth: 200)
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup {
                    Button(action: createProject) {
                        Image(systemName: "plus")
                    }
                    Button(action: deleteSelectedProject) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedProject == nil)
                }
            }

            Divider()

            if let binding = binding(for: selectedProject) {
                Form {
                    TextField("Project Title", text: binding.title)
                    TextField("Description", text: binding.description, axis: .vertical)
                    TextField("Project Summary", text: binding.projectSummary, axis: .vertical)
                    TextField("Chat Summary", text: binding.chatSummary, axis: .vertical)
                }
                .padding()
                .frame(minWidth: 300)
            } else {
                VStack {
                    Spacer()
                    Label("No Project Selected", systemImage: "folder")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Select or create a project to view and edit details.")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(minWidth: 300)
            }
        }
    }

    private func binding(for project: Project?) -> Binding<Project>? {
        guard let project = project,
              let index = projects.firstIndex(where: { $0.id == project.id }) else {
            return nil
        }
        return $projects[index]
    }

    private func createProject() {
        let newProject = Project(
            id: UUID(),
            title: "Untitled Project",
            description: "",
            createdAt: Date(),
            chats: [],
            projectSummary: "",
            chatSummary: ""
        )
        projects.append(newProject)
        selectedProject = newProject
    }

    private func deleteSelectedProject() {
        if let selected = selectedProject {
            delete(project: selected)
        }
    }

    private func delete(project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
        }
    }
}
