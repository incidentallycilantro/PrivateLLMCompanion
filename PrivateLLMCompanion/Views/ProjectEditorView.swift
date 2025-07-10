import SwiftUI

struct ProjectEditorView: View {
    @Binding var project: Project
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Project")
                .font(.title2)
                .bold()

            TextField("Project Title", text: $project.title)
            TextField("Description", text: $project.description)

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
}
