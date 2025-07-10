import SwiftUI

struct MainView: View {
    @State private var projects: [Project] = PersistenceManager.loadProjects()
    @State private var selectedProject: Project?

    var body: some View {
        MainSidebarView(
            projects: $projects,
            selectedProject: $selectedProject
        )
        .onChange(of: projects) { _ in
            PersistenceManager.saveProjects(projects)
        }
    }
}
