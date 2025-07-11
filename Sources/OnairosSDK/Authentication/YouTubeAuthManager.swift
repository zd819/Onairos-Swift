import Foundation
import GoogleSignIn
import UIKit

/// YouTube configuration validation result
public enum YouTubeConfigurationResult {
    case configured
    case notInitialized
    case notConfigured
    case missingURLScheme(String)
    
    /// User-friendly description of the configuration status
    public var description: String {
        switch self {
        case .configured:
            return "YouTube authentication is properly configured"
        case .notInitialized:
            return "YouTube authentication not initialized. Call YouTubeAuthManager.shared.initialize() in your AppDelegate."
        case .notConfigured:
            return "Google Sign-In configuration is missing"
        case .missingURLScheme(let scheme):
            return "Missing required URL scheme in Info.plist: \(scheme)"
        }
    }
    
    /// Whether the configuration is ready for use
    public var isReady: Bool {
        switch self {
        case .configured:
            return true
        default:
            return false
        }
    }
}

/// YouTube authentication manager using Google Sign-In SDK
public class YouTubeAuthManager {
    
    /// Shared instance
    public static let shared = YouTubeAuthManager()
    
    /// Configuration constants
    private struct Config {
        static let scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
        static let offlineAccess = true
        static let forceCodeForRefreshToken = true
        
        // Admin/Testing mode client ID (hardcoded for internal testing)
        static let adminClientID = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
    }
    
    /// Google client ID (provided by consuming app or admin default)
    private var clientID: String?
    
    /// Initialization status
    private var isInitialized = false
    
    /// Private initializer
    private init() {}
    
