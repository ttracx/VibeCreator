// CreatePostView.swift
// VibeCreator - Create and edit posts

import SwiftUI
import VibeCreatorKit

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var showingMediaPicker = false
    @State private var showingScheduler = false

    var body: some View {
        NavigationStack {
            Form {
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
            }
            .navigationTitle("Create Post")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button(action: { Task { await viewModel.saveDraft(); dismiss() } }) {
                            Label("Save Draft", systemImage: "doc")
                        }
                        Button(action: { showingScheduler = true }) {
                            Label("Schedule", systemImage: "clock")
                        }
                        Button(action: { Task { await viewModel.publishNow(); dismiss() } }) {
                            Label("Publish Now", systemImage: "paperplane")
                        }
                    } label: {
                        Text("Save")
                    }
                    .disabled(viewModel.selectedAccounts.isEmpty)
                }
            }
            .sheet(isPresented: $showingMediaPicker) {
                MediaPickerView(selectedMedia: $viewModel.selectedMedia)
            }
            .sheet(isPresented: $showingScheduler) {
                SchedulePickerView(selectedDate: $viewModel.scheduledDate) {
                    Task {
                        await viewModel.schedulePost()
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAccounts()
                await viewModel.loadTags()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
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

                // Character count
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
        } footer: {
            if viewModel.isOverCharacterLimit {
                Text("Content exceeds character limit for selected platforms")
                    .foregroundStyle(.red)
            }
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
                    Button("Change") {
                        showingScheduler = true
                    }
                    Button(role: .destructive) {
                        viewModel.scheduledDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: { showingScheduler = true }) {
                    Label("Schedule for later", systemImage: "clock")
                }
            }
        }
    }
}

// MARK: - Account Selection Chip

struct AccountSelectionChip: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: account.provider.iconName)
                    .font(.caption)
                Text(account.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Thumbnail

struct MediaThumbnail: View {
    let media: Media
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CachedAsyncImage(url: media.displayURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 4, y: -4)
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? tag.color.opacity(0.2) : Color(.tertiarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? tag.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Schedule Picker View

struct SchedulePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date?
    let onSchedule: () -> Void

    @State private var tempDate = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Schedule Date",
                    selection: $tempDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
            .navigationTitle("Schedule Post")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        selectedDate = tempDate
                        onSchedule()
                    }
                }
            }
        }
    }
}

// MARK: - Create Post View Model

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var content = ""
    @Published var accounts: [Account] = []
    @Published var selectedAccounts: [Account] = []
    @Published var selectedMedia: [Media] = []
    @Published var availableTags: [Tag] = []
    @Published var selectedTags: [Tag] = []
    @Published var scheduledDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var characterLimit: Int? {
        selectedAccounts.map { $0.provider.characterLimit }.min()
    }

    var isOverCharacterLimit: Bool {
        guard let limit = characterLimit else { return false }
        return content.count > limit
    }

    func loadAccounts() async {
        do {
            accounts = try await APIClient.shared.getAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTags() async {
        do {
            availableTags = try await APIClient.shared.getTags()
        } catch {
            // Tags are optional, don't show error
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

    func saveDraft() async {
        await savePost(schedule: false)
    }

    func schedulePost() async {
        await savePost(schedule: true)
    }

    func publishNow() async {
        scheduledDate = Date()
        await savePost(schedule: true)
    }

    private func savePost(schedule: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let versions = selectedAccounts.map { account in
            CreatePostVersionRequest(
                accountId: account.id,
                content: [["type": "text", "value": content]],
                media: selectedMedia.map { $0.id }
            )
        }

        var request = CreatePostRequest(
            accounts: selectedAccounts.map { $0.id },
            versions: versions,
            tags: selectedTags.map { $0.id }
        )

        if schedule, let date = scheduledDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            request.date = formatter.string(from: date)
            formatter.dateFormat = "HH:mm"
            request.time = formatter.string(from: date)
        }

        do {
            _ = try await APIClient.shared.createPost(post: request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePostView()
}
