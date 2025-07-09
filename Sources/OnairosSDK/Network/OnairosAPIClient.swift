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
    ///   - baseURL: Base URL for API requests (optional, will be overridden by API key service if initialized)
    ///   - logLevel: Logging level for debugging
    ///   - enableDetailedLogging: Whether to log request/response bodies
    public func configure(baseURL: String? = nil, logLevel: APILogLevel = .error, enableDetailedLogging: Bool = false) {
        // Use base URL from API key service if available, otherwise use provided URL
        if let keyService = try? OnairosAPIKeyService.shared.getAuthHeaders() {
            // API key service is initialized, get base URL from it
            // Note: We'll get the actual base URL in the request methods
            log("🔧 OnairosAPIClient using API key service configuration", level: .info)
        } else if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        
        self.logLevel = logLevel
        self.enableDetailedLogging = enableDetailedLogging
        
        log("🔧 OnairosAPIClient configured:", level: .info)
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
        
        let request = EmailVerificationRequest.requestCode(email: email)
        
        let result = await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        )
        
        switch result {
        case .success(let response):
            log("✅ Email verification request successful: \(response.success)", level: .info)
            if let testingMode = response.testingMode {
                log("🧪 Testing mode enabled: \(testingMode)", level: .info)
            }
            if let accountInfo = response.accountInfo {
                log("📋 Account info received: \(accountInfo)", level: .info)
            }
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
        
        let request = EmailVerificationRequest.verifyCode(email: email, code: code)
        
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
            if let testingMode = response.testingMode {
                log("🧪 Testing mode enabled: \(testingMode)", level: .info)
            }
            if let accountInfo = response.accountInfo {
                log("📋 Account info received: \(accountInfo)", level: .info)
            }
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
    public func checkEmailVerificationStatus(email: String) async -> Result<EmailVerificationStatusResponse, OnairosError> {
        return await performRequestWithDictionary(
            endpoint: "/email/verify/status", 
            method: .POST, 
            body: ["email": email], 
            responseType: EmailVerificationStatusResponse.self
        )
    }
    
    /// Request email verification with full response
    /// - Parameter email: Email address to verify
    /// - Returns: Full email verification response including account info
    public func requestEmailVerificationWithResponse(email: String) async -> Result<EmailVerificationResponse, OnairosError> {
        log("🚀 Requesting email verification with full response for: \(email)", level: .info)
        
        let request = EmailVerificationRequest.requestCode(email: email)
        
        return await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        )
    }
    
    /// Verify email with code and get full response
    /// - Parameters:
    ///   - email: Email address
    ///   - code: Verification code
    /// - Returns: Full email verification response including account info
    public func verifyEmailCodeWithResponse(email: String, code: String) async -> Result<EmailVerificationResponse, OnairosError> {
        log("🚀 Verifying email code with full response for: \(email) with code: \(code)", level: .info)
        
        let request = EmailVerificationRequest.verifyCode(email: email, code: code)
        
        return await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        )
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
    
    /// Get authorization URL for platform
    /// - Parameters:
    ///   - platform: Platform to get authorization URL for
    ///   - userEmail: User email for the request
    /// - Returns: Authorization URL response
    public func getAuthorizationURL(platform: Platform, userEmail: String) async -> Result<AuthorizationURLResponse, OnairosError> {
        log("🚀 Requesting authorization URL for platform: \(platform.rawValue)", level: .info)
        
        // Enable detailed logging for debugging
        let originalDetailedLogging = enableDetailedLogging
        enableDetailedLogging = true
        
        // Get the actual username from UserDefaults (saved during email verification)
        let username = UserDefaults.standard.string(forKey: "onairos_username") ?? extractUsername(from: userEmail)
        
        // Build complete OAuth request parameters that the backend expects
        let requestBody: [String: Any] = [
            "response_type": "code",
            "redirect_uri": "onairos://oauth/callback", // Default redirect URI
            "scope": platform.oauthScopes,
            "state": generateStateParameter(),
            "email": userEmail,
            "session": [
                "username": username
            ]
        ]
        
        log("📤 Sending authorization URL request with body: \(requestBody)", level: .debug)
        
        let result = await performRequestWithDictionary(
            endpoint: "/\(platform.rawValue)/authorize",
            method: .POST,
            body: requestBody,
            responseType: AuthorizationURLResponse.self
        )
        
        // Restore original logging setting
        enableDetailedLogging = originalDetailedLogging
        
        return result
    }
    
    /// Generate state parameter for OAuth security
    /// - Returns: Random state string
    private func generateStateParameter() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement() ?? "a" })
    }
    
    /// Extract username from email address
    /// - Parameter email: Full email address
    /// - Returns: Username (part before @)
    private func extractUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? email
    }
    
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
    
    /// Authenticate with platform (with explicit username)
    /// - Parameters:
    ///   - platform: Platform name (e.g., "pinterest", "linkedin")
    ///   - accessToken: OAuth access token
    ///   - refreshToken: OAuth refresh token (optional)
    ///   - authCode: Authorization code (optional)
    ///   - username: Username for session identification
    /// - Returns: Authentication response
    public func authenticatePlatform(
        platform: String,
        accessToken: String,
        refreshToken: String? = nil,
        authCode: String? = nil,
        username: String
    ) async -> Result<PlatformAuthResponse, OnairosError> {
        let request = PlatformAuthRequest(
            platform: platform,
            accessToken: accessToken,
            refreshToken: refreshToken,
            authCode: authCode,
            username: username
        )
        
        return await authenticatePlatform(request)
    }
    
    /// Authenticate YouTube with native tokens
    /// - Parameters:
    ///   - accessToken: YouTube access token
    ///   - refreshToken: YouTube refresh token
    ///   - idToken: ID token from Google Sign-In
    ///   - username: Optional username for session (if not provided, will use stored username)
    /// - Returns: Authentication response
    public func authenticateYouTube(
        accessToken: String,
        refreshToken: String,
        idToken: String?,
        username: String? = nil
    ) async -> Result<PlatformAuthResponse, OnairosError> {
        let request = PlatformAuthRequest(
            platform: "youtube",
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            username: username
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
    
    /// Test the API client connection (for debugging)
    /// - Returns: Simple test response
    public func testConnection() async -> Result<[String: Any], OnairosError> {
        log("🧪 Testing API connection", level: .info)
        
        // Enable detailed logging for debugging
        let originalDetailedLogging = enableDetailedLogging
        enableDetailedLogging = true
        
        let result = await performRequestWithoutBody(
            endpoint: "/health",
            method: .GET,
            responseType: [String: AnyCodable].self
        ).map { response in
            response.mapValues { $0.value }
        }
        
        // Restore original logging setting
        enableDetailedLogging = originalDetailedLogging
        
        return result
    }
    
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
        
        // Try to get URL and headers from API key service first
        let (requestURL, requestHeaders) = getRequestURLAndHeaders(endpoint: endpoint)
        
        guard let url = requestURL else {
            let error = OnairosError.configurationError("Invalid URL configuration")
            log("❌ Invalid URL configuration for endpoint: \(endpoint)", level: .error)
            return .failure(error)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers (from API key service or default)
        for (key, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
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
            
            // Check for HTTP errors and get status code
            var statusCode: Int = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                guard 200...299 ~= httpResponse.statusCode else {
                    // Handle rate limiting specifically
                    if httpResponse.statusCode == 429 {
                        log("⚠️ Rate limit exceeded", level: .error)
                        return .failure(.rateLimitExceeded("Rate limit exceeded. Please wait before making more requests."))
                    }
                    
                    let error = OnairosError.fromHTTPResponse(data: data, response: response, error: nil)
                    log("❌ HTTP error \(httpResponse.statusCode): \(error.localizedDescription)", level: .error)
                    return .failure(error)
                }
                log("✅ HTTP request successful (\(httpResponse.statusCode))", level: .info)
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                
                // Try to decode as unified response format first
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = jsonObject["success"] as? Bool {
                    
                    if success {
                        // Success response - decode the expected type
                        let result = try decoder.decode(responseType, from: data)
                        log("✅ Response decoded successfully", level: .debug)
                        return .success(result)
                    } else {
                        // Error response - extract error information
                        let errorMessage = jsonObject["error"] as? String ?? "Unknown error"
                        let errorCode = jsonObject["code"] as? String
                        log("❌ API returned error: \(errorMessage)", level: .error)
                        
                        if let errorCode = errorCode {
                            return .failure(.apiError("\(errorMessage) (Code: \(errorCode))", statusCode))
                        } else {
                            return .failure(.apiError(errorMessage, statusCode))
                        }
                    }
                } else {
                    // Fallback to direct decoding for legacy responses
                    let result = try decoder.decode(responseType, from: data)
                    log("✅ Response decoded successfully (legacy format)", level: .debug)
                    return .success(result)
                }
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
        request.setValue("OnairosSwift/3.0.72", forHTTPHeaderField: "User-Agent")
        request.setValue("3.0.72", forHTTPHeaderField: "X-SDK-Version")
        request.setValue("production", forHTTPHeaderField: "X-SDK-Environment")
        request.setValue("developer", forHTTPHeaderField: "X-API-Key-Type")
        request.setValue(ISO8601DateFormatter().string(from: Date()), forHTTPHeaderField: "X-Timestamp")
        
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
        
        log("🚀 Starting dictionary request to \(endpoint)", level: .info)
        
        // Try to get URL and headers from API key service first
        let (requestURL, requestHeaders) = getRequestURLAndHeaders(endpoint: endpoint)
        
        guard let url = requestURL else {
            let error = OnairosError.configurationError("Invalid URL configuration")
            log("❌ Invalid URL configuration for endpoint: \(endpoint)", level: .error)
            return .failure(error)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers (from API key service or default)
        for (key, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add request body
        var requestBodyData: Data?
        do {
            requestBodyData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = requestBodyData
            log("✅ Request body encoded successfully", level: .debug)
        } catch {
            let errorMsg = "Failed to encode request body: \(error.localizedDescription)"
            log("❌ \(errorMsg)", level: .error)
            return .failure(.unknownError(errorMsg))
        }
        
        // Log request details
        logRequest(request, body: requestBodyData)
        
        // Perform request
        do {
            log("⏳ Sending HTTP request...", level: .debug)
            let (data, response) = try await session.data(for: request)
            
            // Log response details
            logResponse(response, data: data, error: nil)
            
            // Check for HTTP errors and get status code
            var statusCode: Int = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                guard 200...299 ~= httpResponse.statusCode else {
                    // Handle rate limiting specifically
                    if httpResponse.statusCode == 429 {
                        log("⚠️ Rate limit exceeded", level: .error)
                        return .failure(.rateLimitExceeded("Rate limit exceeded. Please wait before making more requests."))
                    }
                    
                    let error = OnairosError.fromHTTPResponse(data: data, response: response, error: nil)
                    log("❌ HTTP error \(httpResponse.statusCode): \(error.localizedDescription)", level: .error)
                    return .failure(error)
                }
                log("✅ HTTP request successful (\(httpResponse.statusCode))", level: .info)
            }
            
            // Check if we have any data
            guard !data.isEmpty else {
                log("❌ Empty response data received", level: .error)
                return .failure(.unknownError("Empty response data"))
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                log("📥 Raw response: \(responseString)", level: .debug)
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                
                // Try to decode as unified response format first
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = jsonObject["success"] as? Bool {
                    
                    if success {
                        // Success response - decode the expected type
                        let result = try decoder.decode(responseType, from: data)
                        log("✅ Response decoded successfully", level: .debug)
                        return .success(result)
                    } else {
                        // Error response - extract error information
                        let errorMessage = jsonObject["error"] as? String ?? "Unknown error"
                        let errorCode = jsonObject["code"] as? String
                        log("❌ API returned error: \(errorMessage)", level: .error)
                        
                        if let errorCode = errorCode {
                            return .failure(.apiError("\(errorMessage) (Code: \(errorCode))", statusCode))
                        } else {
                            return .failure(.apiError(errorMessage, statusCode))
                        }
                    }
                } else {
                    // Fallback to direct decoding for legacy responses
                    let result = try decoder.decode(responseType, from: data)
                    log("✅ Response decoded successfully (legacy format)", level: .debug)
                    return .success(result)
                }
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
    
    /// Submit PIN to backend endpoint with retry mechanism
    /// - Parameter request: PIN submission request with username and pin
    /// - Returns: Result with PIN submission response
    public func submitPIN(_ request: PINSubmissionRequest) async -> Result<PINSubmissionResponse, OnairosError> {
        log("📤 Submitting PIN to backend for user: \(request.username)", level: .info)
        
        // Retry configuration for PIN submission
        let maxRetries = 3
        let retryDelay: TimeInterval = 2.0
        
        for attempt in 1...maxRetries {
            log("🔄 PIN submission attempt \(attempt)/\(maxRetries)", level: .info)
            
            // Create a longer timeout specifically for PIN submission
            let result = await performPINSubmissionWithTimeout(request)
            
            switch result {
            case .success(let response):
                log("✅ PIN submission successful on attempt \(attempt)", level: .info)
                return .success(response)
                
            case .failure(let error):
                log("❌ PIN submission failed on attempt \(attempt): \(error.localizedDescription)", level: .error)
                
                // Don't retry for certain errors
                if shouldRetryPINSubmission(error: error) && attempt < maxRetries {
                    log("⏳ Retrying PIN submission in \(retryDelay) seconds...", level: .info)
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                } else {
                    // Final failure or non-retryable error
                    let enhancedError = enhancePINSubmissionError(error, attempt: attempt)
                    log("💥 PIN submission failed permanently: \(enhancedError.localizedDescription)", level: .error)
                    return .failure(enhancedError)
                }
            }
        }
        
        // This should never be reached, but just in case
        return .failure(.unknownError("PIN submission failed after \(maxRetries) attempts"))
    }
    
    /// Perform PIN submission with extended timeout
    /// - Parameter request: PIN submission request
    /// - Returns: Result with PIN submission response
    private func performPINSubmissionWithTimeout(_ request: PINSubmissionRequest) async -> Result<PINSubmissionResponse, OnairosError> {
        // Create a custom session with longer timeout for PIN submission
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0  // 60 seconds for PIN submission
        config.timeoutIntervalForResource = 120.0  // 2 minutes total resource timeout
        let pinSession = URLSession(configuration: config)
        
        log("⏱️ Using extended timeout for PIN submission (60s request, 120s resource)", level: .debug)
        
        // Get URL and headers
        let (requestURL, requestHeaders) = getRequestURLAndHeaders(endpoint: "/store-pin/mobile")
        
        guard let url = requestURL else {
            let error = OnairosError.configurationError("Invalid URL configuration for PIN submission")
            log("❌ Invalid URL configuration for PIN endpoint", level: .error)
            return .failure(error)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // Add headers
        for (key, value) in requestHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Encode request body
        var requestBodyData: Data?
        do {
            requestBodyData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestBodyData
            log("✅ PIN request body encoded successfully", level: .debug)
        } catch {
            let errorMsg = "Failed to encode PIN request body: \(error.localizedDescription)"
            log("❌ \(errorMsg)", level: .error)
            return .failure(.unknownError(errorMsg))
        }
        
        // Log request details
        logRequest(urlRequest, body: requestBodyData)
        
        // Perform request with timeout protection
        do {
            log("⏳ Sending PIN submission request with extended timeout...", level: .info)
            let (data, response) = try await pinSession.data(for: urlRequest)
            
            // Log response details
            logResponse(response, data: data, error: nil)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                guard 200...299 ~= statusCode else {
                    log("❌ PIN submission HTTP error: \(statusCode)", level: .error)
                    
                    // Handle specific status codes
                    switch statusCode {
                    case 400:
                        return .failure(.validationFailed("Invalid PIN format or missing data"))
                    case 401:
                        return .failure(.invalidCredentials)
                    case 404:
                        return .failure(.apiError("User not found", statusCode))
                    case 429:
                        return .failure(.rateLimitExceeded("Too many PIN submission attempts"))
                    case 500...599:
                        return .failure(.serverError(statusCode, "Server error during PIN storage"))
                    default:
                        return .failure(.apiError("HTTP error \(statusCode)", statusCode))
                    }
                }
                
                log("✅ PIN submission HTTP request successful (\(statusCode))", level: .info)
            }
            
            // Check if we have response data
            guard !data.isEmpty else {
                log("❌ Empty response data from PIN submission", level: .error)
                return .failure(.unknownError("Empty response from PIN submission"))
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                log("📥 PIN submission raw response: \(responseString)", level: .debug)
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PINSubmissionResponse.self, from: data)
                
                // Validate response
                if response.success {
                    log("✅ PIN submission response decoded successfully", level: .info)
                    return .success(response)
                } else {
                    let errorMessage = response.message.isEmpty ? "PIN submission failed" : response.message
                    log("❌ PIN submission failed: \(errorMessage)", level: .error)
                    return .failure(.apiError(errorMessage, nil))
                }
                
            } catch {
                let errorMsg = "Failed to decode PIN submission response: \(error.localizedDescription)"
                log("❌ \(errorMsg)", level: .error)
                if enableDetailedLogging, let dataString = String(data: data, encoding: .utf8) {
                    log("   Raw response: \(dataString)", level: .error)
                }
                return .failure(.unknownError(errorMsg))
            }
            
        } catch {
            let onairosError = OnairosError.fromHTTPResponse(data: nil, response: nil, error: error)
            log("❌ PIN submission network request failed: \(error.localizedDescription)", level: .error)
            
            // Check if it's a timeout error
            if (error as NSError).code == NSURLErrorTimedOut {
                log("⏰ PIN submission timed out", level: .error)
                return .failure(.networkError("PIN submission timed out. Please check your connection and try again."))
            }
            
            return .failure(onairosError)
        }
    }
    
    /// Determine if PIN submission should be retried based on error type
    /// - Parameter error: The error that occurred
    /// - Returns: True if should retry, false otherwise
    private func shouldRetryPINSubmission(error: OnairosError) -> Bool {
        switch error {
        case .networkUnavailable, .networkError:
            return true  // Retry network issues
        case .serverError(let code, _):
            return code >= 500  // Retry server errors
        case .rateLimitExceeded:
            return true  // Retry rate limits after delay
        case .unknownError(let message):
            return message.contains("timeout") || message.contains("connection")  // Retry timeouts
        default:
            return false  // Don't retry validation errors, auth errors, etc.
        }
    }
    
    /// Enhance PIN submission error with additional context
    /// - Parameters:
    ///   - error: Original error
    ///   - attempt: Attempt number
    /// - Returns: Enhanced error with better messaging
    private func enhancePINSubmissionError(_ error: OnairosError, attempt: Int) -> OnairosError {
        switch error {
        case .networkError(let message):
            return .networkError("PIN submission failed after \(attempt) attempts: \(message)")
        case .serverError(let code, let message):
            return .serverError(code, "PIN submission server error (attempt \(attempt)): \(message)")
        case .unknownError(let message):
            return .unknownError("PIN submission failed after \(attempt) attempts: \(message)")
        default:
            return error  // Return original error for other types
        }
    }
    

    
    /// Get request URL and headers, preferring API key service if available
    /// - Parameter endpoint: API endpoint
    /// - Returns: Tuple of URL and headers
    private func getRequestURLAndHeaders(endpoint: String) -> (URL?, [String: String]) {
        let apiKeyService = OnairosAPIKeyService.shared
        
        // Try to use API key service first
        if apiKeyService.isSDKInitialized,
           let authHeaders = try? apiKeyService.getAuthHeaders(),
           let baseURL = apiKeyService.currentBaseURL {
            
            log("🔑 Using API key service for authentication", level: .debug)
            let url = URL(string: baseURL + endpoint)
            return (url, authHeaders)
        }
        
        // Fallback to legacy configuration
        log("🔄 Using legacy configuration (no API key service)", level: .debug)
        let fallbackHeaders = [
            "Content-Type": "application/json",
            "User-Agent": "OnairosSwift/3.0.72",
            "X-SDK-Version": "3.0.72",
            "X-SDK-Environment": "production",
            "X-API-Key-Type": "developer",
            "X-Timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        let url = URL(string: baseURL + endpoint)
        return (url, fallbackHeaders)
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