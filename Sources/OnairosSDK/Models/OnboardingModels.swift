import Foundation
import UIKit

/// SDK Environment configuration
public enum SDKEnvironment: String, CaseIterable {
    case production = "production"
    case development = "development"
    
    /// Base URL for API requests
    public var baseURL: String {
        switch self {
        case .production: return "https://api2.onairos.uk"
        case .development: return "https://dev-api.onairos.uk"
        }
    }
    
    /// Display name for environment
    public var displayName: String {
        switch self {
        case .production: return "Production"
        case .development: return "Development"
        }
    }
}

/// SDK Configuration
public struct OnairosConfig {
    public let apiKey: String
    public let environment: SDKEnvironment
    public let enableLogging: Bool
    public let timeout: TimeInterval
    
    // Additional properties for backward compatibility
    public let apiBaseURL: String
    public let isTestMode: Bool
    public let isDebugMode: Bool
    public let allowEmptyConnections: Bool
    public let simulateTraining: Bool
    public let platforms: Set<Platform>
    public let linkedInClientID: String?
    public let googleClientID: String?
    public let urlScheme: String
    public let appName: String
    public let enableSecureOAuth: Bool
    
    public init(
        apiKey: String,
        environment: SDKEnvironment = .production,
        enableLogging: Bool = false,
        timeout: TimeInterval = 30.0,
        isTestMode: Bool = false,
        isDebugMode: Bool = false,
        allowEmptyConnections: Bool = false,
        simulateTraining: Bool = false,
        platforms: Set<Platform> = [.linkedin, .youtube, .reddit, .pinterest, .gmail],
        linkedInClientID: String? = nil,
        googleClientID: String? = nil,
        urlScheme: String = "onairos",
        appName: String = "iOS App",
        enableSecureOAuth: Bool = true
    ) {
        self.apiKey = apiKey
        self.environment = environment
        self.enableLogging = enableLogging
        self.timeout = timeout
        
        // Derive additional properties from environment and flags
        self.apiBaseURL = environment.baseURL
        self.isTestMode = isTestMode
        self.isDebugMode = isDebugMode || enableLogging
        self.allowEmptyConnections = allowEmptyConnections || isTestMode
        self.simulateTraining = isTestMode ? true : simulateTraining
        self.platforms = platforms
        self.linkedInClientID = linkedInClientID
        self.googleClientID = googleClientID
        self.urlScheme = urlScheme
        self.appName = appName
        self.enableSecureOAuth = enableSecureOAuth
    }
    
    /// Convenience initializer for test scenarios without API key
    /// - Parameters:
    ///   - isTestMode: Enable test mode
    ///   - isDebugMode: Enable debug mode
    ///   - urlScheme: URL scheme for OAuth redirects
    ///   - appName: Application name
    public init(
        isTestMode: Bool = true,
        isDebugMode: Bool = true,
        urlScheme: String = "onairos-test",
        appName: String = "Test App"
    ) {
        self.apiKey = OnairosAPIKeyService.ADMIN_API_KEY
        self.environment = .production  // Use production API for OAuth to work
        self.enableLogging = isDebugMode
        self.timeout = 30.0
        
        // Derive additional properties from environment and flags
        self.apiBaseURL = environment.baseURL
        self.isTestMode = isTestMode
        self.isDebugMode = isDebugMode
        self.allowEmptyConnections = isTestMode
        self.simulateTraining = isTestMode
        self.platforms = [.linkedin, .youtube, .reddit, .pinterest, .gmail]
        self.linkedInClientID = nil
        self.googleClientID = nil
        self.urlScheme = urlScheme
        self.appName = appName
        self.enableSecureOAuth = true // Default to true for test mode
    }
    
    /// Computed log level based on mode
    public var logLevel: APILogLevel {
        if isTestMode {
            return .verbose
        } else if isDebugMode {
            return .debug
        } else {
            return .info
        }
    }
    