    /// Initialize Google Sign-In for admin/testing mode (uses hardcoded client ID)
    /// This method is for internal testing and admin usage only
    public func initialize() {
        self.clientID = Config.adminClientID
        
        // Configure Google Sign-In with the admin client ID
        let configuration = GIDConfiguration(clientID: Config.adminClientID)
        
        GIDSignIn.sharedInstance.configuration = configuration
        isInitialized = true
        
        // Log configuration status for debugging
        print("🔍 [YouTubeAuth] Initialized in ADMIN/TESTING mode")
        print("🔍 [YouTubeAuth] Using hardcoded client ID: \(Config.adminClientID)")
        
        // Enhanced debugging - show what's actually in Info.plist
        print("🔍 [YouTubeAuth] DEBUGGING - Info.plist URL configuration:")
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            print("   📋 Found CFBundleURLTypes with \(urlTypes.count) entries:")
            for (index, urlType) in urlTypes.enumerated() {
                print("   📋 Entry \(index): \(urlType)")
                if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                    print("   📋 Schemes in entry \(index): \(schemes)")
                    for scheme in schemes {
                        print("   📋 - \(scheme)")
                    }
                }
            }
        } else {
            print("   ❌ No CFBundleURLTypes found in Info.plist!")
        }
        
        if let expectedScheme = getExpectedURLScheme() {
            print("🔍 [YouTubeAuth] Expected URL scheme: \(expectedScheme)")
        }
        
        let configResult = validateConfiguration()
        switch configResult {
        case .configured:
            print("✅ [YouTubeAuth] Configuration is valid and ready")
        case .missingURLScheme(let scheme):
            print("⚠️ [YouTubeAuth] Missing URL scheme: \(scheme)")
            print("   Add this to your Info.plist to enable YouTube authentication:")
            print("   <key>CFBundleURLTypes</key>")
            print("   <array>")
            print("       <dict>")
            print("           <key>CFBundleURLSchemes</key>")
            print("           <array>")
            print("               <string>\(scheme)</string>")
            print("           </array>")
            print("       </dict>")
            print("   </array>")
            print("   See YOUTUBE_INTEGRATION_SETUP.md for complete instructions")
        default:
            print("⚠️ [YouTubeAuth] Configuration issue: \(configResult.description)")
        }
    }
    
    /// Initialize Google Sign-In with consuming app's Google Client ID
    /// - Parameter clientID: Google Client ID from consuming app
    public func initialize(clientID: String) {
        self.clientID = clientID
        
        // Configure Google Sign-In with the provided client ID
        let configuration = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = configuration
        isInitialized = true
        
        // Log configuration status for debugging
        print("🔍 [YouTubeAuth] Initialized with CUSTOM client ID: \(clientID)")
        
        let configResult = validateConfiguration()
        switch configResult {
        case .configured:
            print("✅ [YouTubeAuth] Configuration is valid and ready")
        case .missingURLScheme(let scheme):
            print("⚠️ [YouTubeAuth] Missing URL scheme: \(scheme)")
            print("   Add this to your Info.plist to enable YouTube authentication:")
            print("   <key>CFBundleURLTypes</key>")
            print("   <array>")
            print("       <dict>")
            print("           <key>CFBundleURLSchemes</key>")
            print("           <array>")
            print("               <string>\(scheme)</string>")
            print("           </array>")
            print("       </dict>")
            print("   </array>")
            print("   See YOUTUBE_INTEGRATION_SETUP.md for complete instructions")
        default:
            print("⚠️ [YouTubeAuth] Configuration issue: \(configResult.description)")
        }
    }
    
    /// Initialize Google Sign-In with consuming app's Google Client ID (legacy method)
    /// - Parameters:
    ///   - clientID: Google Client ID from consuming app (required)
    ///   - serverClientID: Server client ID (optional, defaults to nil)
    @available(*, deprecated, message: "Use initialize(clientID:) instead")
    public func initialize(clientID: String, serverClientID: String? = nil) {
        initialize(clientID: clientID)
    }
    
    /// Get the expected URL scheme for the current client ID
    /// - Returns: Expected URL scheme or nil if not initialized
    public func getExpectedURLScheme() -> String? {
        guard let clientID = clientID else { return nil }
        
        // Extract the client ID part (remove .apps.googleusercontent.com if present)
        let cleanClientID = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        
        // Generate the URL scheme: com.googleusercontent.apps.{CLIENT_ID}
        return "com.googleusercontent.apps.\(cleanClientID)"
    }
    
    /// Authenticate with YouTube using enhanced configuration
    /// - Returns: YouTube credentials
    public func authenticate() async throws -> YouTubeCredentials {
        // Validate configuration before attempting authentication
        let configResult = validateConfiguration()
        guard configResult.isReady else {
            print("❌ [YouTubeAuth] Configuration validation failed: \(configResult.description)")
            
            switch configResult {
            case .missingURLScheme(let scheme):
                let detailedMessage = """
                YouTube authentication requires URL scheme configuration.
                
                Add this to your app's Info.plist:
                <key>CFBundleURLTypes</key>
                <array>
                    <dict>
                        <key>CFBundleURLSchemes</key>
                        <array>
                            <string>\(scheme)</string>
                        </array>
                    </dict>
                </array>
                
                See YOUTUBE_INTEGRATION_SETUP.md for complete instructions.
                """
                throw OnairosError.googleSignInFailed(detailedMessage)
            default:
                throw OnairosError.googleSignInFailed(configResult.description)
            }
        }
        
        guard let presentingViewController = await getPresentingViewController() else {
            throw OnairosError.googleSignInFailed("No presenting view controller available")
        }
        
        do {
            print("🔍 [YouTubeAuth] Starting Google Sign-In authentication...")
            
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: nil,
                additionalScopes: Config.scopes
            )
            
            print("✅ [YouTubeAuth] Google Sign-In completed successfully")
            
            let user = result.user
            let accessToken = user.accessToken.tokenString
            
            // Enhanced credential creation with additional properties
            let credentials = YouTubeCredentials(
                accessToken: accessToken,
                refreshToken: user.refreshToken.tokenString,
                idToken: user.idToken?.tokenString,
                expiresAt: user.accessToken.expirationDate,
                serverAuthCode: result.serverAuthCode, // For offline access
                userInfo: [
                    "email": user.profile?.email ?? "",
                    "name": user.profile?.name ?? "",
                    "given_name": user.profile?.givenName ?? "",
                    "family_name": user.profile?.familyName ?? "",
                    "picture": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
                    "user_id": user.userID ?? ""
                ]
            )
            
            return credentials
            
        } catch {
            print("❌ [YouTubeAuth] Google Sign-In failed: \(error.localizedDescription)")
            
            // Check if this is a timeout-related error
            if error.localizedDescription.contains("timeout") || 
               error.localizedDescription.contains("timed out") ||
               error.localizedDescription.contains("cancelled") {
                throw OnairosError.googleSignInFailed("YouTube authentication timed out or was cancelled")
            }
            
            throw OnairosError.googleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Sign out from Google
    public func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    /// Check if user is currently signed in
    /// - Returns: True if user has valid session
    public func isSignedIn() -> Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    /// Get current user if signed in
    /// - Returns: Current YouTube credentials or nil
    public func getCurrentUser() -> YouTubeCredentials? {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            return nil
        }
        
        let accessToken = user.accessToken.tokenString
        
        return YouTubeCredentials(
            accessToken: accessToken,
            refreshToken: user.refreshToken.tokenString,
            idToken: user.idToken?.tokenString,
            expiresAt: user.accessToken.expirationDate,
            serverAuthCode: nil, // Server auth code not available in current user
            userInfo: [
                "email": user.profile?.email ?? "",
                "name": user.profile?.name ?? "",
                "given_name": user.profile?.givenName ?? "",
                "family_name": user.profile?.familyName ?? "",
                "picture": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
                "user_id": user.userID ?? ""
            ]
        )
    }
    
    /// Refresh access token if needed
    /// - Returns: Updated credentials
    public func refreshTokenIfNeeded() async throws -> YouTubeCredentials {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw OnairosError.googleSignInFailed("No current user")
        }
        
        do {
            try await user.refreshTokensIfNeeded()
            
            let accessToken = user.accessToken.tokenString
            
            return YouTubeCredentials(
                accessToken: accessToken,
                refreshToken: user.refreshToken.tokenString,
                idToken: user.idToken?.tokenString,
                expiresAt: user.accessToken.expirationDate,
                serverAuthCode: nil, // Server auth code not available during token refresh
                userInfo: [
                    "email": user.profile?.email ?? "",
                    "name": user.profile?.name ?? "",
                    "given_name": user.profile?.givenName ?? "",
                    "family_name": user.profile?.familyName ?? "",
                    "picture": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
                    "user_id": user.userID ?? ""
                ]
            )
            
        } catch {
            throw OnairosError.googleSignInFailed("Token refresh failed: \(error.localizedDescription)")
        }
    }
    
    /// Handle URL callback from Google Sign-In
    /// - Parameter url: Callback URL
    /// - Returns: True if URL was handled
    public func handleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    /// Check if YouTube authentication is available
    /// - Returns: True if Google Sign-In is configured
    public func isAvailable() -> Bool {
        return isInitialized && GIDSignIn.sharedInstance.configuration != nil
    }
    
    /// Validate YouTube authentication configuration
    /// - Returns: Configuration validation result
    public func validateConfiguration() -> YouTubeConfigurationResult {
        // Check if initialized
        guard isInitialized else {
            return .notInitialized
        }
        
        // Check if Google Sign-In is configured
        guard GIDSignIn.sharedInstance.configuration != nil else {
            return .notConfigured
        }
        
        // Check if URL scheme is configured in Info.plist
        guard let requiredURLScheme = getExpectedURLScheme() else {
            return .notConfigured
        }
        
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return .missingURLScheme(requiredURLScheme)
        }
        
        for urlType in urlTypes {
            if let schemes = urlType["CFBundleURLSchemes"] as? [String],
               schemes.contains(requiredURLScheme) {
                return .configured
            }
        }
        
        return .missingURLScheme(requiredURLScheme)
    }
    
    /// Get detailed configuration status for debugging
    /// - Returns: Configuration status details
    public func getConfigurationStatus() -> [String: Any] {
        var status: [String: Any] = [:]
        
        status["isInitialized"] = isInitialized
        status["hasGoogleSignInConfiguration"] = GIDSignIn.sharedInstance.configuration != nil
        status["clientID"] = clientID ?? "Not set"
        
        // Check URL schemes
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            var configuredSchemes: [String] = []
            for urlType in urlTypes {
                if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                    configuredSchemes.append(contentsOf: schemes)
                }
            }
            status["configuredURLSchemes"] = configuredSchemes
        } else {
            status["configuredURLSchemes"] = []
        }
        
        if let expectedScheme = getExpectedURLScheme() {
            status["expectedURLScheme"] = expectedScheme
        }
        
        return status
    }
    
    /// Restore previous sign-in state
    /// - Returns: True if previous session was restored
    public func restorePreviousSignIn() async -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            return false
        }
        
        do {
            try await user.refreshTokensIfNeeded()
            return true
        } catch {
            return false
        }
    }
    
    /// Get presenting view controller
    /// - Returns: Top-most view controller
    @MainActor
    private func getPresentingViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
}

