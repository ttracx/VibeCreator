// Media.swift
// VibeCreatorKit - Media models

import Foundation

/// Media type enum
public enum MediaType: String, Codable {
    case image = "image"
    case video = "video"
    case gif = "gif"
}

/// Media model for uploaded files
public struct Media: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let mimeType: String
    public let disk: String?
    public let path: String?
    public let url: String?
    public let thumb: String?
    public let size: Int?
    public let sizeReadable: String?
    public let conversions: [MediaConversion]?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mimeType = "mime_type"
        case disk
        case path
        case url
        case thumb
        case size
        case sizeReadable = "size_readable"
        case conversions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: Int, name: String, mimeType: String, disk: String? = nil, path: String? = nil, url: String? = nil, thumb: String? = nil, size: Int? = nil, sizeReadable: String? = nil, conversions: [MediaConversion]? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.disk = disk
        self.path = path
        self.url = url
        self.thumb = thumb
        self.size = size
        self.sizeReadable = sizeReadable
        self.conversions = conversions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Get media type from mime type
    public var mediaType: MediaType {
        if mimeType.contains("gif") {
            return .gif
        } else if mimeType.contains("video") {
            return .video
        }
        return .image
    }

    /// Get the best URL for display
    public var displayURL: URL? {
        if let thumb = thumb, let url = URL(string: thumb) {
            return url
        }
        if let urlString = url, let url = URL(string: urlString) {
            return url
        }
        return nil
    }

    /// Get full resolution URL
    public var fullURL: URL? {
        if let urlString = url {
            return URL(string: urlString)
        }
        return nil
    }
}

/// Media conversion (thumbnails, resized versions)
public struct MediaConversion: Codable, Hashable {
    public let name: String
    public let path: String
    public let url: String?

    public init(name: String, path: String, url: String? = nil) {
        self.name = name
        self.path = path
        self.url = url
    }
}

/// Media list response
public struct MediaResponse: Codable {
    public let data: [Media]
    public let meta: PaginationMeta?
    public let links: PaginationLinks?
}

/// Stock photo response (Unsplash)
public struct StockMediaResponse: Codable {
    public let data: [StockMedia]
    public let meta: StockMeta?
}

/// Stock media item
public struct StockMedia: Codable, Identifiable, Hashable {
    public let id: String
    public let url: String
    public let thumb: String?
    public let download: String?
    public let author: String?
    public let authorUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case thumb
        case download
        case author
        case authorUrl = "author_url"
    }
}

/// Stock media pagination
public struct StockMeta: Codable {
    public let page: Int
    public let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "total_pages"
    }
}

/// GIF response (Tenor)
public struct GifMediaResponse: Codable {
    public let data: [GifMedia]
    public let next: String?
}

/// GIF media item
public struct GifMedia: Codable, Identifiable, Hashable {
    public let id: String
    public let url: String
    public let preview: String?
    public let title: String?

    public init(id: String, url: String, preview: String? = nil, title: String? = nil) {
        self.id = id
        self.url = url
        self.preview = preview
        self.title = title
    }
}
