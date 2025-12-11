// CalendarView.swift
// VibeCreator - Calendar view for post scheduling

import SwiftUI
import VibeCreatorKit

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedPost: CalendarPost?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar toolbar
                calendarToolbar

                // Calendar content
                if viewModel.viewType == .month {
                    monthView
                } else {
                    weekView
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showNewPost = true }) {
                        Label("New Post", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    CalendarPostDetailView(post: post)
                }
            }
            .task {
                await viewModel.loadCalendar()
            }
        }
    }

    // MARK: - Calendar Toolbar

    private var calendarToolbar: some View {
        VStack(spacing: 12) {
            // Month/Week toggle and navigation
            HStack {
                Button(action: viewModel.previousPeriod) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(viewModel.currentPeriodTitle)
                    .font(.headline)

                Spacer()

                Button(action: viewModel.nextPeriod) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // View type toggle
            HStack {
                Picker("View", selection: $viewModel.viewType) {
                    Text("Month").tag(CalendarViewType.month)
                    Text("Week").tag(CalendarViewType.week)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                Button("Today") {
                    viewModel.goToToday()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Divider()
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Color(.secondarySystemBackground))

            Divider()

            // Calendar grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                    ForEach(viewModel.calendarDays) { day in
                        CalendarDayCell(day: day) { post in
                            selectedPost = post
                        }
                    }
                }
                .background(Color(.separator))
            }
        }
    }

    // MARK: - Week View

    private var weekView: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(viewModel.calendarDays) { day in
                    CalendarWeekDayRow(day: day) { post in
                        selectedPost = post
                    }
                }
            }
            .background(Color(.separator))
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: CalendarDay
    let onSelectPost: (CalendarPost) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day number
            HStack {
                Text("\(day.dayNumber)")
                    .font(.subheadline)
                    .fontWeight(day.isToday ? .bold : .regular)
                    .foregroundStyle(day.isCurrentMonth ? (day.isToday ? .white : .primary) : .secondary)
                    .frame(width: 28, height: 28)
                    .background(day.isToday ? Color.accentColor : Color.clear)
                    .clipShape(Circle())

                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)

            // Posts
            VStack(spacing: 2) {
                ForEach(day.posts.prefix(3)) { post in
                    CalendarPostPill(post: post)
                        .onTapGesture {
                            onSelectPost(post)
                        }
                }

                if day.posts.count > 3 {
                    Text("+\(day.posts.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 100)
        .background(Color(.systemBackground))
    }
}

// MARK: - Calendar Post Pill

struct CalendarPostPill: View {
    let post: CalendarPost

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(post.content ?? "Post")
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.horizontal, 2)
    }

    private var statusColor: Color {
        switch post.status {
        case .draft: return .gray
        case .scheduled: return .blue
        case .published: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Calendar Week Day Row

struct CalendarWeekDayRow: View {
    let day: CalendarDay
    let onSelectPost: (CalendarPost) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                VStack(alignment: .leading) {
                    Text(day.date.dayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(day.date.formatted(style: .medium))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if day.isToday {
                    Text("Today")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            // Posts for the day
            if day.posts.isEmpty {
                Text("No posts scheduled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(day.posts) { post in
                    CalendarWeekPostRow(post: post)
                        .onTapGesture {
                            onSelectPost(post)
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Calendar Week Post Row

struct CalendarWeekPostRow: View {
    let post: CalendarPost

    var body: some View {
        HStack(spacing: 12) {
            // Time
            if let time = post.scheduledAt {
                Text(time.timeString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
            }

            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.content ?? "Post")
                    .font(.subheadline)
                    .lineLimit(2)

                // Account indicators
                if let accounts = post.accounts, !accounts.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(accounts) { account in
                            Image(systemName: account.provider.iconName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Status badge
            Text(post.status.displayName)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        switch post.status {
        case .draft: return .gray
        case .scheduled: return .blue
        case .published: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Calendar Post Detail View

struct CalendarPostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let post: CalendarPost

    var body: some View {
        List {
            Section("Status") {
                StatusBadge(status: post.status)
            }

            Section("Content") {
                Text(post.content ?? "No content")
            }

            if let date = post.scheduledAt ?? post.publishedAt {
                Section("Time") {
                    Label(date.formattedDateTime(), systemImage: "clock")
                }
            }

            if let accounts = post.accounts, !accounts.isEmpty {
                Section("Accounts") {
                    ForEach(accounts) { account in
                        HStack {
                            Image(systemName: account.provider.iconName)
                            Text(account.name)
                        }
                    }
                }
            }

            if let tags = post.tags, !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags) { tag in
                        HStack {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Post Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Calendar View Model

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var viewType: CalendarViewType = .month
    @Published var calendarDays: [CalendarDay] = []
    @Published var posts: [CalendarPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var weekdaySymbols: [String] {
        Calendar.current.shortWeekdaySymbols
    }

    var currentPeriodTitle: String {
        let formatter = DateFormatter()
        if viewType == .month {
            formatter.dateFormat = "MMMM yyyy"
        } else {
            formatter.dateFormat = "'Week of' MMM d, yyyy"
        }
        return formatter.string(from: currentDate)
    }

    func loadCalendar() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.getCalendar(date: currentDate, type: viewType)
            posts = response.posts
            generateCalendarDays()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previousPeriod() {
        if viewType == .month {
            currentDate = currentDate.addingMonths(-1)
        } else {
            currentDate = currentDate.addingDays(-7)
        }
        Task { await loadCalendar() }
    }

    func nextPeriod() {
        if viewType == .month {
            currentDate = currentDate.addingMonths(1)
        } else {
            currentDate = currentDate.addingDays(7)
        }
        Task { await loadCalendar() }
    }

    func goToToday() {
        currentDate = Date()
        Task { await loadCalendar() }
    }

    private func generateCalendarDays() {
        var days: [CalendarDay] = []
        let calendar = Calendar.current

        if viewType == .month {
            let startOfMonth = currentDate.startOfMonth
            let startWeekday = calendar.component(.weekday, from: startOfMonth)

            // Days from previous month
            let daysToAdd = startWeekday - calendar.firstWeekday
            let adjustedDays = daysToAdd < 0 ? daysToAdd + 7 : daysToAdd

            for i in (0..<adjustedDays).reversed() {
                let date = calendar.date(byAdding: .day, value: -(i + 1), to: startOfMonth) ?? startOfMonth
                days.append(CalendarDay(date: date, isCurrentMonth: false, isToday: false, posts: postsForDate(date)))
            }

            // Days in current month
            let range = calendar.range(of: .day, in: .month, for: currentDate) ?? 1..<31
            for day in range {
                if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                    let isToday = calendar.isDateInToday(date)
                    days.append(CalendarDay(date: date, isCurrentMonth: true, isToday: isToday, posts: postsForDate(date)))
                }
            }

            // Fill remaining cells to make 6 weeks
            let remaining = 42 - days.count
            if remaining > 0 {
                let endOfMonth = currentDate.endOfMonth
                for i in 1...remaining {
                    if let date = calendar.date(byAdding: .day, value: i, to: endOfMonth) {
                        days.append(CalendarDay(date: date, isCurrentMonth: false, isToday: false, posts: postsForDate(date)))
                    }
                }
            }
        } else {
            // Week view
            let startOfWeek = currentDate.startOfWeek()
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? currentDate
                let isToday = calendar.isDateInToday(date)
                days.append(CalendarDay(date: date, isCurrentMonth: true, isToday: isToday, posts: postsForDate(date)))
            }
        }

        calendarDays = days
    }

    private func postsForDate(_ date: Date) -> [CalendarPost] {
        let calendar = Calendar.current
        return posts.filter { post in
            guard let postDate = post.effectiveDate else { return false }
            return calendar.isDate(postDate, inSameDayAs: date)
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(AppState.shared)
}
