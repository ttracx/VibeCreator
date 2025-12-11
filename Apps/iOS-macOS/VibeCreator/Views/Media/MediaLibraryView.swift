// MediaLibraryView.swift
// VibeCreator - Media library management

import SwiftUI
import PhotosUI
import VibeCreatorKit

struct MediaLibraryView: View {
    @StateObject private var viewModel = MediaLibraryViewModel()
    @State private var selectedTab: MediaTab = .uploads
    @State private var searchText = ""
    @State private var showingUploader = false
    @State private var selectedItems: Set<Int> = []

    enum MediaTab: String, CaseIterable {
        case uploads = "Uploads"
        case stock = "Stock"
        case gifs = "GIFs"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Media Type", selection: $selectedTab) {
                    ForEach(MediaTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Search bar (for stock and gifs)
                if selectedTab != .uploads {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                Task { await performSearch() }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.bottom)
                }

                // Content
                Group {
                    switch selectedTab {
                    case .uploads:
                        uploadsView
                    case .stock:
                        stockView
                    case .gifs:
                        gifsView
                    }
                }
            }
            .navigationTitle("Media")
            .toolbar {
                if selectedTab == .uploads {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingUploader = true }) {
                            Label("Upload", systemImage: "square.and.arrow.up")
                        }
                    }

                    if !selectedItems.isEmpty {
                        ToolbarItem(placement: .automatic) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteSelected(ids: Array(selectedItems)) }
                                selectedItems.removeAll()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingUploader) {
                MediaUploaderView {
                    Task { await viewModel.loadUploads() }
                }
            }
            .task {
                await viewModel.loadUploads()
            }
        }
    }

    // MARK: - Uploads View

    private var uploadsView: some View {
        Group {
            if viewModel.isLoading && viewModel.uploads.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.uploads.isEmpty {
                emptyUploadsState
            } else {
                mediaGrid(items: viewModel.uploads) { media in
                    toggleSelection(media.id)
                }
            }
        }
    }

    // MARK: - Stock View

    private var stockView: some View {
        Group {
            if viewModel.isLoadingStock && viewModel.stockPhotos.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.stockPhotos.isEmpty {
                if searchText.isEmpty {
                    searchPrompt("Search for stock photos")
                } else {
                    noResultsView
                }
            } else {
                stockGrid
            }
        }
    }

    // MARK: - GIFs View

    private var gifsView: some View {
        Group {
            if viewModel.isLoadingGifs && viewModel.gifs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.gifs.isEmpty {
                if searchText.isEmpty {
                    searchPrompt("Search for GIFs")
                } else {
                    noResultsView
                }
            } else {
                gifsGrid
            }
        }
    }

    // MARK: - Media Grid

    private func mediaGrid(items: [Media], onTap: @escaping (Media) -> Void) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150))
            ], spacing: 8) {
                ForEach(items) { media in
                    MediaGridItem(
                        media: media,
                        isSelected: selectedItems.contains(media.id)
                    ) {
                        onTap(media)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Stock Grid

    private var stockGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150, maximum: 200))
            ], spacing: 8) {
                ForEach(viewModel.stockPhotos) { photo in
                    StockPhotoItem(photo: photo) {
                        Task {
                            await viewModel.downloadStockPhoto(photo)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - GIFs Grid

    private var gifsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120, maximum: 180))
            ], spacing: 8) {
                ForEach(viewModel.gifs) { gif in
                    GifItem(gif: gif) {
                        Task {
                            await viewModel.downloadGif(gif)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private var emptyUploadsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No media uploaded")
                .font(.title2)
                .fontWeight(.medium)

            Text("Upload images, videos, or GIFs to use in your posts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingUploader = true }) {
                Label("Upload Media", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func searchPrompt(_ text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No results found")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func toggleSelection(_ id: Int) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }

    private func performSearch() async {
        switch selectedTab {
        case .uploads:
            break
        case .stock:
            await viewModel.searchStock(query: searchText)
        case .gifs:
            await viewModel.searchGifs(query: searchText)
        }
    }
}

// MARK: - Media Grid Item

struct MediaGridItem: View {
    let media: Media
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: media.displayURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, .blue)
                        .padding(4)
                }

                // Media type indicator
                if media.mediaType == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if media.mediaType == .gif {
                    Text("GIF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stock Photo Item

struct StockPhotoItem: View {
    let photo: StockMedia
    let onDownload: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: URL(string: photo.thumb ?? photo.url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Attribution and download button
            HStack {
                if let author = photo.author {
                    Text("by \(author)")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onDownload) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - GIF Item

struct GifItem: View {
    let gif: GifMedia
    let onDownload: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(url: URL(string: gif.preview ?? gif.url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.white)
                    .padding(8)
            }
        }
    }
}

// MARK: - Media Uploader View

struct MediaUploaderView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("Upload Media")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Select images, videos, or GIFs from your library")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if isUploading {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                } else {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 10,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Select from Library", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Upload")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    await uploadSelectedItems(items)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func uploadSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        isUploading = true
        let totalItems = Double(items.count)

        for (index, item) in items.enumerated() {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // Determine mime type
                    let mimeType = "image/jpeg" // Simplified, would need proper detection

                    _ = try await APIClient.shared.uploadMedia(
                        data: data,
                        filename: "upload_\(index).jpg",
                        mimeType: mimeType
                    )
                }

                uploadProgress = Double(index + 1) / totalItems
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isUploading = false
        onComplete()
        dismiss()
    }
}

// MARK: - Media Picker View (for post creation)

struct MediaPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMedia: [Media]

    @StateObject private var viewModel = MediaLibraryViewModel()
    @State private var localSelection: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 150))
                    ], spacing: 8) {
                        ForEach(viewModel.uploads) { media in
                            MediaGridItem(
                                media: media,
                                isSelected: localSelection.contains(media.id)
                            ) {
                                toggleSelection(media)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Media")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedMedia = viewModel.uploads.filter { localSelection.contains($0.id) }
                        dismiss()
                    }
                    .disabled(localSelection.isEmpty)
                }
            }
            .task {
                await viewModel.loadUploads()
                localSelection = Set(selectedMedia.map(\.id))
            }
        }
    }

    private func toggleSelection(_ media: Media) {
        if localSelection.contains(media.id) {
            localSelection.remove(media.id)
        } else {
            localSelection.insert(media.id)
        }
    }
}

