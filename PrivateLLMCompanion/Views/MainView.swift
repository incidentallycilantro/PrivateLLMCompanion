import SwiftUI

struct MainView: View {
    @State private var projects: [Project] = PersistenceManager.loadProjects()
    @State private var selectedProject: Project?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if showingOnboarding {
                RevolutionaryOnboardingView(showingOnboarding: $showingOnboarding)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .opacity
                    ))
            } else {
                MainSidebarView(
                    projects: $projects,
                    selectedProject: $selectedProject
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .leading)),
                    removal: .opacity
                ))
            }
        }
        .onChange(of: projects) { _, _ in
            PersistenceManager.saveProjects(projects)
        }
        .onAppear {
            checkOnboardingStatus()
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showingOnboarding)
    }
    
    private func checkOnboardingStatus() {
        if !hasSeenOnboarding {
            showingOnboarding = true
        }
    }
}

// MARK: - Revolutionary Onboarding Experience

struct RevolutionaryOnboardingView: View {
    @Binding var showingOnboarding: Bool
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentStep = 0
    @State private var showingFeatures = false
    
    private let onboardingSteps = [
        OnboardingStep(
            icon: "bubble.left.and.bubble.right.fill",
            title: "Chat Instantly",
            subtitle: "No Setup Required",
            description: "Start chatting immediately - no projects, no folders, no friction. Just open and talk.",
            color: .blue
        ),
        OnboardingStep(
            icon: "sparkles",
            title: "AI Organizes For You",
            subtitle: "Through Conversation",
            description: "I'll analyze your conversations and suggest organization when they become substantial. No manual filing needed.",
            color: .orange
        ),
        OnboardingStep(
            icon: "brain.head.profile",
            title: "Intelligent Suggestions",
            subtitle: "Learns Your Patterns",
            description: "Tell me 'create a project for this' or 'add this to my design work' - I understand conversational commands.",
            color: .green
        ),
        OnboardingStep(
            icon: "bolt.fill",
            title: "Why This Is Different",
            subtitle: "Revolutionary UX",
            description: "ChatGPT is chaotic. Claude requires manual folders. I organize myself through conversation.",
            color: .purple
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private LLM Companion")
                        .font(.title)
                        .bold()
                    
                    Text("The AI that organizes itself")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main content
            TabView(selection: $currentStep) {
                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                    OnboardingStepView(step: onboardingSteps[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut, value: currentStep)
            
            // Controls
            VStack(spacing: 16) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < onboardingSteps.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button("Start Chatting!") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .controlSize(.large)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showingFeatures = true
                }
            }
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            showingOnboarding = false
        }
    }
}

// MARK: - Onboarding Step

struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                
                Image(systemName: step.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(step.color)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isVisible)
            
            // Content
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(step.title)
                        .font(.largeTitle)
                        .bold()
                        .opacity(isVisible ? 1.0 : 0.0)
                        .offset(y: isVisible ? 0 : 20)
                    
                    Text(step.subtitle)
                        .font(.title2)
                        .foregroundColor(step.color)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .offset(y: isVisible ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
                
                Text(step.description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 40)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
            }
            
            Spacer()
        }
        .frame(maxWidth: 600)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}
