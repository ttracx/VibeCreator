// PostsListView.swift
// VibeCreator - Posts list and management

import SwiftUI
import VibeCreatorKit

struct PostsListView: View {
    @StateObject private var viewModel = PostsListViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showingFilters = false
    @State private var selectedPost: Post?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar

                // Posts list
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    postsList
                }
            }
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showNewPost = true }) {
                        Label("New Post", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(PostStatus.allCases, id: \.self) { status in
                            Button(action: { viewModel.filterByStatus(status) }) {
                                Label(status.displayName, systemImage: viewModel.statusFilter == status ? "checkmark" : "")
                            }
                        }
                        Divider()
                        Button("Clear Filter") {
                            viewModel.clearFilters()
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    EditPostView(post: post)
                }
            }
            .refreshable {
                await viewModel.loadPosts()
            }
            .task {
                await viewModel.loadPosts()
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Status filter chips
                ForEach(PostStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: viewModel.statusFilter == status,
                        color: Color(status.color)
                    ) {
                        viewModel.filterByStatus(viewModel.statusFilter == status ? nil : status)
                    }
                }

                Divider()
                    .frame(height: 20)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $viewModel.searchKeyword)
                        .textFieldStyle(.plain)
                        .frame(minWidth: 100)
                        .onSubmit {
                            Task { await viewModel.loadPosts() }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Posts List

    private var postsList: some View {
        List {
            ForEach(viewModel.posts) { post in
                PostRow(post: post)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPost = post
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task { await viewModel.deletePost(post) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            Task { await viewModel.duplicatePost(post) }
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
            }

            // Load more indicator
            if viewModel.hasMorePages {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .task {
                        await viewModel.loadMorePosts()
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No posts yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Create your first post to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { appState.showNewPost = true }) {
                Label("Create Post", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? color : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Post Row

struct PostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Media thumbnail
            if let firstMedia = post.allMedia.first {
                CachedAsyncImage(url: firstMedia.displayURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.primaryContent ?? "No content")
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Date
                    if let date = post.scheduledAt ?? post.publishedAt ?? post.createdAt {
                        Text(date.relativeTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Account badges
                    if let accounts = post.accounts {
                        HStack(spacing: -4) {
                            ForEach(accounts.prefix(3)) { account in
                                Image(systemName: account.provider.iconName)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }
                    }

                    // Tags
                    if let tags = post.tags, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(2)) { tag in
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Status badge
            Text(post.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
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

// MARK: - Posts List View Model

@MainActor
class PostsListViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var statusFilter: PostStatus?
    @Published var tagFilter: Tag?
    @Published var accountFilter: Account?
    @Published var searchKeyword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentPage = 1
    private var lastPage = 1

    var hasMorePages: Bool {
        currentPage < lastPage
    }

    func loadPosts() async {
        currentPage = 1
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.getPosts(
                page: currentPage,
                status: statusFilter,
                tagId: tagFilter?.id,
                accountId: accountFilter?.id,
                keyword: searchKeyword.isEmpty ? nil : searchKeyword
            )
            posts = response.data
            lastPage = response.meta?.lastPage ?? 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMorePosts() async {
        guard hasMorePages, !isLoading else { return }

        currentPage += 1
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.getPosts(
                page: currentPage,
                status: statusFilter,
                tagId: tagFilter?.id,
                accountId: accountFilter?.id,
                keyword: searchKeyword.isEmpty ? nil : searchKeyword
            )
            posts.append(contentsOf: response.data)
            lastPage = response.meta?.lastPage ?? 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func filterByStatus(_ status: PostStatus?) {
        statusFilter = status
        Task { await loadPosts() }
    }

    func clearFilters() {
        statusFilter = nil
        tagFilter = nil
        accountFilter = nil
        searchKeyword = ""
        Task { await loadPosts() }
    }

    func deletePost(_ post: Post) async {
        do {
            try await APIClient.shared.deletePost(id: post.id)
            posts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicatePost(_ post: Post) async {
        do {
            let newPost = try await APIClient.shared.duplicatePost(id: post.id)
            posts.insert(newPost, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    PostsListView()
        .environmentObject(AppState.shared)
}