// MARK: - Media Library View Model

@MainActor
class MediaLibraryViewModel: ObservableObject {
    @Published var uploads: [Media] = []
    @Published var stockPhotos: [StockMedia] = []
    @Published var gifs: [GifMedia] = []
    @Published var isLoading = false
    @Published var isLoadingStock = false
    @Published var isLoadingGifs = false
    @Published var errorMessage: String?

    func loadUploads() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.getMedia()
            uploads = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchStock(query: String) async {
        guard !query.isEmpty else { return }

        isLoadingStock = true
        defer { isLoadingStock = false }

        do {
            let response = try await APIClient.shared.searchStockPhotos(query: query)
            stockPhotos = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchGifs(query: String) async {
        guard !query.isEmpty else { return }

        isLoadingGifs = true
        defer { isLoadingGifs = false }

        do {
            let response = try await APIClient.shared.searchGifs(query: query)
            gifs = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func downloadStockPhoto(_ photo: StockMedia) async {
        do {
            guard let downloadURL = photo.download else { return }
            _ = try await APIClient.shared.downloadExternalMedia(url: downloadURL)
            await loadUploads()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func downloadGif(_ gif: GifMedia) async {
        do {
            _ = try await APIClient.shared.downloadExternalMedia(url: gif.url)
            await loadUploads()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSelected(ids: [Int]) async {
        do {
            try await APIClient.shared.deleteMedia(ids: ids)
            uploads.removeAll { ids.contains($0.id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    MediaLibraryView()
}
