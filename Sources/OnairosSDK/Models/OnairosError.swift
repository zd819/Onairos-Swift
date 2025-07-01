import Foundation

/// Onairos SDK error enumeration
public enum OnairosError: Error, LocalizedError {
    case notInitialized
    case networkUnavailable
    case invalidCredentials
    case platformUnavailable(String)
    case opacitySDKRequired
    case googleSignInFailed(String)
    case emailVerificationFailed(String)
    case invalidEmail
    case invalidPIN
    case trainingFailed(String)
    case userCancelled
    case configurationError(String)
    case apiError(String, Int?)
    case socketConnectionFailed
    case unknownError(String)
    
    /// User-friendly error descriptions
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SDK not initialized. Please call OnairosSDK.shared.initialize() first."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .invalidCredentials:
            return "Invalid verification code. Please try again."
        case .platformUnavailable(let platform):
            return "\(platform) connection is currently unavailable."
        case .opacitySDKRequired:
            return "Instagram connection requires the Opacity SDK."
        case .googleSignInFailed(let reason):
            return "YouTube connection failed: \(reason)"
        case .emailVerificationFailed(let reason):
            return "Email verification failed: \(reason)"
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPIN:
            return "PIN must be at least 8 characters with numbers and special characters."
        case .trainingFailed(let reason):
            return "AI training failed: \(reason)"
        case .userCancelled:
            return "Operation cancelled by user."
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        case .apiError(let message, let code):
            if let code = code {
                return "API error (\(code)): \(message)"
            } else {
                return "API error: \(message)"
            }
        case .socketConnectionFailed:
            return "Failed to connect to training server."
        case .unknownError(let reason):
            return "An unexpected error occurred: \(reason)"
        }
    }
    
    /// Error recovery suggestions
    public var recoverySuggestion: String? {
        switch self {
        case .notInitialized:
            return "Initialize the SDK in your AppDelegate or before using."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidCredentials:
            return "Enter the correct verification code from your email."
        case .platformUnavailable:
            return "Try connecting to other platforms or skip this step."
        case .opacitySDKRequired:
            return "Contact your app developer to add Instagram support."
        case .googleSignInFailed:
            return "Make sure Google Sign-In is properly configured."
        case .emailVerificationFailed:
            return "Check your email for the verification code."
        case .invalidEmail:
            return "Enter a valid email address format."
        case .invalidPIN:
            return "Create a PIN with at least 8 characters, including numbers and special characters."
        case .trainingFailed:
            return "Try again or contact support if the problem persists."
        case .userCancelled:
            return "You can restart the onboarding process anytime."
        case .configurationError:
            return "Check your SDK configuration settings."
        case .apiError:
            return "Try again or contact support if the problem persists."
        case .socketConnectionFailed:
            return "Check your internet connection and try again."
        case .unknownError:
            return "Try again or contact support if the problem persists."
        }
    }
    
    /// Whether the error is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .notInitialized, .configurationError, .opacitySDKRequired:
            return false
        case .userCancelled:
            return true
        default:
            return true
        }
    }
    
    /// Error category for analytics
    public var category: ErrorCategory {
        switch self {
        case .notInitialized, .configurationError:
            return .configuration
        case .networkUnavailable, .socketConnectionFailed:
            return .network
        case .platformUnavailable, .opacitySDKRequired, .googleSignInFailed:
            return .authentication
        case .invalidCredentials, .emailVerificationFailed, .invalidEmail, .invalidPIN:
            return .validation
        case .trainingFailed:
            return .training
        case .userCancelled:
            return .userAction
        case .apiError:
            return .api
        case .unknownError:
            return .unknown
        }
    }
}

/// Error category enumeration
public enum ErrorCategory: String {
    case configuration = "configuration"
    case network = "network"
    case authentication = "authentication"
    case validation = "validation"
    case training = "training"
    case userAction = "user_action"
    case api = "api"
    case unknown = "unknown"
}

/// Error reporting protocol
public protocol ErrorReporting {
    func reportError(_ error: OnairosError, context: [String: Any]?)
}

/// Default error reporter (can be replaced with custom implementation)
public class DefaultErrorReporter: ErrorReporting {
    public func reportError(_ error: OnairosError, context: [String: Any]?) {
        // Default implementation - log to console
        print("OnairosSDK Error: \(error.localizedDescription)")
        if let context = context {
            print("Context: \(context)")
        }
    }
}

/// Error handling utilities
public extension OnairosError {
    /// Create error from HTTP response
    static func fromHTTPResponse(data: Data?, response: URLResponse?, error: Error?) -> OnairosError {
        if let error = error {
            if (error as NSError).domain == NSURLErrorDomain {
                return .networkUnavailable
            }
            return .unknownError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .unknownError("Invalid response")
        }
        
        let statusCode = httpResponse.statusCode
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return .apiError(message, statusCode)
        }
        
        switch statusCode {
        case 400:
            return .apiError("Bad request", statusCode)
        case 401:
            return .invalidCredentials
        case 403:
            return .apiError("Forbidden", statusCode)
        case 404:
            return .apiError("Not found", statusCode)
        case 429:
            return .apiError("Too many requests", statusCode)
        case 500...599:
            return .apiError("Server error", statusCode)
        default:
            return .apiError("HTTP error", statusCode)
        }
    }
    
    /// Create error from platform authentication failure
    static func platformAuthError(platform: Platform, reason: String) -> OnairosError {
        switch platform.authMethod {
        case .opacitySDK:
            return .opacitySDKRequired
        case .nativeSDK:
            return .googleSignInFailed(reason)
        case .oauth:
            return .platformUnavailable(platform.displayName)
        }
    }
} 