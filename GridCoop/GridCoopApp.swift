import SwiftUI
import UserNotifications

// MARK: - App Entry Point
@main
struct GridCoopApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var environmentStore = EnvironmentStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .environmentObject(projectStore)
                .environmentObject(environmentStore)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if appState.showSplash {
                SplashView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !authViewModel.isLoggedIn {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authViewModel.isLoggedIn)
    }
}
