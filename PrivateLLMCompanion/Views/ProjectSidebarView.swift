import SwiftUI

struct ProjectSidebarView: View {
    @Binding var projects: [Project]
    @Binding var selectedProject: Project?

    @State private var newProjectTitle: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Projects")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: createNewProject) {
                    Image(systemName: "plus.circle")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top)

            List(selection: $selectedProject) {
                ForEach(projects) { project in
                    Text(project.title)
                        .tag(project)
                }
            }
            .listStyle(SidebarListStyle())

            Spacer()
        }
        .padding()
    }

    private func createNewProject() {
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
}
