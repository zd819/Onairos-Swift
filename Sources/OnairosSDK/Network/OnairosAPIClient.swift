import Foundation

/// API client logging level
public enum APILogLevel: Int {
    case none = 0
    case error = 1
    case info = 2
    case debug = 3
    case verbose = 4
}

/// Main API client for Onairos backend communication
public class OnairosAPIClient {
    
    /// Shared instance
    public static let shared = OnairosAPIClient()
    
    /// Base URL for API requests
    private var baseURL: String = "https://api2.onairos.uk"
    
    /// URL session for network requests
    private let session: URLSession
    
    /// Request timeout interval
    private let timeoutInterval: TimeInterval = 30.0
    
    /// Logging level
    public var logLevel: APILogLevel = .error
    
    /// Enable detailed logging (includes request/response bodies)
    public var enableDetailedLogging: Bool = false
    
    /// Private initializer
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Configure the API client
    /// - Parameters:
    ///   - baseURL: Base URL for API requests
    ///   - logLevel: Logging level for debugging
    ///   - enableDetailedLogging: Whether to log request/response bodies
    public func configure(baseURL: String, logLevel: APILogLevel = .error, enableDetailedLogging: Bool = false) {
        self.baseURL = baseURL
        self.logLevel = logLevel
        self.enableDetailedLogging = enableDetailedLogging
        
        log("🔧 OnairosAPIClient configured:", level: .info)
        log("   Base URL: \(baseURL)", level: .info)
        log("   Log Level: \(logLevel)", level: .info)
        log("   Detailed Logging: \(enableDetailedLogging)", level: .info)
    }
    
    // MARK: - Logging
    
    /// Log message with level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    private func log(_ message: String, level: APILogLevel) {
        guard level.rawValue <= logLevel.rawValue else { return }
        
        let prefix: String
        switch level {
        case .none:
            return
        case .error:
            prefix = "❌ [OnairosAPI ERROR]"
        case .info:
            prefix = "ℹ️ [OnairosAPI INFO]"
        case .debug:
            prefix = "🐛 [OnairosAPI DEBUG]"
        case .verbose:
            prefix = "📝 [OnairosAPI VERBOSE]"
        }
        
