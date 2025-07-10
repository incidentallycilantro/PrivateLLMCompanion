import SwiftUI

struct ProjectDetailView: View {
    @Binding var project: Project

    var body: some View {
        Form {
            Section(header: Text("Project Info")) {
                TextField("Title", text: $project.title)
                TextField("Description", text: $project.description)
            }

            Section(header: Text("Summaries")) {
                TextField("Project Summary", text: $project.projectSummary, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Chat Summary", text: $project.chatSummary, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .padding()
    }
}
