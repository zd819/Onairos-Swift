import Foundation

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
    
    /// Private initializer
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Configure the API client
    /// - Parameter baseURL: Base URL for API requests
    public func configure(baseURL: String) {
        self.baseURL = baseURL
    }
    
    // MARK: - Email Verification
    
    /// Request email verification
    /// - Parameter email: Email address to verify
    /// - Returns: Success status
    public func requestEmailVerification(email: String) async -> Result<Bool, OnairosError> {
        let request = EmailVerificationRequest(email: email)
        
        return await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        ).map { response in
            response.success
        }
    }
    
    /// Verify email with code
    /// - Parameters:
    ///   - email: Email address
    ///   - code: Verification code
    /// - Returns: Verification success status
    public func verifyEmailCode(email: String, code: String) async -> Result<Bool, OnairosError> {
        let request = EmailVerificationRequest(email: email, action: "verify", code: code)
        
        return await performRequest(
            endpoint: "/email/verification",
            method: .POST,
            body: request,
            responseType: EmailVerificationResponse.self
        ).map { response in
            response.verified ?? false
        }
    }
    
    /// Check email verification status
    /// - Parameter email: Email address
    /// - Returns: Verification status
    public func checkEmailVerificationStatus(email: String) async -> Result<Bool, OnairosError> {
        return await performRequest(
            endpoint: "/email/verification/status/\(email)",
            method: .GET,
            responseType: EmailVerificationResponse.self
        ).map { response in
            response.verified ?? false
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
        
        return await performRequest(
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
        
        return await performRequest(
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
        
        return await performRequest(
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
        return await performRequest(
            endpoint: "/health",
            method: .GET,
            responseType: [String: AnyCodable].self
        ).map { response in
            response["status"]?.value as? String == "ok"
        }
    }
    
    // MARK: - Generic Request Handler
    
    /// Perform HTTP request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - body: Request body (optional)
    ///   - responseType: Expected response type
    /// - Returns: Decoded response or error
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        responseType: U.Type
    ) async -> Result<U, OnairosError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.configurationError("Invalid URL: \(baseURL + endpoint)"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OnairosSDK/1.0 iOS", forHTTPHeaderField: "User-Agent")
        
        // Add request body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.unknownError("Failed to encode request body: \(error.localizedDescription)"))
            }
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
    
    /// Perform request with dictionary body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - body: Dictionary body
    ///   - responseType: Expected response type
    /// - Returns: Decoded response or error
    private func performRequest<U: Codable>(
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