        print("\(prefix) \(message)")
    }
    
    /// Log request details
    /// - Parameters:
    ///   - request: URL request
    ///   - body: Request body data
    private func logRequest(_ request: URLRequest, body: Data?) {
        log("📤 Outgoing Request:", level: .debug)
        log("   URL: \(request.url?.absoluteString ?? "nil")", level: .debug)
        log("   Method: \(request.httpMethod ?? "nil")", level: .debug)
        log("   Headers: \(request.allHTTPHeaderFields ?? [:])", level: .verbose)
        
        if enableDetailedLogging, let body = body {
            if let bodyString = String(data: body, encoding: .utf8) {
                log("   Body: \(bodyString)", level: .verbose)
            } else {
                log("   Body: <binary data \(body.count) bytes>", level: .verbose)
            }
        }
    }
    
    /// Log response details
    /// - Parameters:
    ///   - response: URL response
    ///   - data: Response data
    ///   - error: Error if any
    private func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        if let error = error {
            log("📥 Response Error: \(error.localizedDescription)", level: .error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            log("📥 Invalid Response: Not HTTP response", level: .error)
            return
        }
        
        let statusEmoji = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 ? "✅" : "❌"
        log("📥 \(statusEmoji) Response:", level: .debug)
        log("   Status: \(httpResponse.statusCode)", level: .debug)
        log("   Headers: \(httpResponse.allHeaderFields)", level: .verbose)
        
        if enableDetailedLogging, let data = data {
            if let responseString = String(data: data, encoding: .utf8) {
                log("   Body: \(responseString)", level: .verbose)
            } else {
                log("   Body: <binary data \(data.count) bytes>", level: .verbose)
            }
        }
    }
    
    // MARK: - Email Verification
    
    /// Check if user has existing account
    /// - Returns: True if account exists
    public func checkExistingAccount() async throws -> Bool {
        // For demo purposes, simulate API call
        // In production, this would check against user database
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Return false for now - all users go through onboarding
        // In production: return actual account existence status
        return false
    }
    
    /// Request email verification
    /// - Parameter email: Email address to verify
    /// - Returns: Success status
    public func requestEmailVerification(email: String) async -> Result<Bool, OnairosError> {
        log("🚀 Requesting email verification for: \(email)", level: .info)
        
        let request = EmailVerificationRequest(email: email)
        
        let result = await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        )
        
        switch result {
        case .success(let response):
            log("✅ Email verification request successful: \(response.success)", level: .info)
            return .success(response.success)
        case .failure(let error):
            log("❌ Email verification request failed: \(error.localizedDescription)", level: .error)
            
            // Provide more specific error context for debugging
            let contextualError = enhanceEmailVerificationError(error, operation: "request")
            return .failure(contextualError)
        }
    }
    
    /// Verify email with code
    /// - Parameters:
    ///   - email: Email address
    ///   - code: Verification code
    /// - Returns: Verification success status
    public func verifyEmailCode(email: String, code: String) async -> Result<Bool, OnairosError> {
        log("🚀 Verifying email code for: \(email) with code: \(code)", level: .info)
        
        let request = EmailVerificationRequest(email: email, action: "verify", code: code)
        
        let result = await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        )
        
        switch result {
        case .success(let response):
            let verified = response.verified ?? false
            log("✅ Email verification code check completed: \(verified)", level: .info)
            return .success(verified)
        case .failure(let error):
            log("❌ Email verification code check failed: \(error.localizedDescription)", level: .error)
            
            // Provide more specific error context for debugging
            let contextualError = enhanceEmailVerificationError(error, operation: "verify")
            return .failure(contextualError)
        }
    }
    
    /// Check email verification status
    /// - Parameter email: Email address
    /// - Returns: Verification status
    public func checkEmailVerificationStatus(email: String) async -> Result<Bool, OnairosError> {
        return await performRequestWithoutBody(
            endpoint: "/email/verification/status/\(email)",
            method: .GET,
            responseType: EmailVerificationResponse.self
        ).map { response in
            response.verified ?? false
        }
    }
    
    /// Enhance email verification errors with more context
    /// - Parameters:
    ///   - error: Original error
    ///   - operation: The operation that failed (request/verify)
    /// - Returns: Enhanced error with more context
    private func enhanceEmailVerificationError(_ error: OnairosError, operation: String) -> OnairosError {
        switch error {
        case .networkUnavailable:
            return .emailVerificationFailed("Network connection unavailable. The email \(operation) service cannot be reached.")
        case .apiError(let message, let statusCode):
            if let statusCode = statusCode {
                switch statusCode {
                case 404:
                    return .emailVerificationFailed("Email \(operation) service is temporarily unavailable. Please try again later.")
                case 429:
                    return .emailVerificationFailed("Too many email \(operation) attempts. Please wait a moment before trying again.")
                case 500...599:
                    return .emailVerificationFailed("Email \(operation) service is experiencing issues. Please try again later.")
                default:
                    return .emailVerificationFailed("Email \(operation) failed: \(message)")
                }
            } else {
                return .emailVerificationFailed("Email \(operation) failed: \(message)")
            }
        case .networkError(let reason):
            return .emailVerificationFailed("Network error during email \(operation): \(reason)")
        default:
            return .emailVerificationFailed("Email \(operation) failed due to an unexpected error. Please check your internet connection and try again.")
        }
    }
    
    // MARK: - Platform Authentication
    
    /// Authenticate with platform
    /// - Parameter request: Platform authentication request
    /// - Returns: Authentication response
    public func authenticatePlatform(_ request: PlatformAuthRequest) async -> Result<PlatformAuthResponse, OnairosError> {
        let endpoint = "/\(request.platform)/authorize"
        
        return await performRequest(
            endpoint: endpoint,
            method: .POST,
            body: request,
            responseType: PlatformAuthResponse.self
        )
    }
    
    /// Authenticate YouTube with native tokens
    /// - Parameters:
    ///   - accessToken: YouTube access token
    ///   - refreshToken: YouTube refresh token
    ///   - idToken: ID token from Google Sign-In
    /// - Returns: Authentication response
    public func authenticateYouTube(
        accessToken: String,
        refreshToken: String,
        idToken: String?
    ) async -> Result<PlatformAuthResponse, OnairosError> {
        let request = PlatformAuthRequest(
            platform: "youtube",
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken
        )
        
        return await performRequest(
            endpoint: "/youtube/native-auth",
            method: .POST,
            body: request,
            responseType: PlatformAuthResponse.self
        )
    }
    
    /// Refresh YouTube token
    /// - Parameter refreshToken: Refresh token
    /// - Returns: New access token
    public func refreshYouTubeToken(refreshToken: String) async -> Result<String, OnairosError> {
        let body = ["refresh_token": refreshToken]
        
        return await performRequestWithDictionary(
            endpoint: "/youtube/refresh-token",
            method: .POST,
            body: body,
            responseType: [String: AnyCodable].self
        ).map { response in
            response["access_token"]?.value as? String ?? ""
        }
    }
    
    /// Revoke platform connection
    /// - Parameter platform: Platform to revoke
    /// - Returns: Success status
    public func revokePlatform(_ platform: String) async -> Result<Bool, OnairosError> {
        let body = ["platform": platform]
        
        return await performRequestWithDictionary(
            endpoint: "/revoke",
            method: .POST,
            body: body,
            responseType: [String: AnyCodable].self
        ).map { response in
            response["success"]?.value as? Bool ?? false
        }
    }
    
    // MARK: - User Registration
    
    /// Register user with Enoch system
    /// - Parameter request: User registration request
    /// - Returns: Registration response
    public func registerUser(_ request: UserRegistrationRequest) async -> Result<[String: Any], OnairosError> {
        return await performRequest(
            endpoint: "/register/enoch",
            method: .POST,
            body: request,
            responseType: [String: AnyCodable].self
        ).map { response in
            response.mapValues { $0.value }
        }
    }
    
    // MARK: - AI Training
    
    /// Start AI model training
    /// - Parameters:
    ///   - socketId: Socket.IO connection ID
    ///   - userData: User data for training
    /// - Returns: Training start response
    public func startAITraining(socketId: String, userData: [String: Any]) async -> Result<[String: Any], OnairosError> {
        var body = userData
        body["socket_id"] = socketId
        
        return await performRequestWithDictionary(
            endpoint: "/enoch/trainModel/mobile",
            method: .POST,
            body: body,
            responseType: [String: AnyCodable].self
        ).map { response in
            response.mapValues { $0.value }
        }
    }
    
    // MARK: - Health Check
    
    /// Check API health
    /// - Returns: Health status
    public func healthCheck() async -> Result<Bool, OnairosError> {
        return await performRequestWithoutBody(
            endpoint: "/health",
            method: .GET,
            responseType: [String: AnyCodable].self
        ).map { response in
            response["status"]?.value as? String == "ok"
        }
    }
    
    // MARK: - Generic Request Handler
    
    /// Perform HTTP request with Codable body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - body: Request body (optional)
    ///   - responseType: Expected response type
    /// - Returns: Decoded response or error
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T?,
        responseType: U.Type
    ) async -> Result<U, OnairosError> {
        
        log("🚀 Starting API request to \(endpoint)", level: .info)
        
        guard let url = URL(string: baseURL + endpoint) else {
            let error = OnairosError.configurationError("Invalid URL: \(baseURL + endpoint)")
            log("❌ Invalid URL configuration: \(baseURL + endpoint)", level: .error)
            return .failure(error)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OnairosSDK/1.0 iOS", forHTTPHeaderField: "User-Agent")
        
        var requestBodyData: Data?
        
        // Add request body if provided
        if let body = body {
            do {
                requestBodyData = try JSONEncoder().encode(body)
                request.httpBody = requestBodyData
                log("✅ Request body encoded successfully", level: .debug)
            } catch {
                let errorMsg = "Failed to encode request body: \(error.localizedDescription)"
                log("❌ \(errorMsg)", level: .error)
                return .failure(.unknownError(errorMsg))
            }
        }
        
        // Log request details
        logRequest(request, body: requestBodyData)
        
        // Perform request
        do {
            log("⏳ Sending HTTP request...", level: .debug)
            let (data, response) = try await session.data(for: request)
            
            // Log response details
            logResponse(response, data: data, error: nil)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    let error = OnairosError.fromHTTPResponse(data: data, response: response, error: nil)
                    log("❌ HTTP error \(httpResponse.statusCode): \(error.localizedDescription)", level: .error)
                    return .failure(error)
                }
                log("✅ HTTP request successful (\(httpResponse.statusCode))", level: .info)
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(responseType, from: data)
                log("✅ Response decoded successfully", level: .debug)
                return .success(result)
            } catch {
                let errorMsg = "Failed to decode response: \(error.localizedDescription)"
                log("❌ \(errorMsg)", level: .error)
                if enableDetailedLogging, let dataString = String(data: data, encoding: .utf8) {
                    log("   Raw response: \(dataString)", level: .error)
                }
                return .failure(.unknownError(errorMsg))
            }
            
        } catch {
            let onairosError = OnairosError.fromHTTPResponse(data: nil, response: nil, error: error)
            log("❌ Network request failed: \(error.localizedDescription)", level: .error)
            logResponse(nil, data: nil, error: error)
            return .failure(onairosError)
        }
    }
    
    /// Perform request without body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - responseType: Expected response type
    /// - Returns: Decoded response or error
    private func performRequestWithoutBody<U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        responseType: U.Type
    ) async -> Result<U, OnairosError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.configurationError("Invalid URL: \(baseURL + endpoint)"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OnairosSDK/1.0 iOS", forHTTPHeaderField: "User-Agent")
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    return .failure(OnairosError.fromHTTPResponse(data: data, response: response, error: nil))
                }
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(responseType, from: data)
                return .success(result)
            } catch {
                return .failure(.unknownError("Failed to decode response: \(error.localizedDescription)"))
            }
            
        } catch {
            return .failure(OnairosError.fromHTTPResponse(data: nil, response: nil, error: error))
        }
    }
    
    /// Perform request with dictionary body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - body: Dictionary body
    ///   - responseType: Expected response type
    /// - Returns: Decoded response or error
    private func performRequestWithDictionary<U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: [String: Any],
        responseType: U.Type
    ) async -> Result<U, OnairosError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.configurationError("Invalid URL: \(baseURL + endpoint)"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OnairosSDK/1.0 iOS", forHTTPHeaderField: "User-Agent")
        
        // Add request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure(.unknownError("Failed to encode request body: \(error.localizedDescription)"))
        }
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    return .failure(OnairosError.fromHTTPResponse(data: data, response: response, error: nil))
                }
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(responseType, from: data)
                return .success(result)
            } catch {
                return .failure(.unknownError("Failed to decode response: \(error.localizedDescription)"))
            }
            
        } catch {
            return .failure(OnairosError.fromHTTPResponse(data: nil, response: nil, error: error))
        }
    }
}

/// HTTP method enumeration
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
} 