    /// Create a test configuration for development
    /// - Parameters:
    ///   - urlScheme: URL scheme for OAuth redirects
    ///   - appName: Application name
    /// - Returns: Test configuration that bypasses all API calls
    public static func testMode(
        urlScheme: String = "onairos-test",
        appName: String = "Test App"
    ) -> OnairosConfig {
        return OnairosConfig(
            apiKey: OnairosAPIKeyService.ADMIN_API_KEY,
            environment: .production,  // Use production API for OAuth to work
            enableLogging: true,
            timeout: 30.0,
            isTestMode: true,
            isDebugMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            platforms: [.linkedin, .youtube, .reddit, .pinterest, .gmail],
            linkedInClientID: nil,
            googleClientID: nil,
            urlScheme: urlScheme,
            appName: appName,
            enableSecureOAuth: true
        )
    }
    
    /// Create a debug configuration for development
    /// - Returns: Debug configuration with enhanced logging
    public static func debugMode() -> OnairosConfig {
        return OnairosConfig(
            apiKey: OnairosAPIKeyService.ADMIN_API_KEY,
            environment: .production,  // Use production API for OAuth to work
            enableLogging: true,
            timeout: 30.0,
            isTestMode: false,
            isDebugMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            platforms: [.linkedin, .youtube, .reddit, .pinterest, .gmail],
            linkedInClientID: nil,
            googleClientID: nil,
            urlScheme: "onairos-debug",
            appName: "Debug App",
            enableSecureOAuth: true
        )
    }
}

/// API Key validation result
public struct ValidationResult {
    public let isValid: Bool
    public let error: String?
    
    public init(isValid: Bool, error: String? = nil) {
        self.isValid = isValid
        self.error = error
    }
}

/// Onboarding step enumeration
public enum OnboardingStep: String, CaseIterable {
    case email = "email"
    case verify = "verify"
    case connect = "connect"
    case success = "success"
    case pin = "pin"
    case training = "training"
}

/// Platform enumeration
public enum Platform: String, CaseIterable, Hashable {
    case linkedin = "linkedin"
    case youtube = "youtube"
    case reddit = "reddit"
    case pinterest = "pinterest"
    case gmail = "gmail"
    
    /// Display name for the platform
    public var displayName: String {
        switch self {
        case .linkedin: return "LinkedIn"
        case .youtube: return "YouTube"
        case .reddit: return "Reddit"
        case .pinterest: return "Pinterest"
        case .gmail: return "Gmail"
        }
    }
    
    /// Authentication method for the platform
    public var authMethod: AuthMethod {
        switch self {
        case .linkedin: return .oauth
        case .youtube: return .nativeSDK
        case .reddit, .pinterest, .gmail: return .oauth
        }
    }
    
    /// OAuth authorization URL for the platform
    public func authorizationURL(baseURL: String) -> String {
        switch self {
        case .linkedin: return "\(baseURL)/linkedin/authorize"
        case .youtube: return "\(baseURL)/youtube/native-auth"
        case .reddit: return "\(baseURL)/reddit/authorize"
        case .pinterest: return "\(baseURL)/pinterest/authorize"
        case .gmail: return "\(baseURL)/gmail/authorize"
        }
    }
    
    /// OAuth scopes for the platform
    public var oauthScopes: String {
        switch self {
        case .linkedin: return "r_liteprofile r_emailaddress"
        case .youtube: return "" // Uses Google Sign-In SDK, not OAuth
        case .reddit: return "identity read"
        case .pinterest: return "read_public"
        case .gmail: return "https://www.googleapis.com/auth/gmail.readonly"
        }
    }
    
    /// Icon filename for the platform
    public var iconFileName: String {
        switch self {
        case .linkedin: return "Linkedinicon.png"
        case .youtube: return "YouTubeicon1.png"
        case .reddit: return "RedditIcon.png"
        case .pinterest: return "pinterest.png"
        case .gmail: return "propergmailicon.png"
        }
    }
}

/// Authentication method enumeration
public enum AuthMethod {
    case nativeSDK     // YouTube - uses Google Sign-In SDK
    case oauth         // Others - WebView OAuth flow
}

/// Onboarding state observable object
@MainActor
public class OnboardingState: ObservableObject {
    @Published public var currentStep: OnboardingStep = .email
    @Published public var email: String = ""
    @Published public var verificationCode: String = ""
    @Published public var connectedPlatforms: Set<String> = []
    @Published public var pin: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var trainingStatus: String = "Initializing..."
    @Published public var accountInfo: [String: AnyCodable]?
    
