// AuthManager.swift
// VibeCreatorKit - Authentication and session management

import Foundation
import KeychainAccess

/// Manages authentication state and secure credential storage
public class AuthManager: ObservableObject {
    public static let shared = AuthManager()

    private let keychain = Keychain(service: "com.vibecreator.app")

    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let csrfTokenKey = "csrf_token"
    private let userIdKey = "user_id"
    private let userDataKey = "user_data"

    @Published public var isAuthenticated = false
    @Published public var currentUser: User?

    public var accessToken: String? {
        get { try? keychain.get(accessTokenKey) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: accessTokenKey)
            } else {
                try? keychain.remove(accessTokenKey)
            }
        }
    }

    public var refreshToken: String? {
        get { try? keychain.get(refreshTokenKey) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: refreshTokenKey)
            } else {
                try? keychain.remove(refreshTokenKey)
            }
        }
    }

    public var csrfToken: String? {
        get { try? keychain.get(csrfTokenKey) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: csrfTokenKey)
            } else {
                try? keychain.remove(csrfTokenKey)
            }
        }
    }

    private init() {
        checkAuthState()
    }

    /// Check if user is authenticated on app launch
    public func checkAuthState() {
        if let token = accessToken, !token.isEmpty {
            isAuthenticated = true
            loadStoredUser()
        }
    }

    /// Save authentication response
    public func saveAuthResponse(_ response: AuthResponse) {
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        csrfToken = response.csrfToken

        if let user = response.user {
            saveUser(user)
        }

        isAuthenticated = true
    }

    /// Save user data
    public func saveUser(_ user: User) {
        currentUser = user

        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDataKey)
        }
    }

    /// Load stored user data
    private func loadStoredUser() {
        if let data = UserDefaults.standard.data(forKey: userDataKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }

    /// Clear all session data
    public func clearSession() {
        accessToken = nil
        refreshToken = nil
        csrfToken = nil
        currentUser = nil
        isAuthenticated = false

        UserDefaults.standard.removeObject(forKey: userDataKey)
    }

    /// Refresh the access token
    public func refreshAccessToken() async throws {
        guard let _ = refreshToken else {
            throw APIError.unauthorized
        }

        let response = try await APIClient.shared.refreshToken()
        saveAuthResponse(response)
    }
}

// MARK: - Auth Response

public struct AuthResponse: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let csrfToken: String?
    public let user: User?
    public let tokenType: String?
    public let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case csrfToken = "csrf_token"
        case user
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - OAuth URL Response

public struct OAuthURLResponse: Codable {
    public let url: String
    public let state: String?
}
