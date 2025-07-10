import SwiftUI

struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                .foregroundColor(message.role == .user ? .blue : .green)
            Text(message.content)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .transition(.opacity)
        .animation(.easeIn(duration: 0.3), value: message.content)
    }
}
