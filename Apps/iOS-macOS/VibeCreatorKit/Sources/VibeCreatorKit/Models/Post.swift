// Post.swift
// VibeCreatorKit - Post models

import Foundation

/// Post status enum matching backend
public enum PostStatus: Int, Codable, CaseIterable {
    case draft = 0
    case scheduled = 1
    case published = 2
    case failed = 3

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .scheduled: return "Scheduled"
        case .published: return "Published"
        case .failed: return "Failed"
        }
    }

    public var color: String {
        switch self {
        case .draft: return "gray"
        case .scheduled: return "blue"
        case .published: return "green"
        case .failed: return "red"
        }
    }
}

/// Post schedule status enum
public enum PostScheduleStatus: Int, Codable {
    case pending = 0
    case processing = 1
    case processed = 2
}

/// Main Post model
public struct Post: Codable, Identifiable, Hashable {
    public let id: Int
    public let userId: Int?
    public let status: PostStatus
    public let scheduleStatus: PostScheduleStatus
    public let scheduledAt: Date?
    public let publishedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let deletedAt: Date?
    public let versions: [PostVersion]?
    public let accounts: [Account]?
    public let tags: [Tag]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case scheduleStatus = "schedule_status"
        case scheduledAt = "scheduled_at"
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case versions
        case accounts
        case tags
    }

    public init(id: Int, userId: Int? = nil, status: PostStatus = .draft, scheduleStatus: PostScheduleStatus = .pending, scheduledAt: Date? = nil, publishedAt: Date? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil, versions: [PostVersion]? = nil, accounts: [Account]? = nil, tags: [Tag]? = nil) {
        self.id = id
        self.userId = userId
        self.status = status
        self.scheduleStatus = scheduleStatus
        self.scheduledAt = scheduledAt
        self.publishedAt = publishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.versions = versions
        self.accounts = accounts
        self.tags = tags
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    /// Get the primary content for display
    public var primaryContent: String? {
        versions?.first?.content?.first?.value
    }

    /// Get all media from all versions
    public var allMedia: [Media] {
        versions?.flatMap { $0.media ?? [] } ?? []
    }
}

/// Post version for platform-specific content
public struct PostVersion: Codable, Identifiable, Hashable {
    public let id: Int
    public let postId: Int
    public let accountId: Int
    public let isOriginal: Bool
    public let content: [PostContent]?
    public let media: [Media]?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case accountId = "account_id"
        case isOriginal = "is_original"
        case content
        case media
    }

    public init(id: Int, postId: Int, accountId: Int, isOriginal: Bool = false, content: [PostContent]? = nil, media: [Media]? = nil) {
        self.id = id
        self.postId = postId
        self.accountId = accountId
        self.isOriginal = isOriginal
        self.content = content
        self.media = media
    }
}

/// Post content block
public struct PostContent: Codable, Hashable {
    public let type: String
    public let value: String

    public init(type: String = "text", value: String) {
        self.type = type
        self.value = value
    }
}

/// Request model for creating/updating posts
public struct CreatePostRequest: Codable {
    public var date: String?
    public var time: String?
    public var accounts: [Int]
    public var versions: [CreatePostVersionRequest]
    public var tags: [Int]

    public init(date: String? = nil, time: String? = nil, accounts: [Int] = [], versions: [CreatePostVersionRequest] = [], tags: [Int] = []) {
        self.date = date
        self.time = time
        self.accounts = accounts
        self.versions = versions
        self.tags = tags
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "accounts": accounts,
            "tags": tags,
            "versions": versions.map { $0.toDictionary() }
        ]

        if let date = date { dict["date"] = date }
        if let time = time { dict["time"] = time }

        return dict
    }
}

/// Request model for post versions
public struct CreatePostVersionRequest: Codable {
    public var accountId: Int
    public var content: [[String: String]]
    public var media: [Int]

    public init(accountId: Int, content: [[String: String]] = [], media: [Int] = []) {
        self.accountId = accountId
        self.content = content
        self.media = media
    }

    public func toDictionary() -> [String: Any] {
        return [
            "account_id": accountId,
            "content": content,
            "media": media
        ]
    }
}

/// Posts list response
public struct PostsResponse: Codable {
    public let data: [Post]
    public let meta: PaginationMeta?
    public let links: PaginationLinks?
}

/// Pagination metadata
public struct PaginationMeta: Codable {
    public let currentPage: Int
    public let from: Int?
    public let lastPage: Int
    public let perPage: Int
    public let to: Int?
    public let total: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case perPage = "per_page"
        case to
        case total
    }
}

/// Pagination links
public struct PaginationLinks: Codable {
    public let first: String?
    public let last: String?
    public let prev: String?
    public let next: String?
}
