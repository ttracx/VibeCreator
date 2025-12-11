// User.swift
// VibeCreatorKit - User model

import Foundation

/// User model representing authenticated users
public struct User: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let email: String
    public let emailVerifiedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: Int, name: String, email: String, emailVerifiedAt: Date? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.emailVerifiedAt = emailVerifiedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)

        // Handle date parsing
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .emailVerifiedAt) {
            emailVerifiedAt = dateFormatter.date(from: dateString)
        } else {
            emailVerifiedAt = nil
        }

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: dateString)
        } else {
            createdAt = nil
        }

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: dateString)
        } else {
            updatedAt = nil
        }
    }
}
