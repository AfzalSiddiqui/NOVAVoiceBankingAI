// NOVA Voice Banking AI
// Entry point for the application

import SwiftUI

@main
struct NOVAApp: App {
    @StateObject private var appState = AppState()
    private let container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.dependencyContainer, container)
                .onAppear {
                    Task {
                        await appState.initialize(container: container)
                    }
                }
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var authError: String?

    func initialize(container: DependencyContainer) async {
        defer { isLoading = false }

        do {
            let biometricAuth = container.biometricAuthManager
            let result = try await biometricAuth.authenticate(reason: "Authenticate to access NOVA Banking")
            isAuthenticated = result
        } catch {
            authError = error.localizedDescription
            isAuthenticated = false
        }
    }

    func logout() {
        isAuthenticated = false
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchScreen()
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
    }
}

// MARK: - Launch Screen

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("NOVA")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Voice Banking AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView()
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("NOVA")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("Voice Banking AI")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let error = appState.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        await appState.initialize(container: .shared)
                    }
                } label: {
                    Label("Authenticate with Face ID", systemImage: "faceid")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case voice = "Assistant"
        case transactions = "Transactions"
        case wealth = "Wealth"
        case security = "Security"

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .voice: return "waveform.circle.fill"
            case .transactions: return "arrow.left.arrow.right"
            case .wealth: return "chart.pie.fill"
            case .security: return "shield.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            VoiceAssistantView()
                .tabItem {
                    Label(Tab.voice.rawValue, systemImage: Tab.voice.icon)
                }
                .tag(Tab.voice)

            TransactionsView()
                .tabItem {
                    Label(Tab.transactions.rawValue, systemImage: Tab.transactions.icon)
                }
                .tag(Tab.transactions)

            WealthView()
                .tabItem {
                    Label(Tab.wealth.rawValue, systemImage: Tab.wealth.icon)
                }
                .tag(Tab.wealth)

            SecurityView()
                .tabItem {
                    Label(Tab.security.rawValue, systemImage: Tab.security.icon)
                }
                .tag(Tab.security)
        }
        .tint(.blue)
    }
}
