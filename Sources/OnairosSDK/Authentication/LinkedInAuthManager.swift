import Foundation

/// LinkedIn authentication manager using OAuth
public class LinkedInAuthManager {
    
    /// Shared instance
    public static let shared = LinkedInAuthManager()
    
    /// LinkedIn client ID
    private var clientID: String?
    
    /// LinkedIn client secret
    private var clientSecret: String?
    
    /// Initialization status
    private var isInitialized = false
    
    /// Private initializer
    private init() {}
    
    /// Initialize LinkedIn OAuth
    /// - Parameters:
    ///   - clientID: LinkedIn OAuth client ID
    ///   - clientSecret: LinkedIn OAuth client secret
    public func initialize(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        isInitialized = true
    }
    
    /// Exchange authorization code for access token
    /// - Parameter authCode: Authorization code from OAuth callback
    /// - Returns: LinkedIn credentials
    public func exchangeCodeForToken(authCode: String) async throws -> LinkedInCredentials {
        guard isInitialized else {
            throw OnairosError.authenticationFailed("LinkedIn authentication not initialized")
        }
        
        guard let clientID = clientID, let clientSecret = clientSecret else {
            throw OnairosError.configurationError("LinkedIn client ID or secret not configured")
        }
        
        let tokenURL = "https://www.linkedin.com/oauth/v2/accessToken"
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "grant_type": "authorization_code",
            "code": authCode,
            "redirect_uri": "your-app://oauth/callback", // This should match your configured redirect URI
            "client_id": clientID,
            "client_secret": clientSecret
        ]
        
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OnairosError.authenticationFailed("Invalid response from LinkedIn")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OnairosError.authenticationFailed("LinkedIn token exchange failed with status \(httpResponse.statusCode)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                throw OnairosError.authenticationFailed("Invalid token response from LinkedIn")
            }
            
            let refreshToken = json["refresh_token"] as? String
            let expiresIn = json["expires_in"] as? Int
            let expiresAt = expiresIn != nil ? Date().addingTimeInterval(TimeInterval(expiresIn!)) : nil
            
            return LinkedInCredentials(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: json["token_type"] as? String ?? "Bearer",
                scope: json["scope"] as? String
            )
            
        } catch {
            throw OnairosError.authenticationFailed("LinkedIn token exchange failed: \(error.localizedDescription)")
        }
    }
    
    /// Get LinkedIn profile information
    /// - Parameter credentials: LinkedIn credentials
    /// - Returns: LinkedIn profile data
    public func getProfile(credentials: LinkedInCredentials) async throws -> LinkedInProfile {
        let profileURL = "https://api.linkedin.com/v2/me"
        var request = URLRequest(url: URL(string: profileURL)!)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OnairosError.authenticationFailed("Invalid response from LinkedIn")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OnairosError.authenticationFailed("LinkedIn profile request failed with status \(httpResponse.statusCode)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw OnairosError.authenticationFailed("Invalid profile response from LinkedIn")
            }
            
            return LinkedInProfile(from: json)
            
        } catch {
            throw OnairosError.authenticationFailed("LinkedIn profile request failed: \(error.localizedDescription)")
        }
    }
    
    /// Check if LinkedIn authentication is available
    /// - Returns: True if LinkedIn OAuth is configured
    public func isAvailable() -> Bool {
        return isInitialized && clientID != nil && clientSecret != nil
    }
}

/// LinkedIn credentials structure
public struct LinkedInCredentials {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?
    public let tokenType: String
    public let scope: String?
    
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        tokenType: String = "Bearer",
        scope: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.scope = scope
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
}

/// LinkedIn profile data structure
public struct LinkedInProfile {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let profilePictureURL: String?
    public let headline: String?
    public let summary: String?
    public let location: String?
    public let industry: String?
    public let publicProfileURL: String?
    public let userData: [String: Any]
    
    public init(
        id: String,
        firstName: String,
        lastName: String,
        profilePictureURL: String? = nil,
        headline: String? = nil,
        summary: String? = nil,
        location: String? = nil,
        industry: String? = nil,
        publicProfileURL: String? = nil,
        userData: [String: Any] = [:]
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.profilePictureURL = profilePictureURL
        self.headline = headline
        self.summary = summary
        self.location = location
        self.industry = industry
        self.publicProfileURL = publicProfileURL
        self.userData = userData
    }
    
    /// Initialize from LinkedIn API response
    /// - Parameter data: Data from LinkedIn API
    public init(from data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        
        // LinkedIn API returns localized names
        let firstName = data["firstName"] as? [String: Any]
        let lastName = data["lastName"] as? [String: Any]
        
        self.firstName = (firstName?["localized"] as? [String: String])?.values.first ?? ""
        self.lastName = (lastName?["localized"] as? [String: String])?.values.first ?? ""
        
        self.headline = data["headline"] as? String
        self.summary = data["summary"] as? String
        self.location = data["location"] as? String
        self.industry = data["industry"] as? String
        self.publicProfileURL = data["publicProfileUrl"] as? String
        
        // Profile picture handling
        if let profilePicture = data["profilePicture"] as? [String: Any],
           let displayImage = profilePicture["displayImage"] as? String {
            self.profilePictureURL = displayImage
        } else {
            self.profilePictureURL = nil
        }
        
        self.userData = data
    }
    
    /// Full name computed property
    public var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

/// LinkedIn authentication error
public enum LinkedInAuthError: Error, LocalizedError {
    case oauthNotConfigured
    case authorizationFailed(String)
    case tokenExchangeFailed(String)
    case profileDataUnavailable
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .oauthNotConfigured:
            return "LinkedIn OAuth is not properly configured. Please check your client ID and secret."
        case .authorizationFailed(let reason):
            return "LinkedIn authorization failed: \(reason)"
        case .tokenExchangeFailed(let reason):
            return "Failed to exchange LinkedIn authorization code: \(reason)"
        case .profileDataUnavailable:
            return "Unable to retrieve LinkedIn profile data."
        case .networkError(let reason):
            return "Network error during LinkedIn authentication: \(reason)"
        }
    }
} 