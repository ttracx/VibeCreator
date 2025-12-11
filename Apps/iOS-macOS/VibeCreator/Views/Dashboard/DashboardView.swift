// DashboardView.swift
// VibeCreator - Main dashboard with analytics

import SwiftUI
import VibeCreatorKit

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats
                    quickStatsSection

                    // Accounts Section
                    if !viewModel.accounts.isEmpty {
                        accountsSection
                    }

                    // Recent Posts Section
                    if let posts = viewModel.dashboard?.recentPosts, !posts.isEmpty {
                        recentPostsSection(posts: posts)
                    }

                    // Selected Account Report
                    if viewModel.selectedAccount != nil {
                        reportSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showNewPost = true }) {
                        Label("New Post", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: viewModel.refresh) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Scheduled",
                value: "\(viewModel.dashboard?.scheduledCount ?? 0)",
                icon: "clock",
                color: .blue
            )

            StatCard(
                title: "Published",
                value: "\(viewModel.dashboard?.publishedCount ?? 0)",
                icon: "checkmark.circle",
                color: .green
            )

            StatCard(
                title: "Failed",
                value: "\(viewModel.dashboard?.failedCount ?? 0)",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.accounts) { account in
                        AccountChip(
                            account: account,
                            isSelected: viewModel.selectedAccount?.id == account.id
                        ) {
                            viewModel.selectAccount(account)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Recent Posts Section

    private func recentPostsSection(posts: [Post]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Posts")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: PostsListView()) {
                    Text("View All")
                        .font(.subheadline)
                }
            }

            ForEach(posts) { post in
                PostPreviewCard(post: post)
            }
        }
    }

    // MARK: - Report Section

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analytics")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $viewModel.selectedPeriod) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("90 Days").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if viewModel.isLoadingReport {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let report = viewModel.report {
                ReportSummaryView(report: report)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Account Chip

struct AccountChip: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                CachedAsyncImage(url: account.profileImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: account.provider.iconName)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(account.provider.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Post Preview Card

struct PostPreviewCard: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(post.primaryContent ?? "No content")
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    if let scheduledAt = post.scheduledAt {
                        Label(scheduledAt.formattedDateTime(), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(post.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch post.status {
        case .draft: return .gray
        case .scheduled: return .blue
        case .published: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Report Summary View

struct ReportSummaryView: View {
    let report: ReportResponse

    var body: some View {
        VStack(spacing: 16) {
            if let summary = report.summary {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MetricCard(title: "Posts", value: "\(summary.totalPosts ?? 0)")
                    MetricCard(title: "Impressions", value: formatNumber(summary.totalImpressions))
                    MetricCard(title: "Reach", value: formatNumber(summary.totalReach))
                    MetricCard(title: "Engagement", value: formatNumber(summary.totalEngagement))
                }

                if let growth = summary.followerGrowth, let percentage = summary.followerGrowthPercentage {
                    HStack {
                        Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(growth >= 0 ? .green : .red)
                        Text("\(growth >= 0 ? "+" : "")\(growth) followers (\(String(format: "%.1f", percentage))%)")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if let audience = report.audience, let history = audience.history, !history.isEmpty {
                AudienceChartView(history: history)
            }
        }
    }

    private func formatNumber(_ number: Int?) -> String {
        guard let number = number else { return "0" }
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Audience Chart View

struct AudienceChartView: View {
    let history: [AudienceHistoryPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Follower Growth")
                .font(.subheadline)
                .fontWeight(.medium)

            // Simple line representation
            GeometryReader { geometry in
                let maxCount = history.map(\.count).max() ?? 1
                let minCount = history.map(\.count).min() ?? 0
                let range = max(maxCount - minCount, 1)

                Path { path in
                    for (index, point) in history.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(history.count - 1, 1))
                        let y = geometry.size.height * (1 - CGFloat(point.count - minCount) / CGFloat(range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Dashboard View Model

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var dashboard: DashboardResponse?
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    @Published var report: ReportResponse?
    @Published var selectedPeriod: Int = 30
    @Published var isLoading = false
    @Published var isLoadingReport = false
    @Published var errorMessage: String?

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            dashboard = try await APIClient.shared.getDashboard()
            accounts = dashboard?.accounts ?? []

            if selectedAccount == nil, let firstAccount = accounts.first {
                selectAccount(firstAccount)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectAccount(_ account: Account) {
        selectedAccount = account
        Task {
            await loadReport()
        }
    }

    func loadReport() async {
        guard let accountId = selectedAccount?.id else { return }

        isLoadingReport = true
        defer { isLoadingReport = false }

        do {
            report = try await APIClient.shared.getReports(accountId: accountId, period: selectedPeriod)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() {
        Task {
            await loadDashboard()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppState.shared)
}
