// VibeCreatorApp.swift
// VibeCreator - Main application entry point

import SwiftUI
import VibeCreatorKit

@main
struct VibeCreatorApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appState = AppState.shared

    init() {
        // Configure the API with your backend URL
        // Change this to your actual backend URL
        VibeCreatorKit.configure(
            baseURL: AppConfig.apiBaseURL
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(appState)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About VibeCreator") {
                    appState.showAbout = true
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("New Post") {
                    appState.showNewPost = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(authManager)
                .environmentObject(appState)
        }
        #endif
    }
}

// MARK: - App State

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: Tab = .dashboard
    @Published var showNewPost = false
    @Published var showAbout = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case posts = "Posts"
        case calendar = "Calendar"
        case accounts = "Accounts"
        case media = "Media"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar"
            case .posts: return "doc.text"
            case .calendar: return "calendar"
            case .accounts: return "person.2"
            case .media: return "photo.on.rectangle"
            case .settings: return "gear"
            }
        }
    }

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - App Configuration

struct AppConfig {
    // Configure your API base URL here
    // For development, use localhost or your local server
    // For production, use your actual backend URL
    static var apiBaseURL: String {
        #if DEBUG
        // Development URL - change to your local Laravel server
        return "http://localhost:8000"
        #else
        // Production URL - change to your production server
        return "https://your-vibecreator-server.com"
        #endif
    }

    // App version info
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