    /// Training progress with NaN protection
    @Published public var trainingProgress: Double = 0.0
    
    /// Safely set training progress with NaN protection
    /// - Parameter progress: Progress value to set
    public func setTrainingProgress(_ progress: Double) {
        // Protect against NaN and infinite values that cause CoreGraphics errors
        let safeValue = progress.isNaN || progress.isInfinite ? 0.0 : min(max(progress, 0.0), 1.0)
        trainingProgress = safeValue
    }
    
    /// Reset state to initial values
    public func reset() {
        currentStep = .email
        email = ""
        verificationCode = ""
        connectedPlatforms.removeAll()
        pin = ""
        trainingProgress = 0.0
        isLoading = false
        errorMessage = nil
        trainingStatus = "Initializing..."
        accountInfo = nil
    }
    
    /// Validate current step data
    public func validateCurrentStep() -> Bool {
        switch currentStep {
        case .email:
            return isValidEmail(email)
        case .verify:
            return verificationCode.count == 6
        case .connect:
            return true // Can proceed with or without connections in debug mode
        case .success:
            return true // Auto-advance step
        case .pin:
            return isValidPIN(pin)
        case .training:
            return trainingProgress >= 1.0
        }
    }
    
    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        // Guard against empty or extremely long emails that could cause regex issues
        guard !email.isEmpty && email.count <= 254 else {
            return false
        }
        
        // Protect against potential regex crashes with try-catch
        do {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        } catch {
            print("🚨 [ERROR] Email validation regex failed: \(error)")
            // Fallback to basic email check
            return email.contains("@") && email.contains(".")
        }
    }
    
    /// Validate PIN requirements with performance optimization
    private func isValidPIN(_ pin: String) -> Bool {
        // SAFEGUARD: Quick length check first
        guard pin.count >= 8 else { return false }
        
        // SAFEGUARD: Protect against potential regex/character set crashes
        do {
            let hasNumbers = pin.rangeOfCharacter(from: .decimalDigits) != nil
            let hasSpecialChars = pin.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
            
            return hasNumbers && hasSpecialChars
        } catch {
            print("🚨 [ERROR] PIN validation crashed: \(error)")
            // Fallback: basic character checks
            let hasNumbers = pin.contains { $0.isNumber }
            let hasSpecialChars = pin.contains { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }
            
            return hasNumbers && hasSpecialChars
        }
    }
}

/// PIN validation requirements
public struct PINRequirements {
    public let minLength: Int = 8
    public let requiresNumbers: Bool = true
    public let requiresSpecialChars: Bool = true
    
    public func validate(_ pin: String) -> [PINValidationResult] {
        var results: [PINValidationResult] = []
        
        // SAFEGUARD: Protect against potential performance issues
        do {
            // Check length (8+ characters)
            let lengthValid = pin.count >= minLength
            results.append(.length(lengthValid))
            
            // Check if contains numbers
            if requiresNumbers {
                let hasNumbers = pin.rangeOfCharacter(from: .decimalDigits) != nil
                results.append(.hasNumbers(hasNumbers))
            }
            
            // Check if contains special characters
            if requiresSpecialChars {
                let hasSpecialChars = pin.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
                results.append(.hasSpecialChars(hasSpecialChars))
            }
        } catch {
            print("🚨 [ERROR] PINRequirements validation crashed: \(error)")
            // Fallback: basic validation
            results.append(.length(pin.count >= minLength))
            
            if requiresNumbers {
                let hasNumbers = pin.contains { $0.isNumber }
                results.append(.hasNumbers(hasNumbers))
            }
            
            if requiresSpecialChars {
                let hasSpecialChars = pin.contains { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }
                results.append(.hasSpecialChars(hasSpecialChars))
            }
        }
        
        return results
    }
}

/// PIN validation result
public enum PINValidationResult {
    case length(Bool)
    case hasNumbers(Bool)
    case hasSpecialChars(Bool)
    
    public var isValid: Bool {
        switch self {
        case .length(let valid), .hasNumbers(let valid), .hasSpecialChars(let valid):
            return valid
        }
    }
    
