// System.swift
// VibeCreatorKit - System status models

import Foundation

/// System status response
public struct SystemStatus: Codable {
    public let environment: EnvironmentInfo
    public let health: HealthChecks
    public let technical: TechnicalInfo?

    enum CodingKeys: String, CodingKey {
        case environment
        case health
        case technical
    }
}

/// Environment information
public struct EnvironmentInfo: Codable {
    public let appName: String?
    public let appVersion: String?
    public let phpVersion: String?
    public let laravelVersion: String?
    public let environment: String?
    public let debug: Bool?
    public let url: String?

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case appVersion = "app_version"
        case phpVersion = "php_version"
        case laravelVersion = "laravel_version"
        case environment
        case debug
        case url
    }
}

/// Health check results
public struct HealthChecks: Codable {
    public let horizon: HealthStatus?
    public let queue: HealthStatus?
    public let scheduler: HealthStatus?
    public let redis: HealthStatus?
    public let database: HealthStatus?

    enum CodingKeys: String, CodingKey {
        case horizon
        case queue
        case scheduler
        case redis
        case database
    }
}

/// Individual health status
public struct HealthStatus: Codable {
    public let status: String
    public let message: String?

    public var isHealthy: Bool {
        status.lowercased() == "ok" || status.lowercased() == "running" || status.lowercased() == "healthy"
    }

    public var statusColor: String {
        isHealthy ? "green" : "red"
    }
}

/// Technical information
public struct TechnicalInfo: Codable {
    public let ffmpegPath: String?
    public let ffprobePath: String?
    public let ffmpegVersion: String?
    public let diskUsage: DiskUsage?

    enum CodingKeys: String, CodingKey {
        case ffmpegPath = "ffmpeg_path"
        case ffprobePath = "ffprobe_path"
        case ffmpegVersion = "ffmpeg_version"
        case diskUsage = "disk_usage"
    }
}

/// Disk usage information
public struct DiskUsage: Codable {
    public let total: String?
    public let used: String?
    public let free: String?
    public let percentage: Int?

    public var usagePercentage: Double {
        Double(percentage ?? 0) / 100.0
    }
}
