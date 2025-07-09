import Foundation
import Security
import LocalAuthentication

// Security framework constants that might not be available in all Swift versions
private let errSecUserCancel: OSStatus = -128

/// Manager for secure PIN storage with biometric authentication
public class BiometricPINManager {
    
    /// Shared singleton instance
    public static let shared = BiometricPINManager()
    
    /// Keychain service identifier
    private let service = "com.onairos.sdk.pin"
    
    /// Keychain account identifier
    private let account = "user_pin"
    
    /// Access control for biometric authentication
    private var accessControl: SecAccessControl? {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            &error
        )
        
        if let error = error?.takeRetainedValue() {
            print("🚨 [BiometricPINManager] Error creating access control: \(error)")
            return nil
        }
        
        return accessControl
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Store PIN securely with biometric authentication
    /// - Parameter pin: PIN to store
    /// - Returns: Success/failure result
    public func storePIN(_ pin: String) async -> Result<Void, BiometricPINError> {
        guard !pin.isEmpty else {
            return .failure(.invalidPIN)
        }
        
        print("🔐 [BiometricPINManager] Starting PIN storage with biometric authentication")
        
        // Check biometric availability
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("🚨 [BiometricPINManager] Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return .failure(.biometricNotAvailable)
        }
        
        // Request biometric authentication
        do {
            print("🔐 [BiometricPINManager] Requesting Face ID authentication...")
            
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to securely store your PIN"
            )
            
            guard success else {
                return .failure(.authenticationFailed)
            }
            
            print("✅ [BiometricPINManager] Face ID authentication successful")
            
        } catch {
            print("🚨 [BiometricPINManager] Face ID authentication failed: \(error.localizedDescription)")
            return .failure(.authenticationFailed)
        }
        
        // Store PIN in Keychain with biometric protection
        guard let accessControl = accessControl else {
            return .failure(.keychainError("Failed to create access control"))
        }
        
        let pinData = pin.data(using: .utf8) ?? Data()
        
        // Delete any existing PIN first
        _ = deletePIN()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: pinData,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            print("✅ [BiometricPINManager] PIN stored successfully")
            return .success(())
        case errSecDuplicateItem:
            return .failure(.keychainError("PIN already exists"))
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [BiometricPINManager] Keychain storage failed: \(errorMessage)")
            return .failure(.keychainError(errorMessage))
        }
    }
    
    /// Retrieve PIN with biometric authentication
    /// - Returns: Retrieved PIN or error
    public func retrievePIN() async -> Result<String, BiometricPINError> {
        let context = LAContext()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        // Request biometric authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your stored PIN"
            )
            
            guard success else {
                return .failure(.authenticationFailed)
            }
        } catch {
            print("🚨 [BiometricPINManager] Face ID authentication failed: \(error.localizedDescription)")
            return .failure(.authenticationFailed)
        }
        
        // Retrieve PIN from Keychain
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let pin = String(data: data, encoding: .utf8) else {
                return .failure(.keychainError("Failed to decode PIN data"))
            }
            print("✅ [BiometricPINManager] PIN retrieved successfully")
            return .success(pin)
        case errSecItemNotFound:
            return .failure(.pinNotFound)
        case errSecUserCancel:
            return .failure(.authenticationCancelled)
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [BiometricPINManager] Keychain retrieval failed: \(errorMessage)")
            return .failure(.keychainError(errorMessage))
        }
    }
    
    /// Delete stored PIN
    /// - Returns: Success/failure result
    public func deletePIN() -> Result<Void, BiometricPINError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("✅ [BiometricPINManager] PIN deleted successfully")
            return .success(())
        case errSecItemNotFound:
            // PIN doesn't exist, which is fine
            return .success(())
        default:
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown keychain error"
            print("🚨 [BiometricPINManager] Keychain deletion failed: \(errorMessage)")
            return .failure(.keychainError(errorMessage))
        }
    }
    
    /// Check if PIN exists in secure storage
    /// - Returns: True if PIN exists, false otherwise
    public func hasPIN() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Check if biometric authentication is available
    /// - Returns: Biometric availability status
    public func biometricAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                switch error.code {
                case LAError.biometryNotAvailable.rawValue:
                    return .notAvailable
                case LAError.biometryNotEnrolled.rawValue:
                    return .notEnrolled
                case LAError.biometryLockout.rawValue:
                    return .lockedOut
                default:
                    return .notAvailable
                }
            }
            return .notAvailable
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .notAvailable
        @unknown default:
            return .unknown
        }
    }
}