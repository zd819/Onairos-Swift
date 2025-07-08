import Foundation
import GoogleSignIn
import UIKit

/// YouTube authentication manager using Google Sign-In SDK
public class YouTubeAuthManager {
    
    /// Shared instance
    public static let shared = YouTubeAuthManager()
    
    /// Configuration constants
    private struct Config {
        static let webClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
        static let iosClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
        static let scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
        static let offlineAccess = true
        static let forceCodeForRefreshToken = true
    }
    
    /// Google client ID
    private var clientID: String?
    
    /// Initialization status
    private var isInitialized = false
    
    /// Private initializer
    private init() {}
    
    /// Initialize Google Sign-In with enhanced configuration
    /// - Parameter clientID: Optional custom client ID (defaults to configured iOS client ID)
    public func initialize(clientID: String? = nil) {
        let finalClientID = clientID ?? Config.iosClientId
        self.clientID = finalClientID
        
        // Configure Google Sign-In with enhanced settings
        let configuration = GIDConfiguration(clientID: finalClientID, serverClientID: Config.webClientId)
        
        GIDSignIn.sharedInstance.configuration = configuration
        isInitialized = true
    }
    
    /// Authenticate with YouTube using enhanced configuration
    /// - Returns: YouTube credentials
    public func authenticate() async throws -> YouTubeCredentials {
        guard isInitialized else {
            throw OnairosError.googleSignInFailed("Google Sign-In not initialized")
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