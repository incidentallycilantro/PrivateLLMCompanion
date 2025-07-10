import SwiftUI

struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundColor(.gray)
            Text("Assistant is typing...")
                .foregroundColor(.gray)
        }
        .transition(.opacity)
    }
}
