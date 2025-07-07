import Foundation
import UIKit

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
        case .gmail: return "Gmail.png"
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
    
    /// Validate PIN requirements
    private func isValidPIN(_ pin: String) -> Bool {
        guard pin.count >= 8 else { return false }
        
        let hasNumbers = pin.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = pin.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        return hasNumbers && hasSpecialChars
    }
}

/// PIN validation requirements
public struct PINRequirements {
    public let minLength: Int = 8
    public let requiresNumbers: Bool = true
    public let requiresSpecialChars: Bool = true
    
    public func validate(_ pin: String) -> [PINValidationResult] {
        var results: [PINValidationResult] = []
        
        results.append(.length(pin.count >= minLength))
        
        if requiresNumbers {
            let hasNumbers = pin.rangeOfCharacter(from: .decimalDigits) != nil
            results.append(.numbers(hasNumbers))
        }
        
        if requiresSpecialChars {
            let hasSpecialChars = pin.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
            results.append(.specialChars(hasSpecialChars))
        }
        
        return results
    }
}

/// PIN validation result
public enum PINValidationResult {
    case length(Bool)
    case numbers(Bool)
    case specialChars(Bool)
    
    public var isValid: Bool {
        switch self {
        case .length(let valid), .numbers(let valid), .specialChars(let valid):
            return valid
        }
    }
    
    public var description: String {
        switch self {
        case .length(let valid):
            return valid ? "✓ At least 8 characters" : "✗ At least 8 characters"
        case .numbers(let valid):
            return valid ? "✓ Contains numbers" : "✗ Contains numbers"
        case .specialChars(let valid):
            return valid ? "✓ Contains special characters" : "✗ Contains special characters"
        }
    }
}

/// Email verification request
public struct EmailVerificationRequest: Codable {
    public let email: String
    public let code: String?
    
    public init(email: String, code: String? = nil) {
        self.email = email
        self.code = code
    }
}

/// Email verification response
public struct EmailVerificationResponse: Codable {
    public let success: Bool
    public let message: String?
    public let verified: Bool?
    public let testingMode: Bool?
    public let email: String?
    public let isNewUser: Bool?
    public let user: UserData?
    public let error: String?
    public let code: Int?
    public let attemptsRemaining: Int?
    
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
    
    public init(
        platform: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        idToken: String? = nil,
        authCode: String? = nil,
        userData: [String: Any]? = nil
    ) {
        self.platform = platform
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.authCode = authCode
        self.userData = userData?.mapValues { AnyCodable($0) }
    }
}

/// Platform authentication response
public struct PlatformAuthResponse: Codable {
    public let success: Bool
    public let message: String?
    public let token: String?
    public let userData: [String: AnyCodable]?
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