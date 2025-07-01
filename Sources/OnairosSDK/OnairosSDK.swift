import UIKit
import Foundation

/// Main SDK interface for Onairos onboarding
@MainActor
public class OnairosSDK {
    
    /// Shared instance of the SDK
    public static let shared = OnairosSDK()
    
    /// Current configuration
    private var config: OnairosConfig?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Initialize the SDK with configuration
    /// - Parameter config: SDK configuration
    public func initialize(config: OnairosConfig) {
        self.config = config
        
        // Initialize platform authentication managers
        if config.platforms.contains(.instagram) {
            // Initialize Opacity SDK when available
            // InstagramAuthManager.shared.initialize(apiKey: config.opacityAPIKey)
        }
        
        if config.platforms.contains(.youtube) {
            // Google Sign-In will be configured in AppDelegate
        }
    }
    
    /// Present the onboarding modal
    /// - Parameters:
    ///   - presentingViewController: The view controller to present from
    ///   - completion: Completion handler with onboarding result
    public func presentOnboarding(
        from presentingViewController: UIViewController,
        completion: @escaping OnboardingCompletion
    ) {
        guard let config = config else {
            let error = OnairosError.notInitialized
            completion(.failure(error))
            return
        }
        
        let onboardingCoordinator = OnboardingCoordinator(config: config)
        onboardingCoordinator.start(
            from: presentingViewController,
            completion: completion
        )
    }
    
    /// Check if user has existing session
    /// - Returns: True if user has saved session
    public func hasExistingSession() -> Bool {
        return UserDefaults.standard.bool(forKey: "onairos_session_saved")
    }
    
    /// Clear saved session
    public func clearSession() {
        UserDefaults.standard.removeObject(forKey: "onairos_session_saved")
        UserDefaults.standard.removeObject(forKey: "onairos_user_data")
        UserDefaults.standard.removeObject(forKey: "onairos_connected_platforms")
    }
}

/// SDK Configuration
public struct OnairosConfig {
    /// Debug mode enables testing features
    public let isDebugMode: Bool
    
    /// Allow proceeding without platform connections
    public let allowEmptyConnections: Bool
    
    /// Simulate training progress for testing
    public let simulateTraining: Bool
    
    /// API base URL
    public let apiBaseURL: String
    
    /// Platforms to enable
    public let platforms: Set<Platform>
    
    /// Opacity API key for Instagram authentication
    public let opacityAPIKey: String?
    
    /// Google client ID for YouTube authentication
    public let googleClientID: String?
    
    /// Custom URL scheme for OAuth callbacks
    public let urlScheme: String
    
    /// App name to display in UI
    public let appName: String
    
    public init(
        isDebugMode: Bool = false,
        allowEmptyConnections: Bool = false,
        simulateTraining: Bool = false,
        apiBaseURL: String = "https://api2.onairos.uk",
        platforms: Set<Platform> = [.instagram, .youtube, .reddit, .pinterest, .gmail],
        opacityAPIKey: String? = nil,
        googleClientID: String? = nil,
        urlScheme: String,
        appName: String
    ) {
        self.isDebugMode = isDebugMode
        self.allowEmptyConnections = allowEmptyConnections
        self.simulateTraining = simulateTraining
        self.apiBaseURL = apiBaseURL
        self.platforms = platforms
        self.opacityAPIKey = opacityAPIKey
        self.googleClientID = googleClientID
        self.urlScheme = urlScheme
        self.appName = appName
    }
}

/// Onboarding completion result
public enum OnboardingResult {
    case success(OnboardingData)
    case failure(OnairosError)
}

/// Completion handler type
public typealias OnboardingCompletion = (OnboardingResult) -> Void

/// Successful onboarding data
public struct OnboardingData {
    public let apiURL: String
    public let token: String
    public let userData: [String: Any]
    public let connectedPlatforms: [String: PlatformData]
    public let sessionSaved: Bool
    public let inferenceData: [String: Any]?
    public let partner: String?
}

/// Platform authentication data
public struct PlatformData {
    public let platform: String
    public let accessToken: String?
    public let refreshToken: String?
    public let expiresAt: Date?
    public let userData: [String: Any]?
} 