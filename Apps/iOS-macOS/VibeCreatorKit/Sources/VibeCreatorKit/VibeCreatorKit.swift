// VibeCreatorKit - Shared Framework for iOS and macOS
// This framework provides core functionality for the VibeCreator app

import Foundation

/// VibeCreatorKit version information
public struct VibeCreatorKit {
    public static let version = "1.0.0"
    public static let buildNumber = "1"

    /// Initialize the kit with the API base URL
    public static func configure(baseURL: String, apiKey: String? = nil) {
        APIConfiguration.shared.baseURL = baseURL
        if let apiKey = apiKey {
            APIConfiguration.shared.apiKey = apiKey
        }
    }
}

/// Global API Configuration
public class APIConfiguration: ObservableObject {
    public static let shared = APIConfiguration()

    @Published public var baseURL: String = ""
    @Published public var apiKey: String = ""
    @Published public var isConfigured: Bool = false

    private init() {}

    public func validate() -> Bool {
        guard !baseURL.isEmpty else { return false }
        isConfigured = true
        return true
    }
}
