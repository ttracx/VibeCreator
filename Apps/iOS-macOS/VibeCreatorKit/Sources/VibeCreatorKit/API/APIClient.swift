// APIClient.swift
// VibeCreatorKit - Core networking layer for VibeCreator

import Foundation
import Alamofire

/// Main API client for VibeCreator backend communication
public class APIClient: ObservableObject {
    public static let shared = APIClient()

    private var session: Session
    private var baseURL: String { APIConfiguration.shared.baseURL }

    @Published public var isAuthenticated = false

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest"
        ]

        self.session = Session(configuration: configuration)
    }

    // MARK: - Authentication

    /// Login with email and password
    public func login(email: String, password: String) async throws -> AuthResponse {
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]

        return try await request(.post, endpoint: "/api/mobile/login", parameters: parameters)
    }

    /// Register a new user
    public func register(name: String, email: String, password: String, passwordConfirmation: String) async throws -> AuthResponse {
        let parameters: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "password_confirmation": passwordConfirmation
        ]

        return try await request(.post, endpoint: "/api/mobile/register", parameters: parameters)
    }

    /// Logout the current user
    public func logout() async throws {
        let _: EmptyResponse = try await request(.post, endpoint: "/api/mobile/logout")
        await MainActor.run {
            self.isAuthenticated = false
            AuthManager.shared.clearSession()
        }
    }

    /// Refresh authentication token
    public func refreshToken() async throws -> AuthResponse {
        return try await request(.post, endpoint: "/api/mobile/refresh")
    }

    // MARK: - Dashboard

    /// Get dashboard data with analytics
    public func getDashboard() async throws -> DashboardResponse {
        return try await request(.get, endpoint: "/api/mobile/dashboard")
    }

    /// Get reports for a specific account
    public func getReports(accountId: Int, period: Int = 30) async throws -> ReportResponse {
        let parameters: [String: Any] = [
            "account_id": accountId,
            "period": period
        ]
        return try await request(.get, endpoint: "/api/mobile/reports", parameters: parameters)
    }

    // MARK: - Posts

    /// Get paginated list of posts
    public func getPosts(page: Int = 1, status: PostStatus? = nil, tagId: Int? = nil, accountId: Int? = nil, keyword: String? = nil) async throws -> PostsResponse {
        var parameters: [String: Any] = ["page": page]
        if let status = status { parameters["status"] = status.rawValue }
        if let tagId = tagId { parameters["tag_id"] = tagId }
        if let accountId = accountId { parameters["account_id"] = accountId }
        if let keyword = keyword { parameters["keyword"] = keyword }

        return try await request(.get, endpoint: "/api/mobile/posts", parameters: parameters)
    }

    /// Get a single post
    public func getPost(id: Int) async throws -> Post {
        return try await request(.get, endpoint: "/api/mobile/posts/\(id)")
    }

    /// Create a new post
    public func createPost(post: CreatePostRequest) async throws -> Post {
        return try await request(.post, endpoint: "/api/mobile/posts", parameters: post.toDictionary())
    }

    /// Update an existing post
    public func updatePost(id: Int, post: CreatePostRequest) async throws -> Post {
        return try await request(.put, endpoint: "/api/mobile/posts/\(id)", parameters: post.toDictionary())
    }

    /// Delete a post
    public func deletePost(id: Int) async throws {
        let _: EmptyResponse = try await request(.delete, endpoint: "/api/mobile/posts/\(id)")
    }

    /// Delete multiple posts
    public func deletePosts(ids: [Int]) async throws {
        let parameters: [String: Any] = ["posts": ids]
        let _: EmptyResponse = try await request(.delete, endpoint: "/api/mobile/posts", parameters: parameters)
    }

    /// Schedule a post
    public func schedulePost(id: Int, scheduledAt: Date) async throws -> Post {
        let formatter = ISO8601DateFormatter()
        let parameters: [String: Any] = [
            "scheduled_at": formatter.string(from: scheduledAt)
        ]
        return try await request(.post, endpoint: "/api/mobile/posts/\(id)/schedule", parameters: parameters)
    }

    /// Duplicate a post
    public func duplicatePost(id: Int) async throws -> Post {
        return try await request(.post, endpoint: "/api/mobile/posts/\(id)/duplicate")
    }

    // MARK: - Calendar

    /// Get calendar data
    public func getCalendar(date: Date, type: CalendarViewType = .month, accountId: Int? = nil, tagId: Int? = nil) async throws -> CalendarResponse {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var parameters: [String: Any] = [
            "date": formatter.string(from: date),
            "type": type.rawValue
        ]
        if let accountId = accountId { parameters["account_id"] = accountId }
        if let tagId = tagId { parameters["tag_id"] = tagId }

        return try await request(.get, endpoint: "/api/mobile/calendar", parameters: parameters)
    }

    // MARK: - Accounts

    /// Get all connected social accounts
    public func getAccounts() async throws -> [Account] {
        return try await request(.get, endpoint: "/api/mobile/accounts")
    }

    /// Update/refresh an account
    public func updateAccount(id: Int) async throws -> Account {
        return try await request(.put, endpoint: "/api/mobile/accounts/\(id)")
    }

    /// Delete an account
    public func deleteAccount(id: Int) async throws {
        let _: EmptyResponse = try await request(.delete, endpoint: "/api/mobile/accounts/\(id)")
    }

    /// Get OAuth URL for adding a new account
    public func getOAuthURL(provider: String) async throws -> OAuthURLResponse {
        return try await request(.get, endpoint: "/api/mobile/accounts/add/\(provider)")
    }

    /// Get account entities (Facebook pages, groups)
    public func getAccountEntities(provider: String) async throws -> [AccountEntity] {
        return try await request(.get, endpoint: "/api/mobile/accounts/entities/\(provider)")
    }

    /// Store selected account entities
    public func storeAccountEntities(provider: String, entities: [String]) async throws -> [Account] {
        let parameters: [String: Any] = ["entities": entities]
        return try await request(.post, endpoint: "/api/mobile/accounts/entities/\(provider)", parameters: parameters)
    }

    // MARK: - Media

    /// Get uploaded media (paginated)
    public func getMedia(page: Int = 1) async throws -> MediaResponse {
        let parameters: [String: Any] = ["page": page]
        return try await request(.get, endpoint: "/api/mobile/media/uploads", parameters: parameters)
    }

    /// Search stock photos (Unsplash)
    public func searchStockPhotos(query: String, page: Int = 1) async throws -> StockMediaResponse {
        let parameters: [String: Any] = [
            "keyword": query,
            "page": page
        ]
        return try await request(.get, endpoint: "/api/mobile/media/stock", parameters: parameters)
    }

    /// Search GIFs (Tenor)
    public func searchGifs(query: String, page: Int = 1) async throws -> GifMediaResponse {
        let parameters: [String: Any] = [
            "keyword": query,
            "page": page
        ]
        return try await request(.get, endpoint: "/api/mobile/media/gifs", parameters: parameters)
    }

    /// Upload media file
    public func uploadMedia(data: Data, filename: String, mimeType: String) async throws -> Media {
        let url = "\(baseURL)/api/mobile/media/upload"

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(data, withName: "file", fileName: filename, mimeType: mimeType)
            }, to: url, headers: self.authHeaders())
            .validate()
            .responseDecodable(of: Media.self) { response in
                switch response.result {
                case .success(let media):
                    continuation.resume(returning: media)
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error, response: response.response))
                }
            }
        }
    }

    /// Download external media to library
    public func downloadExternalMedia(url: String) async throws -> Media {
        let parameters: [String: Any] = ["url": url]
        return try await request(.post, endpoint: "/api/mobile/media/download", parameters: parameters)
    }

    /// Delete media
    public func deleteMedia(ids: [Int]) async throws {
        let parameters: [String: Any] = ["media": ids]
        let _: EmptyResponse = try await request(.delete, endpoint: "/api/mobile/media", parameters: parameters)
    }

    // MARK: - Tags

    /// Get all tags
    public func getTags() async throws -> [Tag] {
        return try await request(.get, endpoint: "/api/mobile/tags")
    }

    /// Create a tag
    public func createTag(name: String, color: String) async throws -> Tag {
        let parameters: [String: Any] = [
            "name": name,
            "hex_color": color
        ]
        return try await request(.post, endpoint: "/api/mobile/tags", parameters: parameters)
    }

    /// Update a tag
    public func updateTag(id: Int, name: String, color: String) async throws -> Tag {
        let parameters: [String: Any] = [
            "name": name,
            "hex_color": color
        ]
        return try await request(.put, endpoint: "/api/mobile/tags/\(id)", parameters: parameters)
    }

    /// Delete a tag
    public func deleteTag(id: Int) async throws {
        let _: EmptyResponse = try await request(.delete, endpoint: "/api/mobile/tags/\(id)")
    }

    // MARK: - Settings

    /// Get app settings
    public func getSettings() async throws -> AppSettings {
        return try await request(.get, endpoint: "/api/mobile/settings")
    }

    /// Update settings
    public func updateSettings(settings: AppSettings) async throws -> AppSettings {
        return try await request(.put, endpoint: "/api/mobile/settings", parameters: settings.toDictionary())
    }

    // MARK: - Profile

    /// Get current user profile
    public func getProfile() async throws -> User {
        return try await request(.get, endpoint: "/api/mobile/profile")
    }

    /// Update user profile
    public func updateProfile(name: String, email: String) async throws -> User {
        let parameters: [String: Any] = [
            "name": name,
            "email": email
        ]
        return try await request(.put, endpoint: "/api/mobile/profile", parameters: parameters)
    }

    /// Update password
    public func updatePassword(currentPassword: String, newPassword: String, confirmPassword: String) async throws {
        let parameters: [String: Any] = [
            "current_password": currentPassword,
            "password": newPassword,
            "password_confirmation": confirmPassword
        ]
        let _: EmptyResponse = try await request(.put, endpoint: "/api/mobile/profile/password", parameters: parameters)
    }

    // MARK: - Services

    /// Get configured services
    public func getServices() async throws -> [Service] {
        return try await request(.get, endpoint: "/api/mobile/services")
    }

    // MARK: - System

    /// Get system status
    public func getSystemStatus() async throws -> SystemStatus {
        return try await request(.get, endpoint: "/api/mobile/system/status")
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(_ method: HTTPMethod, endpoint: String, parameters: [String: Any]? = nil) async throws -> T {
        let url = "\(baseURL)\(endpoint)"

        let encoding: ParameterEncoding = method == .get ? URLEncoding.default : JSONEncoding.default

        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, parameters: parameters, encoding: encoding, headers: authHeaders())
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: self.mapError(error, response: response.response))
                    }
                }
        }
    }

    private func authHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest"
        ]

        if let token = AuthManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        if let csrfToken = AuthManager.shared.csrfToken {
            headers["X-CSRF-TOKEN"] = csrfToken
        }

        return headers
    }

    private func mapError(_ error: AFError, response: HTTPURLResponse?) -> APIError {
        switch response?.statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 422:
            return .validationError("Validation failed")
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError
        default:
            return .networkError(error.localizedDescription)
        }
    }
}

// MARK: - API Error

public enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case validationError(String)
    case rateLimited
    case serverError
    case networkError(String)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .validationError(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError:
            return "A server error occurred. Please try again later."
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to process response: \(message)"
        }
    }
}

// MARK: - Empty Response

struct EmptyResponse: Decodable {}

// MARK: - Calendar View Type

public enum CalendarViewType: String {
    case month = "month"
    case week = "week"
}