    public var description: String {
        switch self {
        case .length(let valid):
            return valid ? "✓ At least 8 characters" : "✗ At least 8 characters"
        case .hasNumbers(let valid):
            return valid ? "✓ Contains numbers" : "✗ Contains numbers"
        case .hasSpecialChars(let valid):
            return valid ? "✓ Contains special characters" : "✗ Contains special characters"
        }
    }
}

/// Email verification request for unified API
public struct EmailVerificationRequest: Codable {
    public let email: String
    public let action: String
    public let code: String?
    
    public init(email: String, action: String, code: String? = nil) {
        self.email = email
        self.action = action
        self.code = code
    }
    
    /// Request verification code
    public static func requestCode(email: String) -> EmailVerificationRequest {
        return EmailVerificationRequest(email: email, action: "request")
    }
    
    /// Verify email with code
    public static func verifyCode(email: String, code: String) -> EmailVerificationRequest {
        return EmailVerificationRequest(email: email, action: "verify", code: code)
    }
}

/// Email verification response for unified API
public struct EmailVerificationResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: EmailVerificationData?
    public let error: String?
    public let code: String?
    
    /// Data structure for successful email verification responses
    public struct EmailVerificationData: Codable {
        public let verified: Bool?
        public let testingMode: Bool?
        public let email: String?
        public let isNewUser: Bool?
        public let user: UserData?
        public let attemptsRemaining: Int?
        public let accountInfo: [String: AnyCodable]?
        
        /// User data structure from API response
        public struct UserData: Codable {
            public let id: String
            public let userId: String
            public let userName: String
            public let name: String
            public let email: String
            public let verified: Bool
            public let creationDate: String
        }
    }
    
    /// Legacy computed properties for backward compatibility
    public var verified: Bool? {
        return data?.verified
    }
    
    public var testingMode: Bool? {
        return data?.testingMode
    }
    
    public var email: String? {
        return data?.email
    }
    
    public var isNewUser: Bool? {
        return data?.isNewUser
    }
    
    public var user: EmailVerificationData.UserData? {
        return data?.user
    }
    
    public var attemptsRemaining: Int? {
        return data?.attemptsRemaining
    }
    
    public var accountInfo: [String: AnyCodable]? {
        return data?.accountInfo
    }
}

/// Email verification error response
public struct EmailVerificationErrorResponse: Codable {
    public let success: Bool
    public let error: String
    public let code: Int
    public let attemptsRemaining: Int?
}

/// Email verification status response
public struct EmailVerificationStatusResponse: Codable {
    public let success: Bool
    public let hasCode: Bool?
    public let expiresAt: String?
}

/// Platform authentication request
public struct PlatformAuthRequest: Codable {
    public let platform: String
    public let accessToken: String?
    public let refreshToken: String?
    public let idToken: String?
    public let authCode: String?
    public let userData: [String: AnyCodable]?
    public let session: SessionData?
    
    public init(
        platform: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        idToken: String? = nil,
        authCode: String? = nil,
        userData: [String: Any]? = nil,
        username: String? = nil
    ) {
        self.platform = platform
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.authCode = authCode
        self.userData = userData?.mapValues { AnyCodable($0) }
        
        // Create session data if username is provided
        if let username = username {
            self.session = SessionData(username: username)
        } else {
            // Try to get username from UserDefaults as fallback
            let storedUsername = UserDefaults.standard.string(forKey: "onairos_username")
            if let storedUsername = storedUsername, !storedUsername.isEmpty {
                self.session = SessionData(username: storedUsername)
            } else {
                self.session = nil
            }
        }
    }
}

/// Session data for OAuth requests
public struct SessionData: Codable {
    public let username: String
    
    public init(username: String) {
        self.username = username
    }
}

/// Platform authentication response
public struct PlatformAuthResponse: Codable {
    public let success: Bool
    public let message: String?
    public let token: String?
    public let userData: [String: AnyCodable]?
}

/// Authorization URL response from backend
public struct AuthorizationURLResponse: Codable {
    public let success: Bool
    public let linkedinURL: String?
    public let redditURL: String?
    public let pinterestURL: String?
    public let gmailURL: String?
    public let youtubeURL: String?
    public let note: String?
    public let scopes: String?
    public let error: String?
    
