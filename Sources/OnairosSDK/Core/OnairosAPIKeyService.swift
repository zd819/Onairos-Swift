import Foundation

/// API Key service for SDK authentication
public class OnairosAPIKeyService {
    
    /// Admin API key for testing
    public static let ADMIN_API_KEY = "OnairosIsAUnicorn2025"
    
    /// Shared instance
    public static let shared = OnairosAPIKeyService()
    
    /// Current configuration
    private var config: OnairosConfig?
    
    /// Initialization status
    private var isInitialized = false
    
    /// Private initializer
    private init() {}
    
    /// Initialize SDK with API key
    /// - Parameter config: SDK configuration
    /// - Throws: OnairosError if initialization fails
    public func initializeApiKey(config: OnairosConfig) async throws {
        log("🔑 Initializing SDK with API key...", level: .info)
        
        self.config = config
        
        // Validate API key with backend
        let validation = try await validateApiKey(config.apiKey)
        guard validation.isValid else {
            let error = OnairosError.invalidAPIKey(validation.error ?? "API key validation failed")
            log("❌ API key validation failed: \(validation.error ?? "Unknown error")", level: .error)
            throw error
        }
        
        self.isInitialized = true
        log("✅ SDK initialized successfully with API key", level: .info)
        log("   Environment: \(config.environment.displayName)", level: .info)
        log("   Base URL: \(config.environment.baseURL)", level: .info)
        log("   Key Type: \(isAdminKey(config.apiKey) ? "Admin" : "Developer")", level: .info)
    }
    
