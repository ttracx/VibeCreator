// EditPostView.swift
// VibeCreator - Edit existing posts

import SwiftUI
import VibeCreatorKit

struct EditPostView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    @StateObject private var viewModel: EditPostViewModel

    @State private var showingMediaPicker = false
    @State private var showingScheduler = false
    @State private var showingDeleteConfirmation = false

    init(post: Post) {
        self.post = post
        self._viewModel = StateObject(wrappedValue: EditPostViewModel(post: post))
    }

    var body: some View {
        Form {
            // Status badge
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    StatusBadge(status: post.status)
                }
            }

            // Account Selection
            accountsSection

            // Content Editor
            contentSection

            // Media Section
            mediaSection

            // Tags Section
            tagsSection

            // Schedule Section
            scheduleSection

            // Actions Section
            actionsSection
        }
        .navigationTitle("Edit Post")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveChanges()
                        dismiss()
                    }
                }
                .disabled(!viewModel.hasChanges || viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(selectedMedia: $viewModel.selectedMedia)
        }
        .sheet(isPresented: $showingScheduler) {
            SchedulePickerView(selectedDate: $viewModel.scheduledDate) {
                Task {
                    await viewModel.reschedule()
                    dismiss()
                }
            }
        }
        .confirmationDialog("Delete Post", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePost()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        Section("Accounts") {
            if viewModel.accounts.isEmpty {
                Text("No accounts connected")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.accounts) { account in
                            AccountSelectionChip(
                                account: account,
                                isSelected: viewModel.selectedAccounts.contains(account)
                            ) {
                                viewModel.toggleAccount(account)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 150)

                HStack {
                    Spacer()
                    Text("\(viewModel.content.count)")
                        .font(.caption)
                        .foregroundStyle(viewModel.isOverCharacterLimit ? .red : .secondary)

                    if let limit = viewModel.characterLimit {
                        Text("/ \(limit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Content")
        }
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        Section("Media") {
            if viewModel.selectedMedia.isEmpty {
                Button(action: { showingMediaPicker = true }) {
                    Label("Add Media", systemImage: "photo.on.rectangle.angled")
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedMedia) { media in
                            MediaThumbnail(media: media) {
                                viewModel.removeMedia(media)
                            }
                        }

                        Button(action: { showingMediaPicker = true }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        Section("Tags") {
            if viewModel.availableTags.isEmpty {
                Text("No tags available")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.availableTags) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: viewModel.selectedTags.contains(tag)
                            ) {
                                viewModel.toggleTag(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        Section("Schedule") {
            if let date = viewModel.scheduledDate {
                HStack {
                    Label(date.formattedDateTime(), systemImage: "clock")
                    Spacer()
                    if post.status == .scheduled || post.status == .draft {
                        Button("Change") {
                            showingScheduler = true
                        }
                    }
                }
            } else if post.status == .draft {
                Button(action: { showingScheduler = true }) {
                    Label("Schedule for later", systemImage: "clock")
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            if post.status == .failed {
                Button(action: { Task { await viewModel.retryPublish() } }) {
                    Label("Retry Publishing", systemImage: "arrow.clockwise")
                }
            }

            Button(action: { Task { await viewModel.duplicatePost() } }) {
                Label("Duplicate Post", systemImage: "doc.on.doc")
            }

            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete Post", systemImage: "trash")
            }
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: PostStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .scheduled: return .blue
        case .published: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Edit Post View Model

@MainActor
class EditPostViewModel: ObservableObject {
    let post: Post

    @Published var content = ""
    @Published var accounts: [Account] = []
    @Published var selectedAccounts: [Account] = []
    @Published var selectedMedia: [Media] = []
    @Published var availableTags: [Tag] = []
    @Published var selectedTags: [Tag] = []
    @Published var scheduledDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var originalContent = ""
    private var originalAccountIds: Set<Int> = []
    private var originalMediaIds: Set<Int> = []
    private var originalTagIds: Set<Int> = []

    var hasChanges: Bool {
        content != originalContent ||
        Set(selectedAccounts.map(\.id)) != originalAccountIds ||
        Set(selectedMedia.map(\.id)) != originalMediaIds ||
        Set(selectedTags.map(\.id)) != originalTagIds
    }

    var characterLimit: Int? {
        selectedAccounts.map { $0.provider.characterLimit }.min()
    }

    var isOverCharacterLimit: Bool {
        guard let limit = characterLimit else { return false }
        return content.count > limit
    }

    init(post: Post) {
        self.post = post
        self.content = post.primaryContent ?? ""
        self.originalContent = self.content
        self.scheduledDate = post.scheduledAt
        self.selectedMedia = post.allMedia
        self.originalMediaIds = Set(post.allMedia.map(\.id))
        self.selectedTags = post.tags ?? []
        self.originalTagIds = Set((post.tags ?? []).map(\.id))
        self.selectedAccounts = post.accounts ?? []
        self.originalAccountIds = Set((post.accounts ?? []).map(\.id))
    }

    func loadData() async {
        do {
            accounts = try await APIClient.shared.getAccounts()
            availableTags = try await APIClient.shared.getTags()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAccount(_ account: Account) {
        if let index = selectedAccounts.firstIndex(of: account) {
            selectedAccounts.remove(at: index)
        } else {
            selectedAccounts.append(account)
        }
    }

    func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    func removeMedia(_ media: Media) {
        selectedMedia.removeAll { $0.id == media.id }
    }

    func saveChanges() async {
        isLoading = true
        defer { isLoading = false }

        let versions = selectedAccounts.map { account in
            CreatePostVersionRequest(
                accountId: account.id,
                content: [["type": "text", "value": content]],
                media: selectedMedia.map { $0.id }
            )
        }

        let request = CreatePostRequest(
            accounts: selectedAccounts.map { $0.id },
            versions: versions,
            tags: selectedTags.map { $0.id }
        )

        do {
            _ = try await APIClient.shared.updatePost(id: post.id, post: request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reschedule() async {
        guard let date = scheduledDate else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await APIClient.shared.schedulePost(id: post.id, scheduledAt: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retryPublish() async {
        scheduledDate = Date()
        await reschedule()
    }

    func duplicatePost() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await APIClient.shared.duplicatePost(id: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePost() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await APIClient.shared.deletePost(id: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditPostView(post: Post(id: 1, status: .draft))
    }
}
