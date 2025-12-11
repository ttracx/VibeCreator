// Calendar.swift
// VibeCreatorKit - Calendar models

import Foundation

/// Calendar response model
public struct CalendarResponse: Codable {
    public let posts: [CalendarPost]
    public let period: CalendarPeriod?

    enum CodingKeys: String, CodingKey {
        case posts
        case period
    }
}

/// Calendar post item
public struct CalendarPost: Codable, Identifiable, Hashable {
    public let id: Int
    public let status: PostStatus
    public let scheduledAt: Date?
    public let publishedAt: Date?
    public let content: String?
    public let accounts: [CalendarAccountPreview]?
    public let tags: [Tag]?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case scheduledAt = "scheduled_at"
        case publishedAt = "published_at"
        case content
        case accounts
        case tags
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: CalendarPost, rhs: CalendarPost) -> Bool {
        lhs.id == rhs.id
    }

    /// Get the effective date for calendar display
    public var effectiveDate: Date? {
        scheduledAt ?? publishedAt
    }
}

/// Preview account info for calendar
public struct CalendarAccountPreview: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let provider: SocialProvider
    public let image: String?

    public init(id: Int, name: String, provider: SocialProvider, image: String? = nil) {
        self.id = id
        self.name = name
        self.provider = provider
        self.image = image
    }
}

/// Calendar period information
public struct CalendarPeriod: Codable {
    public let start: String
    public let end: String
    public let type: String

    public var startDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: start)
    }

    public var endDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: end)
    }
}

// MARK: - Calendar Helpers

public struct CalendarDay: Identifiable, Hashable {
    public let id = UUID()
    public let date: Date
    public let isCurrentMonth: Bool
    public let isToday: Bool
    public var posts: [CalendarPost]

    public init(date: Date, isCurrentMonth: Bool = true, isToday: Bool = false, posts: [CalendarPost] = []) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.posts = posts
    }

    public var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }

    public static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}

public struct CalendarWeek: Identifiable {
    public let id = UUID()
    public var days: [CalendarDay]

    public init(days: [CalendarDay]) {
        self.days = days
    }
}