    /// Get authentication headers for API requests
    /// - Returns: Dictionary of authentication headers
    /// - Throws: OnairosError if SDK not initialized
    public func getAuthHeaders() throws -> [String: String] {
        guard let config = config else {
            throw OnairosError.notInitialized("SDK not initialized. Call initializeApiKey() first.")
        }
        
        return [
            "Authorization": "Bearer \(config.apiKey)",
            "Content-Type": "application/json",
            "User-Agent": "OnairosSwift/3.0.72",
            "X-SDK-Version": "3.0.72",
            "X-SDK-Environment": config.environment == .production ? "production" : "development",
            "X-API-Key-Type": isAdminKey(config.apiKey) ? "admin" : "developer",
            "X-Timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Make authenticated HTTP request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Request body data
    /// - Returns: Tuple of response data and HTTP response
    /// - Throws: OnairosError if request fails
    public func makeAuthenticatedRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let config = config else {
            throw OnairosError.notInitialized("SDK not initialized")
        }
        
        guard let url = URL(string: "\(config.environment.baseURL)\(endpoint)") else {
            throw OnairosError.configurationError("Invalid URL: \(config.environment.baseURL)\(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = config.timeout
        
        // Add authentication headers
        let headers = try getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        log("📤 Making authenticated request to: \(endpoint)", level: .debug)
        log("   Method: \(method)", level: .debug)
        log("   Headers: \(headers)", level: .verbose)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OnairosError.networkError("Invalid response type")
            }
            
            log("📥 Response received: \(httpResponse.statusCode)", level: .debug)
            
            return (data, httpResponse)
            
        } catch {
            log("❌ Request failed: \(error.localizedDescription)", level: .error)
            throw OnairosError.networkError(error.localizedDescription)
        }
    }
    
    /// Check if API key is admin key
    /// - Parameter key: API key to check
    /// - Returns: True if admin key
    private func isAdminKey(_ key: String) -> Bool {
        return key == Self.ADMIN_API_KEY
    }
    
    /// Check if API key matches developer key format
    /// - Parameter key: API key to check
    /// - Returns: True if valid developer key format
    private func isDeveloperKeyFormat(_ key: String) -> Bool {
        guard key.count >= 32 else { return false }
        return key.hasPrefix("ona_") || key.hasPrefix("dev_") || key.hasPrefix("pk_")
    }
    
    /// Validate API key with backend
    /// - Parameter apiKey: API key to validate
    /// - Returns: Validation result
    /// - Throws: OnairosError if validation fails
    private func validateApiKey(_ apiKey: String) async throws -> ValidationResult {
        // Admin key is always valid
        if isAdminKey(apiKey) {
            log("🔑 Using admin API key - validation skipped", level: .info)
            return ValidationResult(isValid: true, error: nil)
        }
        
        // Check developer key format
        if !isDeveloperKeyFormat(apiKey) {
            log("❌ Invalid developer key format", level: .error)
            return ValidationResult(isValid: false, error: "Invalid API key format. Developer keys must be 32+ characters starting with 'ona_', 'dev_', or 'pk_'")
        }
        
        // For developer keys, validate with backend
        log("🔑 Validating developer API key with backend...", level: .info)
        
        do {
            guard let config = config else {
                return ValidationResult(isValid: false, error: "Configuration not available")
            }
            
            let validationURL = URL(string: "\(config.environment.baseURL)/validate-api-key")!
            var request = URLRequest(url: validationURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("OnairosSwift/3.0.72", forHTTPHeaderField: "User-Agent")
            request.setValue("3.0.72", forHTTPHeaderField: "X-SDK-Version")
            request.setValue(config.environment == .production ? "production" : "development", forHTTPHeaderField: "X-SDK-Environment")
            request.setValue("developer", forHTTPHeaderField: "X-API-Key-Type")
            request.setValue(ISO8601DateFormatter().string(from: Date()), forHTTPHeaderField: "X-Timestamp")
            
            let body = ["apiKey": apiKey]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return ValidationResult(isValid: false, error: "Invalid response")
            }
            
            if httpResponse.statusCode == 200 {
                log("✅ Developer API key validated successfully", level: .info)
                return ValidationResult(isValid: true, error: nil)
            } else if httpResponse.statusCode == 429 {
                log("⚠️ Rate limit exceeded during API key validation", level: .error)
                return ValidationResult(isValid: false, error: "Rate limit exceeded. Please wait before validating again.")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Validation failed"
                log("❌ Developer API key validation failed: \(errorMessage)", level: .error)
                return ValidationResult(isValid: false, error: errorMessage)
            }
            
        } catch {
            log("❌ API key validation error: \(error.localizedDescription)", level: .error)
            return ValidationResult(isValid: false, error: error.localizedDescription)
        }
    }
    
    /// Log message with level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    private func log(_ message: String, level: LogLevel) {
        guard let config = config, config.enableLogging else { return }
        
        let prefix: String
        switch level {
        case .error:
            prefix = "❌ [OnairosAPIKey ERROR]"
        case .info:
            prefix = "ℹ️ [OnairosAPIKey INFO]"
        case .debug:
            prefix = "🐛 [OnairosAPIKey DEBUG]"
        case .verbose:
            prefix = "📝 [OnairosAPIKey VERBOSE]"
        }
        
        print("\(prefix) \(message)")
    }
    
    /// Log levels for API key service
    private enum LogLevel {
        case error
        case info
        case debug
        case verbose
    }
    
    /// Get current environment configuration
    /// - Returns: Current environment, or nil if not initialized
    public var currentEnvironment: SDKEnvironment? {
        return config?.environment
    }
    
    /// Get current base URL
    /// - Returns: Current base URL, or nil if not initialized
    public var currentBaseURL: String? {
        return config?.environment.baseURL
    }
    
    /// Check if SDK is initialized
    /// - Returns: True if initialized
    public var isSDKInitialized: Bool {
        return isInitialized
    }
}

// MARK: - OnairosError Extensions

extension OnairosError {
    /// Invalid API key error
    public static func invalidAPIKey(_ message: String) -> OnairosError {
        return .authenticationFailed("Invalid API key: \(message)")
    }
    
    /// SDK not initialized error
    public static func notInitialized(_ message: String) -> OnairosError {
        return .configurationError("SDK not initialized: \(message)")
    }
} 