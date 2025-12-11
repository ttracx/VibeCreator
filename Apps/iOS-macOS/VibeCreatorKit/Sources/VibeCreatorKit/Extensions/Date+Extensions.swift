// Date+Extensions.swift
// VibeCreatorKit - Date formatting extensions

import Foundation

public extension Date {
    /// Format date for display
    func formatted(style: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    /// Format date and time
    func formattedDateTime(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    /// Format for API request
    var apiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// Format for API request with time
    var apiDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }

    /// ISO8601 string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    /// Time string only
    func timeString(format: Int = 24) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format == 12 ? "h:mm a" : "HH:mm"
        return formatter.string(from: self)
    }

    /// Relative time (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Check if date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Start of month
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// End of month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Start of week
    func startOfWeek(startingOn: Int = 1) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = startingOn + 1 // Calendar uses 1-based indexing (1 = Sunday)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Add days
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add months
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Get day component
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Get month component
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Get year component
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Get weekday component (1 = Sunday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Month name
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    /// Short month name
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    /// Day name
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// Short day name
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}

// MARK: - Date Parsing

public extension Date {
    /// Parse from API date string
    init?(apiString: String) {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: apiString) {
                self = date
                return
            }
        }

        // Try ISO8601
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: apiString) {
            self = date
            return
        }

        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: apiString) {
            self = date
            return
        }

        return nil
    }
}
