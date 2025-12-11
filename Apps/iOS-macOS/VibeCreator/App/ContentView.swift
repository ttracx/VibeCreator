// ContentView.swift
// VibeCreator - Main content view with navigation

import SwiftUI
import VibeCreatorKit

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainNavigationView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .alert("Error", isPresented: $appState.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
    }
}

// MARK: - Main Navigation View

struct MainNavigationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        #if os(iOS)
        iOSNavigationView()
        #else
        macOSNavigationView()
        #endif
    }

    // MARK: - iOS Navigation

    @ViewBuilder
    private func iOSNavigationView() -> some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label(AppState.Tab.dashboard.rawValue, systemImage: AppState.Tab.dashboard.icon)
                }
                .tag(AppState.Tab.dashboard)

            PostsListView()
                .tabItem {
                    Label(AppState.Tab.posts.rawValue, systemImage: AppState.Tab.posts.icon)
                }
                .tag(AppState.Tab.posts)

            CalendarView()
                .tabItem {
                    Label(AppState.Tab.calendar.rawValue, systemImage: AppState.Tab.calendar.icon)
                }
                .tag(AppState.Tab.calendar)

            AccountsView()
                .tabItem {
                    Label(AppState.Tab.accounts.rawValue, systemImage: AppState.Tab.accounts.icon)
                }
                .tag(AppState.Tab.accounts)

            MediaLibraryView()
                .tabItem {
                    Label(AppState.Tab.media.rawValue, systemImage: AppState.Tab.media.icon)
                }
                .tag(AppState.Tab.media)
        }
        .sheet(isPresented: $appState.showNewPost) {
            NavigationStack {
                CreatePostView()
            }
        }
    }

    // MARK: - macOS Navigation

    @ViewBuilder
    private func macOSNavigationView() -> some View {
        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                ForEach(AppState.Tab.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .navigationTitle("VibeCreator")
        } detail: {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
            case .posts:
                PostsListView()
            case .calendar:
                CalendarView()
            case .accounts:
                AccountsView()
            case .media:
                MediaLibraryView()
            case .settings:
                SettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $appState.showNewPost) {
            CreatePostView()
                .frame(minWidth: 600, minHeight: 500)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppState.shared)
}
