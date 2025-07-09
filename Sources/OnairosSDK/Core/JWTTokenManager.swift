import Foundation
import Security

/// JWT token manager for secure storage and retrieval
public class JWTTokenManager {
    
    /// Shared instance
    public static let shared = JWTTokenManager()
    
    /// Keychain service identifier
    private let service = "uk.onairos.sdk.jwt"
    
    /// Account identifier for JWT token
    private let account = "onairos_jwt_token"
    
    /// Current JWT token (cached in memory)
    private var currentToken: String?
    
    /// Private initializer for singleton
    private init() {
        // Load existing token from keychain on initialization
        self.currentToken = retrieveTokenFromKeychain()
    }
    
    // MARK: - Public Methods
    
    /// Store JWT token securely in keychain
    /// - Parameter token: JWT token to store
    /// - Returns: True if storage was successful
    public func storeJWTToken(_ token: String) -> Bool {
        guard !token.isEmpty else {
            print("🚨 [JWTTokenManager] Cannot store empty token")
            return false
        }
        
        print("🔐 [JWTTokenManager] Storing JWT token securely")
        
        // Clear any existing token first
        _ = clearJWTToken()
        
        // Prepare token data
        guard let tokenData = token.data(using: .utf8) else {
            print("🚨 [JWTTokenManager] Failed to encode token data")
            return false
        }
        
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            print("✅ [JWTTokenManager] JWT token stored successfully")
            self.currentToken = token
            return true
        case errSecDuplicateItem:
            print("🚨 [JWTTokenManager] Token already exists in keychain")
            return false
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [JWTTokenManager] Failed to store token: \(errorMessage)")
            return false
        }
    }
    
    /// Retrieve JWT token from keychain
    /// - Returns: JWT token if available
    public func getJWTToken() -> String? {
        // Return cached token if available
        if let cachedToken = currentToken {
            return cachedToken
        }
        
        // Try to load from keychain
        if let token = retrieveTokenFromKeychain() {
            self.currentToken = token
            return token
        }
        
        return nil
    }
    
    /// Check if JWT token is stored
    /// - Returns: True if token exists
    public func hasJWTToken() -> Bool {
        return getJWTToken() != nil
    }
    
    /// Clear JWT token from keychain and memory
    /// - Returns: True if clearing was successful
    public func clearJWTToken() -> Bool {
        print("🔄 [JWTTokenManager] Clearing JWT token")
        
        // Clear from memory
        self.currentToken = nil
        
        // Clear from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("✅ [JWTTokenManager] JWT token cleared successfully")
            return true
        case errSecItemNotFound:
            print("ℹ️ [JWTTokenManager] No JWT token found to clear")
            return true // Consider this success
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [JWTTokenManager] Failed to clear token: \(errorMessage)")
            return false
        }
    }
    
    /// Check if JWT token is expired (requires decoding)
    /// - Returns: True if token is expired, nil if cannot determine
    public func isTokenExpired() -> Bool? {
        guard let token = getJWTToken() else {
            return nil
        }
        
        // JWT tokens have 3 parts separated by dots
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            print("🚨 [JWTTokenManager] Invalid JWT token format")
            return nil
        }
        
        // Decode the payload (middle part)
        let payload = parts[1]
        
        // Add padding if needed for base64 decoding
        var paddedPayload = payload
        while paddedPayload.count % 4 != 0 {
            paddedPayload += "="
        }
        
        guard let payloadData = Data(base64Encoded: paddedPayload),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            print("🚨 [JWTTokenManager] Failed to decode JWT payload")
            return nil
        }
        
        // Check if token is expired
        let currentTime = Date().timeIntervalSince1970
        let isExpired = currentTime >= exp
        
        if isExpired {
            print("⚠️ [JWTTokenManager] JWT token is expired")
        }
        
        return isExpired
    }
    
    /// Get user information from JWT token (if available)
    /// - Returns: Dictionary containing user info from JWT payload
    public func getUserInfoFromToken() -> [String: Any]? {
        guard let token = getJWTToken() else {
            return nil
        }
        
        // JWT tokens have 3 parts separated by dots
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            print("🚨 [JWTTokenManager] Invalid JWT token format")
            return nil
        }
        
        // Decode the payload (middle part)
        let payload = parts[1]
        
        // Add padding if needed for base64 decoding
        var paddedPayload = payload
        while paddedPayload.count % 4 != 0 {
            paddedPayload += "="
        }
        
        guard let payloadData = Data(base64Encoded: paddedPayload),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            print("🚨 [JWTTokenManager] Failed to decode JWT payload")
            return nil
        }
        
        return json
    }
    
    // MARK: - Private Methods
    
    /// Retrieve token from keychain
    /// - Returns: JWT token if found
    private func retrieveTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                print("🚨 [JWTTokenManager] Failed to decode token data")
                return nil
            }
            return token
        case errSecItemNotFound:
            return nil
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [JWTTokenManager] Failed to retrieve token: \(errorMessage)")
            return nil
        }
    }
}

// MARK: - JWT Token Errors

/// Errors related to JWT token management
public enum JWTTokenError: Error, LocalizedError {
    case tokenNotFound
    case invalidTokenFormat
    case tokenExpired
    case storageError(String)
    case decodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .tokenNotFound:
            return "JWT token not found. Please authenticate first."
        case .invalidTokenFormat:
            return "Invalid JWT token format."
        case .tokenExpired:
            return "JWT token has expired. Please authenticate again."
        case .storageError(let message):
            return "JWT token storage error: \(message)"
        case .decodingError(let message):
            return "JWT token decoding error: \(message)"
        }
    }
} 