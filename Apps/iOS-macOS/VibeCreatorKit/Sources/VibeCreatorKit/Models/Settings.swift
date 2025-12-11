// Settings.swift
// VibeCreatorKit - App settings models

import Foundation

/// App settings model
public struct AppSettings: Codable {
    public var timezone: String
    public var timeFormat: Int
    public var weekStartsOn: Int
    public var adminEmail: String?

    enum CodingKeys: String, CodingKey {
        case timezone
        case timeFormat = "time_format"
        case weekStartsOn = "week_starts_on"
        case adminEmail = "admin_email"
    }

    public init(timezone: String = "UTC", timeFormat: Int = 24, weekStartsOn: Int = 1, adminEmail: String? = nil) {
        self.timezone = timezone
        self.timeFormat = timeFormat
        self.weekStartsOn = weekStartsOn
        self.adminEmail = adminEmail
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timezone": timezone,
            "time_format": timeFormat,
            "week_starts_on": weekStartsOn
        ]

        if let adminEmail = adminEmail {
            dict["admin_email"] = adminEmail
        }

        return dict
    }

    /// Time format display string
    public var timeFormatDisplay: String {
        timeFormat == 12 ? "12-hour" : "24-hour"
    }

    /// Week start day display string
    public var weekStartDisplay: String {
        weekStartsOn == 0 ? "Sunday" : "Monday"
    }
}

/// Available timezones
public struct TimezoneList {
    public static let timezones: [String] = [
        "UTC",
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "America/Anchorage",
        "America/Honolulu",
        "America/Toronto",
        "America/Vancouver",
        "America/Mexico_City",
        "America/Sao_Paulo",
        "America/Buenos_Aires",
        "Europe/London",
        "Europe/Paris",
        "Europe/Berlin",
        "Europe/Rome",
        "Europe/Madrid",
        "Europe/Amsterdam",
        "Europe/Brussels",
        "Europe/Stockholm",
        "Europe/Oslo",
        "Europe/Copenhagen",
        "Europe/Helsinki",
        "Europe/Warsaw",
        "Europe/Prague",
        "Europe/Vienna",
        "Europe/Zurich",
        "Europe/Moscow",
        "Europe/Istanbul",
        "Asia/Dubai",
        "Asia/Kolkata",
        "Asia/Bangkok",
        "Asia/Singapore",
        "Asia/Hong_Kong",
        "Asia/Shanghai",
        "Asia/Seoul",
        "Asia/Tokyo",
        "Australia/Sydney",
        "Australia/Melbourne",
        "Australia/Perth",
        "Pacific/Auckland",
        "Pacific/Fiji"
    ]
}

/// Service configuration model
public struct Service: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let group: ServiceGroup
    public let active: Bool
    public let configuration: [String: String]?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case group
        case active
        case configuration
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Service group enum
public enum ServiceGroup: String, Codable {
    case social = "social"
    case media = "media"
    case miscellaneous = "miscellaneous"

    public var displayName: String {
        switch self {
        case .social: return "Social Networks"
        case .media: return "Media Services"
        case .miscellaneous: return "Miscellaneous"
        }
    }
}
