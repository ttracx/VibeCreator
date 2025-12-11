// SettingsView.swift
// VibeCreator - Settings and profile management

import SwiftUI
import VibeCreatorKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                profileSection

                // App Settings Section
                appSettingsSection

                // System Section
                systemSection

                // About Section
                aboutSection

                // Logout Section
                logoutSection
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.loadSettings()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            NavigationLink(destination: ProfileView()) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.currentUser?.name ?? "User")
                            .font(.headline)
                        Text(authManager.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - App Settings Section

    private var appSettingsSection: some View {
        Section("App Settings") {
            // Timezone
            Picker("Timezone", selection: $viewModel.settings.timezone) {
                ForEach(TimezoneList.timezones, id: \.self) { tz in
                    Text(tz).tag(tz)
                }
            }
            .onChange(of: viewModel.settings.timezone) { _, _ in
                Task { await viewModel.saveSettings() }
            }

            // Time Format
            Picker("Time Format", selection: $viewModel.settings.timeFormat) {
                Text("12-hour").tag(12)
                Text("24-hour").tag(24)
            }
            .onChange(of: viewModel.settings.timeFormat) { _, _ in
                Task { await viewModel.saveSettings() }
            }

            // Week Starts On
            Picker("Week Starts On", selection: $viewModel.settings.weekStartsOn) {
                Text("Sunday").tag(0)
                Text("Monday").tag(1)
            }
            .onChange(of: viewModel.settings.weekStartsOn) { _, _ in
                Task { await viewModel.saveSettings() }
            }

            // Admin Email
            HStack {
                Text("Admin Email")
                Spacer()
                TextField("Email", text: Binding(
                    get: { viewModel.settings.adminEmail ?? "" },
                    set: { viewModel.settings.adminEmail = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                #endif
            }
        }
    }

    // MARK: - System Section

    private var systemSection: some View {
        Section("System") {
            NavigationLink(destination: SystemStatusView()) {
                Label("System Status", systemImage: "server.rack")
            }

            NavigationLink(destination: SystemLogsView()) {
                Label("Logs", systemImage: "doc.text")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(AppConfig.appVersion) (\(AppConfig.buildNumber))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Framework")
                Spacer()
                Text("VibeCreatorKit \(VibeCreatorKit.version)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Logout Section

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    try? await APIClient.shared.logout()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingPasswordChange = false

    var body: some View {
        Form {
            Section("Account Information") {
                TextField("Name", text: $viewModel.name)
                TextField("Email", text: $viewModel.email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
            }

            Section {
                Button("Update Profile") {
                    Task { await viewModel.updateProfile() }
                }
                .disabled(!viewModel.hasChanges || viewModel.isLoading)
            }

            Section("Security") {
                Button("Change Password") {
                    showingPasswordChange = true
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingPasswordChange) {
            ChangePasswordView()
        }
        .onAppear {
            viewModel.name = authManager.currentUser?.name ?? ""
            viewModel.email = authManager.currentUser?.email ?? ""
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {}
        } message: {
            Text("Profile updated successfully")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var isValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                } footer: {
                    Text("Password must be at least 8 characters")
                }

                Section {
                    Button("Update Password") {
                        Task { await changePassword() }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .navigationTitle("Change Password")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func changePassword() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await APIClient.shared.updatePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - System Status View

struct SystemStatusView: View {
    @StateObject private var viewModel = SystemStatusViewModel()

    var body: some View {
        List {
            if let status = viewModel.status {
                // Environment Section
                Section("Environment") {
                    InfoRow(label: "App Name", value: status.environment.appName ?? "N/A")
                    InfoRow(label: "Version", value: status.environment.appVersion ?? "N/A")
                    InfoRow(label: "PHP Version", value: status.environment.phpVersion ?? "N/A")
                    InfoRow(label: "Laravel Version", value: status.environment.laravelVersion ?? "N/A")
                    InfoRow(label: "Environment", value: status.environment.environment ?? "N/A")
                    InfoRow(label: "Debug Mode", value: status.environment.debug == true ? "Enabled" : "Disabled")
                }

                // Health Checks Section
                Section("Health Checks") {
                    if let horizon = status.health.horizon {
                        HealthRow(label: "Horizon", status: horizon)
                    }
                    if let queue = status.health.queue {
                        HealthRow(label: "Queue", status: queue)
                    }
                    if let scheduler = status.health.scheduler {
                        HealthRow(label: "Scheduler", status: scheduler)
                    }
                    if let redis = status.health.redis {
                        HealthRow(label: "Redis", status: redis)
                    }
                    if let database = status.health.database {
                        HealthRow(label: "Database", status: database)
                    }
                }

                // Technical Info Section
                if let technical = status.technical {
                    Section("Technical") {
                        if let ffmpeg = technical.ffmpegPath {
                            InfoRow(label: "FFmpeg", value: ffmpeg)
                        }
                        if let ffprobe = technical.ffprobePath {
                            InfoRow(label: "FFprobe", value: ffprobe)
                        }
                    }
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("System Status")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { Task { await viewModel.loadStatus() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadStatus()
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Health Row

struct HealthRow: View {
    let label: String
    let status: HealthStatus

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(status.isHealthy ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(status.status)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - System Logs View

struct SystemLogsView: View {
    @State private var logs = ""
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
            } else {
                Text(logs.isEmpty ? "No logs available" : logs)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("Logs")
        .task {
            // Would load logs from API
            isLoading = false
            logs = "Log viewing is available in the web interface."
        }
    }
}

// MARK: - Settings View Model

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings = AppSettings()
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            settings = try await APIClient.shared.getSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSettings() async {
        do {
            settings = try await APIClient.shared.updateSettings(settings: settings)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Profile View Model

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var errorMessage: String?

    private var originalName = ""
    private var originalEmail = ""

    var hasChanges: Bool {
        name != originalName || email != originalEmail
    }

    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await APIClient.shared.updateProfile(name: name, email: email)
            AuthManager.shared.saveUser(user)
            originalName = name
            originalEmail = email
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - System Status View Model

@MainActor
class SystemStatusViewModel: ObservableObject {
    @Published var status: SystemStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            status = try await APIClient.shared.getSystemStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