/// YouTube credentials structure
public struct YouTubeCredentials {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let expiresAt: Date?
    public let serverAuthCode: String?
    public let userInfo: [String: String]
    
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        idToken: String? = nil,
        expiresAt: Date? = nil,
        serverAuthCode: String? = nil,
        userInfo: [String: String] = [:]
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.expiresAt = expiresAt
        self.serverAuthCode = serverAuthCode
        self.userInfo = userInfo
    }
    
    /// Check if token is expired
    /// - Returns: True if token is expired
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }
    
    /// Check if token expires soon (within 5 minutes)
    /// - Returns: True if token expires soon
    public var expiresSoon: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date().addingTimeInterval(300) >= expiresAt // 5 minutes
    }
    
    /// Check if offline access is available
    /// - Returns: True if server auth code is available for offline access
    public var hasOfflineAccess: Bool {
        return serverAuthCode != nil || refreshToken != nil
    }
}

/// YouTube authentication error
public enum YouTubeAuthError: Error, LocalizedError {
    case googleSignInNotConfigured
    case noAccessToken
    case tokenRefreshFailed(String)
    case userCancelled
    case networkError(String)
    case offlineAccessNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .googleSignInNotConfigured:
            return "Google Sign-In is not properly configured. Please check your GoogleService-Info.plist file."
        case .noAccessToken:
            return "No access token received from Google Sign-In."
        case .tokenRefreshFailed(let reason):
            return "Failed to refresh YouTube access token: \(reason)"
        case .userCancelled:
            return "YouTube authentication was cancelled by the user."
        case .networkError(let reason):
            return "Network error during YouTube authentication: \(reason)"
        case .offlineAccessNotAvailable:
            return "Offline access is not available. Please re-authenticate."
        }
    }
} 