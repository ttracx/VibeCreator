// AccountsView.swift
// VibeCreator - Social account management

import SwiftUI
import VibeCreatorKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @State private var showingAddAccount = false
    @State private var accountToDelete: Account?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.accounts.isEmpty {
                    emptyState
                } else {
                    accountsGrid
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAccount = true }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView {
                    Task { await viewModel.loadAccounts() }
                }
            }
            .confirmationDialog(
                "Remove Account",
                isPresented: .constant(accountToDelete != nil),
                presenting: accountToDelete
            ) { account in
                Button("Remove", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount(account)
                        accountToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    accountToDelete = nil
                }
            } message: { account in
                Text("Are you sure you want to remove \(account.name)? This will not delete any scheduled posts.")
            }
            .refreshable {
                await viewModel.loadAccounts()
            }
            .task {
                await viewModel.loadAccounts()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Accounts Grid

    private var accountsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: 400))
            ], spacing: 16) {
                ForEach(viewModel.accounts) { account in
                    AccountCard(
                        account: account,
                        onRefresh: {
                            Task { await viewModel.refreshAccount(account) }
                        },
                        onDelete: {
                            accountToDelete = account
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No accounts connected")
                .font(.title2)
                .fontWeight(.medium)

            Text("Connect your social media accounts to start scheduling posts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingAddAccount = true }) {
                Label("Add Account", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Account Card

struct AccountCard: View {
    let account: Account
    let onRefresh: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Profile image
                CachedAsyncImage(url: account.profileImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: account.provider.iconName)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.separator), lineWidth: 1)
                )

                // Account info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .lineLimit(1)

                    if let username = account.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: account.provider.iconName)
                            .font(.caption)
                        Text(account.provider.displayName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Status indicator
                Circle()
                    .fill(account.authorized ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            }

            // Stats
            if let data = account.data {
                HStack(spacing: 0) {
                    if let followers = data.followers {
                        StatItem(value: formatNumber(followers), label: "Followers")
                    }
                    if let following = data.following {
                        StatItem(value: formatNumber(following), label: "Following")
                    }
                    if let posts = data.posts {
                        StatItem(value: formatNumber(posts), label: "Posts")
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onDelete) {
                    Label("Remove", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Account View

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    let providers: [(provider: SocialProvider, icon: String, color: Color)] = [
        (.twitter, "bird", .blue),
        (.facebookPage, "person.2.fill", .indigo),
        (.facebookGroup, "person.3.fill", .indigo),
        (.mastodon, "globe", .purple)
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(providers, id: \.provider) { item in
                    Button(action: { connectAccount(item.provider) }) {
                        HStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(item.color.opacity(0.2))
                                .foregroundStyle(item.color)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.provider.displayName)
                                    .font(.headline)
                                Text(getProviderDescription(item.provider))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func getProviderDescription(_ provider: SocialProvider) -> String {
        switch provider {
        case .twitter:
            return "Post tweets and threads"
        case .facebookPage:
            return "Manage your Facebook Pages"
        case .facebookGroup:
            return "Post to Facebook Groups"
        case .mastodon:
            return "Connect to any Mastodon instance"
        }
    }

    private func connectAccount(_ provider: SocialProvider) {
        isLoading = true

        Task {
            do {
                let response = try await APIClient.shared.getOAuthURL(provider: provider.rawValue)

                // Open OAuth URL in browser/web view
                if let url = URL(string: response.url) {
                    #if os(iOS)
                    await UIApplication.shared.open(url)
                    #elseif os(macOS)
                    NSWorkspace.shared.open(url)
                    #endif
                }

                // Note: In a real implementation, you would handle the OAuth callback
                // This would typically involve a custom URL scheme or universal link

                dismiss()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}

// MARK: - Accounts View Model

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await APIClient.shared.getAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAccount(_ account: Account) async {
        do {
            let updated = try await APIClient.shared.updateAccount(id: account.id)
            if let index = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount(_ account: Account) async {
        do {
            try await APIClient.shared.deleteAccount(id: account.id)
            accounts.removeAll { $0.id == account.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    AccountsView()
}
