// Tag.swift
// VibeCreatorKit - Tag models

import Foundation
import SwiftUI

/// Tag model for organizing posts
public struct Tag: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let hexColor: String
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hexColor = "hex_color"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: Int, name: String, hexColor: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.hexColor = hexColor
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convert hex color to SwiftUI Color
    public var color: Color {
        Color(hex: hexColor)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        NativeColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
        NativeColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

// MARK: - Predefined Colors

public extension Tag {
    static let predefinedColors: [String] = [
        "#F44336", // Red
        "#E91E63", // Pink
        "#9C27B0", // Purple
        "#673AB7", // Deep Purple
        "#3F51B5", // Indigo
        "#2196F3", // Blue
        "#03A9F4", // Light Blue
        "#00BCD4", // Cyan
        "#009688", // Teal
        "#4CAF50", // Green
        "#8BC34A", // Light Green
        "#CDDC39", // Lime
        "#FFEB3B", // Yellow
        "#FFC107", // Amber
        "#FF9800", // Orange
        "#FF5722", // Deep Orange
        "#795548", // Brown
        "#9E9E9E", // Grey
        "#607D8B"  // Blue Grey
    ]
}
