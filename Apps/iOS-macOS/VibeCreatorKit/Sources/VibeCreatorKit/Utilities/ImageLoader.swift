// ImageLoader.swift
// VibeCreatorKit - Async image loading utility

import Foundation
import SwiftUI

/// Image cache for storing loaded images
public actor ImageCache {
    public static let shared = ImageCache()

    private var cache: [URL: Image] = [:]
    private var dataCache: [URL: Data] = [:]

    private init() {}

    public func image(for url: URL) -> Image? {
        cache[url]
    }

    public func data(for url: URL) -> Data? {
        dataCache[url]
    }

    public func insert(_ image: Image, data: Data, for url: URL) {
        cache[url] = image
        dataCache[url] = data
    }

    public func removeImage(for url: URL) {
        cache.removeValue(forKey: url)
        dataCache.removeValue(forKey: url)
    }

    public func clearCache() {
        cache.removeAll()
        dataCache.removeAll()
    }
}

/// Observable image loader
@MainActor
public class ImageLoader: ObservableObject {
    @Published public var image: Image?
    @Published public var isLoading = false
    @Published public var error: Error?

    private var url: URL?
    private var task: Task<Void, Never>?

    public init() {}

    public func load(from url: URL) {
        guard self.url != url else { return }

        cancel()
        self.url = url
        self.isLoading = true
        self.error = nil

        task = Task {
            do {
                // Check cache first
                if let cachedImage = await ImageCache.shared.image(for: url) {
                    self.image = cachedImage
                    self.isLoading = false
                    return
                }

                // Download image
                let (data, _) = try await URLSession.shared.data(from: url)

                #if canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw ImageLoaderError.invalidData
                }
                let image = Image(uiImage: uiImage)
                #elseif canImport(AppKit)
                guard let nsImage = NSImage(data: data) else {
                    throw ImageLoaderError.invalidData
                }
                let image = Image(nsImage: nsImage)
                #endif

                // Cache the image
                await ImageCache.shared.insert(image, data: data, for: url)

                self.image = image
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
        isLoading = false
    }
}

public enum ImageLoaderError: Error {
    case invalidData
    case downloadFailed
}

// MARK: - Cached Async Image View

public struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let image = loader.image {
                content(image)
            } else {
                placeholder()
            }
        }
        .onAppear {
            if let url = url {
                loader.load(from: url)
            }
        }
        .onChange(of: url) { _, newURL in
            if let newURL = newURL {
                loader.load(from: newURL)
            }
        }
    }
}

// MARK: - Convenience Extension

public extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}
