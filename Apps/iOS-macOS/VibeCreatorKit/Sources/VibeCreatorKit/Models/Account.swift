// Account.swift
// VibeCreatorKit - Social account models

import Foundation

/// Social media provider types
public enum SocialProvider: String, Codable, CaseIterable {
    case twitter = "twitter"
    case facebookPage = "facebook_page"
    case facebookGroup = "facebook_group"
    case mastodon = "mastodon"

    public var displayName: String {
        switch self {
        case .twitter: return "Twitter/X"
        case .facebookPage: return "Facebook Page"
        case .facebookGroup: return "Facebook Group"
        case .mastodon: return "Mastodon"
        }
    }

    public var iconName: String {
        switch self {
        case .twitter: return "bird"
        case .facebookPage, .facebookGroup: return "person.2"
        case .mastodon: return "globe"
        }
    }

    public var characterLimit: Int {
        switch self {
        case .twitter: return 280
        case .facebookPage, .facebookGroup: return 5000
        case .mastodon: return 500
        }
    }

    public var maxPhotos: Int {
        switch self {
        case .twitter: return 4
        case .facebookPage, .facebookGroup: return 10
        case .mastodon: return 4
        }
    }

    public var maxVideos: Int {
        return 1
    }

    public var maxGifs: Int {
        return 1
    }

    public var supportsSimultaneousPosting: Bool {
        switch self {
        case .twitter: return false
        case .facebookPage, .facebookGroup, .mastodon: return true
        }
    }
}

/// Social media account model
public struct Account: Codable, Identifiable, Hashable {
    public let id: Int
    public let userId: Int?
    public let name: String
    public let username: String?
    public let provider: SocialProvider
    public let providerId: String?
    public let media: Media?
    public let data: AccountData?
    public let authorized: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case username
        case provider
        case providerId = "provider_id"
        case media
        case data
        case authorized
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: Int, userId: Int? = nil, name: String, username: String? = nil, provider: SocialProvider, providerId: String? = nil, media: Media? = nil, data: AccountData? = nil, authorized: Bool = true, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.username = username
        self.provider = provider
        self.providerId = providerId
        self.media = media
        self.data = data
        self.authorized = authorized
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    /// Display name with username
    public var displayNameWithUsername: String {
        if let username = username, !username.isEmpty {
            return "\(name) (@\(username))"
        }
        return name
    }

    /// Profile image URL
    public var profileImageURL: URL? {
        guard let urlString = media?.url else { return nil }
        return URL(string: urlString)
    }
}

/// Additional account data
public struct AccountData: Codable, Hashable {
    public let followers: Int?
    public let following: Int?
    public let posts: Int?

    enum CodingKeys: String, CodingKey {
        case followers
        case following
        case posts
    }
}

/// Account entity (Facebook page/group selection)
public struct AccountEntity: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let username: String?
    public let image: String?

    public init(id: String, name: String, username: String? = nil, image: String? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.image = image
    }
}
