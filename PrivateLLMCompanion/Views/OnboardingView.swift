import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 20) {
            Text("👋 Welcome to Private LLM Companion")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()

            Text("Your private, local AI assistant.\nFully offline. Fully yours.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                hasSeenOnboarding = true
            }) {
                Text("Get Started")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .frame(maxWidth: 500)
        .padding()
    }
}