    /// Custom initializer to handle different response formats
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode success field, default to true if not present
        self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        
        // Decode URL fields
        self.linkedinURL = try container.decodeIfPresent(String.self, forKey: .linkedinURL)
        self.redditURL = try container.decodeIfPresent(String.self, forKey: .redditURL)
        self.pinterestURL = try container.decodeIfPresent(String.self, forKey: .pinterestURL)
        self.gmailURL = try container.decodeIfPresent(String.self, forKey: .gmailURL)
        self.youtubeURL = try container.decodeIfPresent(String.self, forKey: .youtubeURL)
        
        // Decode optional fields
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.scopes = try container.decodeIfPresent(String.self, forKey: .scopes)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
    }
    
    /// Get the authorization URL for a specific platform
    /// - Parameter platform: Platform to get URL for
    /// - Returns: Authorization URL if available
    public func authorizationURL(for platform: Platform) -> String? {
        switch platform {
        case .linkedin:
            return linkedinURL
        case .reddit:
            return redditURL
        case .pinterest:
            return pinterestURL
        case .gmail:
            return gmailURL
        case .youtube:
            return youtubeURL
        }
    }
    
    /// Coding keys for the response
    private enum CodingKeys: String, CodingKey {
        case success
        case linkedinURL
        case redditURL
        case pinterestURL
        case gmailURL
        case youtubeURL
        case note
        case scopes
        case error
    }
}

/// User registration request
public struct UserRegistrationRequest: Codable {
    public let email: String
    public let pin: String
    public let connectedPlatforms: [String: PlatformData]
    public let deviceInfo: DeviceInfo
    
    public init(email: String, pin: String, connectedPlatforms: [String: PlatformData]) {
        self.email = email
        self.pin = pin
        self.connectedPlatforms = connectedPlatforms
        self.deviceInfo = DeviceInfo()
    }
}

/// Device information
public struct DeviceInfo: Codable {
    public let platform: String
    public let version: String
    public let model: String
    public let appVersion: String
    
    public init() {
        self.platform = "iOS"
        self.version = UIDevice.current.systemVersion
        self.model = UIDevice.current.model
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/// Training progress data
public struct TrainingProgress {
    public let percentage: Double
    public let status: String
    public let isComplete: Bool
    
    public init(percentage: Double, status: String, isComplete: Bool = false) {
        // Protect against NaN and infinite values that cause CoreGraphics errors
        let safePercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : min(max(percentage, 0.0), 1.0)
        self.percentage = safePercentage
        self.status = status
        self.isComplete = isComplete
    }
}

/// Socket.IO training events
public enum TrainingEvent: String {
    case progress = "training_progress"
    case complete = "training_complete"
    case error = "training_error"
    case start = "start_training"
}

/// Helper for encoding Any values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}

/// PIN submission request
public struct PINSubmissionRequest: Codable {
    public let username: String
    public let pin: String
    
    public init(username: String, pin: String) {
        self.username = username
        self.pin = pin
    }
}

/// PIN submission response
public struct PINSubmissionResponse: Codable {
    public let success: Bool
    public let message: String
    public let userId: String?
    public let pinSecured: Bool?
    public let timestamp: String?
}

// MARK: - Biometric PIN Management Types

/// Biometric PIN error types
public enum BiometricPINError: Error, LocalizedError {
    case invalidPIN
    case biometricNotAvailable
    case authenticationFailed
    case authenticationCancelled
    case pinNotFound
    case keychainError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPIN:
            return "Invalid PIN provided"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .authenticationCancelled:
            return "Authentication was cancelled by the user"
        case .pinNotFound:
            return "No PIN found in secure storage"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        }
    }
}

/// Biometric availability status
public enum BiometricAvailability {
    case faceID
    case touchID
    case opticID
    case notAvailable
    case notEnrolled
    case lockedOut
    case unknown
    
    public var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .notAvailable:
            return "Not Available"
        case .notEnrolled:
            return "Not Enrolled"
        case .lockedOut:
            return "Locked Out"
        case .unknown:
            return "Unknown"
        }
    }
} 