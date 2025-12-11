// Dashboard.swift
// VibeCreatorKit - Dashboard and analytics models

import Foundation

/// Dashboard response model
public struct DashboardResponse: Codable {
    public let accounts: [Account]
    public let recentPosts: [Post]?
    public let scheduledCount: Int?
    public let publishedCount: Int?
    public let failedCount: Int?

    enum CodingKeys: String, CodingKey {
        case accounts
        case recentPosts = "recent_posts"
        case scheduledCount = "scheduled_count"
        case publishedCount = "published_count"
        case failedCount = "failed_count"
    }
}

/// Report response model
public struct ReportResponse: Codable {
    public let account: Account?
    public let metrics: [Metric]?
    public let summary: ReportSummary?
    public let audience: AudienceData?

    enum CodingKeys: String, CodingKey {
        case account
        case metrics
        case summary
        case audience
    }
}

/// Metric data point
public struct Metric: Codable, Identifiable {
    public let id: Int?
    public let accountId: Int
    public let date: String
    public let data: MetricData?

    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case date
        case data
    }

    public var identifier: String {
        if let id = id {
            return String(id)
        }
        return "\(accountId)-\(date)"
    }
}

/// Metric data details
public struct MetricData: Codable {
    public let followers: Int?
    public let following: Int?
    public let posts: Int?
    public let impressions: Int?
    public let reach: Int?
    public let engagement: Int?
    public let likes: Int?
    public let comments: Int?
    public let shares: Int?
    public let clicks: Int?
    public let profileViews: Int?

    enum CodingKeys: String, CodingKey {
        case followers
        case following
        case posts
        case impressions
        case reach
        case engagement
        case likes
        case comments
        case shares
        case clicks
        case profileViews = "profile_views"
    }
}

/// Report summary
public struct ReportSummary: Codable {
    public let totalPosts: Int?
    public let totalImpressions: Int?
    public let totalReach: Int?
    public let totalEngagement: Int?
    public let averageEngagement: Double?
    public let followerGrowth: Int?
    public let followerGrowthPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case totalPosts = "total_posts"
        case totalImpressions = "total_impressions"
        case totalReach = "total_reach"
        case totalEngagement = "total_engagement"
        case averageEngagement = "average_engagement"
        case followerGrowth = "follower_growth"
        case followerGrowthPercentage = "follower_growth_percentage"
    }
}

/// Audience data
public struct AudienceData: Codable {
    public let current: Int?
    public let previous: Int?
    public let change: Int?
    public let changePercentage: Double?
    public let history: [AudienceHistoryPoint]?

    enum CodingKeys: String, CodingKey {
        case current
        case previous
        case change
        case changePercentage = "change_percentage"
        case history
    }
}

/// Audience history data point
public struct AudienceHistoryPoint: Codable, Identifiable {
    public let date: String
    public let count: Int

    public var id: String { date }
}
