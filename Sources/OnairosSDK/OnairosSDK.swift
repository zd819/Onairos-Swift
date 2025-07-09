import UIKit
import Foundation
import Combine

/// Main Onairos SDK interface
@MainActor
public class OnairosSDK: ObservableObject {
    
    /// SDK version
    public static let version = "3.0.72"
    
    /// Shared singleton instance
    public static let shared = OnairosSDK()
    
    /// SDK configuration
    private var config: OnairosConfig?
    
    /// Completion callback for onboarding
    private var completionCallback: ((Result<OnboardingResult, OnairosError>) -> Void)?
    
    /// Current modal controller
    private weak var modalController: OnairosModalController?
    
    /// Current onboarding coordinator
    private var coordinator: OnboardingCoordinator?
    
    private init() {}
    
    /// Initialize the SDK with default configuration for testing
    /// This method provides a simple initialization for basic testing scenarios
    public func initialize() {
        let config = OnairosConfig.testMode(
            urlScheme: "onairos-sdk",
            appName: "OnairosSDK"
        )
        initialize(config: config)
    }
    
    /// Initialize the SDK with API key configuration
    /// - Parameter config: API key configuration
    /// - Throws: OnairosError if initialization fails
    public func initializeApiKey(config: OnairosConfig) async throws {
        try await OnairosAPIKeyService.shared.initializeApiKey(config: config)
        
        // Store the configuration directly
        self.config = config
        
        // Initialize YouTube authentication if Google client ID is provided
        if let googleClientID = config.googleClientID {
            YouTubeAuthManager.shared.initialize(clientID: googleClientID)
            print("✅ [OnairosSDK] YouTube authentication initialized with Google client ID")
        } else {
            print("⚠️ [OnairosSDK] YouTube authentication not configured - no Google client ID provided")
        }
        
        // Configure API client to use the API key service
        OnairosAPIClient.shared.configure(
            baseURL: config.environment.baseURL,
            logLevel: config.logLevel,
            enableDetailedLogging: config.enableLogging
        )
        
        print("✅ [OnairosSDK] SDK initialized successfully with API key")
        print("   Environment: \(config.environment.rawValue)")
        print("   API Base URL: \(config.environment.baseURL)")
        print("   Logging Level: \(config.logLevel)")
    }
    
    /// Initialize the SDK with admin key (for testing and development)
    /// - Parameters:
    ///   - environment: API environment (production or development)
    ///   - enableLogging: Enable detailed logging
    ///   - timeout: Request timeout
    ///   - googleClientID: Google client ID for YouTube authentication
    /// - Throws: OnairosError if initialization fails
    public func initializeWithAdminKey(
        environment: SDKEnvironment = .production,  // Use production API for OAuth to work
        enableLogging: Bool = true,
        timeout: TimeInterval = 30.0,
        googleClientID: String? = nil
    ) async throws {
        let config = OnairosConfig(
            apiKey: OnairosAPIKeyService.ADMIN_API_KEY,
            environment: environment,
            enableLogging: enableLogging,
            timeout: timeout,
            googleClientID: googleClientID
        )
        
        try await initializeApiKey(config: config)
    }
    
    /// Initialize the SDK with a custom API key
    /// - Parameters:
    ///   - apiKey: Your API key
    ///   - environment: API environment (production or development)
    ///   - enableLogging: Enable detailed logging
    ///   - timeout: Request timeout
    ///   - googleClientID: Google client ID for YouTube authentication
    /// - Throws: OnairosError if initialization fails
    public func initializeWithApiKey(
        _ apiKey: String,
        environment: SDKEnvironment = .production,
        enableLogging: Bool = false,
        timeout: TimeInterval = 30.0,
        googleClientID: String? = nil
    ) async throws {
        let config = OnairosConfig(
            apiKey: apiKey,
            environment: environment,
            enableLogging: enableLogging,
            timeout: timeout,
            googleClientID: googleClientID
        )
        
        try await initializeApiKey(config: config)
    }
    
    /// Initialize the SDK with configuration (modern method)
    /// - Parameter config: SDK configuration
    public func initialize(config: OnairosConfig) {
        self.config = config
        
        // Initialize YouTube authentication if Google client ID is provided
        if let googleClientID = config.googleClientID {
            YouTubeAuthManager.shared.initialize(clientID: googleClientID)
            print("✅ [OnairosSDK] YouTube authentication initialized with Google client ID")
        } else {
            print("⚠️ [OnairosSDK] YouTube authentication not configured - no Google client ID provided")
        }
        
        // Validate configuration and provide guidance
        validateConfiguration(config)
        
        // Configure API client logging based on mode
        let logLevel: APILogLevel
        let enableDetailedLogging: Bool
        
        if config.isTestMode {
            logLevel = .verbose
            enableDetailedLogging = true
            print("🧪 [OnairosSDK] Test mode enabled - Full API logging active")
            print("🧪 [OnairosSDK] ⚠️  WARNING: Test mode bypasses all real API calls!")
            print("🧪 [OnairosSDK] ✅ This configuration prevents modal dismissal issues during development")
        } else if config.isDebugMode {
            logLevel = .debug
            enableDetailedLogging = true
            print("🐛 [OnairosSDK] Debug mode enabled - Enhanced API logging active")
            print("🐛 [OnairosSDK] ⚠️  WARNING: Debug mode makes real API calls but bypasses failures")
            print("🐛 [OnairosSDK] 🔧 For development without API calls, use OnairosConfig.testMode() instead")
        } else {
            logLevel = .info
            enableDetailedLogging = false
            print("ℹ️ [OnairosSDK] Production mode - Basic API logging active")
        }
        
        // Configure shared API client
        OnairosAPIClient.shared.configure(
            baseURL: config.apiBaseURL,
            logLevel: logLevel,
            enableDetailedLogging: enableDetailedLogging
        )
        
        // Initialize YouTube authentication if YouTube platform is enabled
        if config.platforms.contains(.youtube) {
            YouTubeAuthManager.shared.initialize()
            print("✅ [OnairosSDK] YouTube authentication initialized")
        }
        
        print("✅ [OnairosSDK] SDK initialized successfully")
        print("   Mode: \(config.isTestMode ? "Test" : config.isDebugMode ? "Debug" : "Production")")
        print("   API Base URL: \(config.apiBaseURL)")
        print("   Logging Level: \(logLevel)")
        print("   YouTube Auth: \(config.platforms.contains(.youtube) ? "Enabled" : "Disabled")")
    }
    
    /// Initialize the SDK with configuration (legacy method)
    /// - Parameter config: SDK configuration
    public func initialize(config: OnairosLegacyConfig) {
        // Convert legacy config to new format
        let newConfig = OnairosConfig(
            apiKey: "legacy-config-key", // Placeholder for legacy configs
            environment: config.apiBaseURL.contains("dev") ? .development : .production,
            enableLogging: config.isDebugMode,
            timeout: 30.0,
            isTestMode: config.isTestMode,
            isDebugMode: config.isDebugMode,
            allowEmptyConnections: config.allowEmptyConnections,
            simulateTraining: config.simulateTraining,
            platforms: config.platforms,
            linkedInClientID: config.linkedInClientID,
            googleClientID: config.googleClientID,
            urlScheme: config.urlScheme,
            appName: config.appName
        )
        
        self.config = newConfig
        
        // Initialize YouTube authentication if Google client ID is provided
        if let googleClientID = config.googleClientID {
            YouTubeAuthManager.shared.initialize(clientID: googleClientID)
            print("✅ [OnairosSDK] YouTube authentication initialized with Google client ID")
        } else {
            print("⚠️ [OnairosSDK] YouTube authentication not configured - no Google client ID provided")
        }
        
        // Validate configuration and provide guidance
        validateConfiguration(newConfig)
        
        // Configure API client logging based on mode
        let logLevel: APILogLevel
        let enableDetailedLogging: Bool
        
        if config.isTestMode {
            logLevel = .verbose
            enableDetailedLogging = true
            print("🧪 [OnairosSDK] Test mode enabled - Full API logging active")
            print("🧪 [OnairosSDK] ⚠️  WARNING: Test mode bypasses all real API calls!")
            print("🧪 [OnairosSDK] ✅ This configuration prevents modal dismissal issues during development")
        } else if config.isDebugMode {
            logLevel = .debug
            enableDetailedLogging = true
            print("🐛 [OnairosSDK] Debug mode enabled - Enhanced API logging active")
            print("🐛 [OnairosSDK] ⚠️  WARNING: Debug mode makes real API calls but bypasses failures")
            print("🐛 [OnairosSDK] 🔧 For development without API calls, use OnairosConfig.testMode() instead")
        } else {
            logLevel = .info
            enableDetailedLogging = false
            print("ℹ️ [OnairosSDK] Production mode - Basic API logging active")
        }
        
        // Configure shared API client
        OnairosAPIClient.shared.configure(
            baseURL: config.apiBaseURL,
            logLevel: logLevel,
            enableDetailedLogging: enableDetailedLogging
        )
        
        // Initialize YouTube authentication if YouTube platform is enabled
        if config.platforms.contains(.youtube) {
            YouTubeAuthManager.shared.initialize()
            print("✅ [OnairosSDK] YouTube authentication initialized")
        }
        
        print("✅ [OnairosSDK] SDK initialized successfully")
        print("   Mode: \(config.isTestMode ? "Test" : config.isDebugMode ? "Debug" : "Production")")
        print("   API Base URL: \(config.apiBaseURL)")
        print("   Logging Level: \(logLevel)")
        print("   YouTube Auth: \(config.platforms.contains(.youtube) ? "Enabled" : "Disabled")")
    }
    
    /// Validate configuration and provide helpful guidance
    /// - Parameter config: Configuration to validate
    private func validateConfiguration(_ config: OnairosConfig) {
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Check for common misconfiguration patterns
        if config.isDebugMode && !config.isTestMode && config.apiBaseURL.contains("api2.onairos.uk") {
            warnings.append("🚨 POTENTIAL ISSUE: Debug mode with production API may cause modal dismissal on API failures")
            recommendations.append("💡 RECOMMENDED: Use OnairosConfig.testMode() for development to avoid API call issues")
        }
        
        if !config.isTestMode && !config.isDebugMode && !config.allowEmptyConnections {
            recommendations.append("💡 INFO: Production mode requires platform connections for users to proceed")
        }
        
        if config.isTestMode && config.apiBaseURL.contains("api2.onairos.uk") {
            recommendations.append("💡 INFO: Test mode ignores API base URL and simulates all API calls locally")
        }
        
        // URL scheme validation
        if config.urlScheme.isEmpty {
            warnings.append("🚨 WARNING: Empty URL scheme may prevent OAuth platform authentication")
        }
        
        // Print warnings and recommendations
        if !warnings.isEmpty {
            print("\n⚠️  [OnairosSDK] CONFIGURATION WARNINGS:")
            warnings.forEach { print("   \($0)") }
        }
        
        if !recommendations.isEmpty {
            print("\n💡 [OnairosSDK] CONFIGURATION RECOMMENDATIONS:")
            recommendations.forEach { print("   \($0)") }
        }
        
        // Print usage examples for common scenarios
        if config.isDebugMode && !config.isTestMode {
            print("\n🔧 [OnairosSDK] DEBUG MODE GUIDANCE:")
            print("   Current: Debug mode with real API calls")
            print("   Alternative: Use OnairosConfig.testMode() to avoid API issues")
            print("   Example:")
            print("     let config = OnairosConfig.testMode(")
            print("         urlScheme: \"\(config.urlScheme)\",")
            print("         appName: \"\(config.appName)\"")
            print("     )")
        }
        
        if !warnings.isEmpty || !recommendations.isEmpty {
            print("\n📚 [OnairosSDK] For more information, see the integration guide")
            print("")
        }
    }
    
    /// Create Onairos connect button
    /// - Parameters:
    ///   - text: Optional custom button text (default: "Connect Data")
    /// - Returns: Configured UIButton
    public func createConnectButton(text: String = "Connect Data") -> UIButton {
        let button = OnairosConnectButton(text: text)
        
        button.onTapped = { [weak self] in
            // Find the current presenting view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                self?.completionCallback?(.failure(.configurationError("No presenting view controller found")))
                return
            }
            
            let presentingVC = self?.findTopViewController(from: rootViewController) ?? rootViewController
            self?.presentOnboarding(from: presentingVC) { result in
                // Handle result if needed
                self?.completionCallback?(result)
            }
        }
        
        return button
    }
    
    /// Create Onairos connect button with completion handler
    /// - Parameters:
    ///   - text: Optional custom button text (default: "Connect Data")
    ///   - completion: Completion callback with result
    /// - Returns: Configured UIButton
    public func createConnectButton(
        text: String = "Connect Data",
        completion: @escaping (Result<OnboardingResult, OnairosError>) -> Void
    ) -> UIButton {
        let button = OnairosConnectButton(text: text)
        
        button.onTapped = { [weak self] in
            // Find the current presenting view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                completion(.failure(.configurationError("No presenting view controller found")))
                return
            }
            
            let presentingVC = self?.findTopViewController(from: rootViewController) ?? rootViewController
            self?.presentOnboarding(from: presentingVC, completion: completion)
        }
        
        return button
    }
    
    /// Find the topmost view controller for presentation
    /// - Parameter viewController: Root view controller to search from
    /// - Returns: Topmost view controller
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return findTopViewController(from: topViewController)
        }
        
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return findTopViewController(from: selectedViewController)
        }
        
        return viewController
    }
    
    /// Present onboarding flow
    /// - Parameters:
    ///   - presentingViewController: View controller to present from
    ///   - completion: Completion callback
    public func presentOnboarding(
        from presentingViewController: UIViewController,
        completion: @escaping (Result<OnboardingResult, OnairosError>) -> Void
    ) {
        guard let config = config else {
            completion(.failure(.configurationError("SDK not initialized. Call initialize(config:) first.")))
            return
        }
        
        self.completionCallback = completion
        
        // Check if user has existing account
        checkExistingAccount { [weak self] hasAccount in
            DispatchQueue.main.async {
                if hasAccount {
                    self?.showDataRequestOverlay(from: presentingViewController)
                } else {
                    self?.startUniversalOnboarding(from: presentingViewController)
                }
            }
        }
    }
    
    /// Check if user has existing account
    private func checkExistingAccount(completion: @escaping (Bool) -> Void) {
        guard let config = config else {
            completion(false)
            return
        }
        
        // In test mode, skip API call
        if config.isTestMode {
            print("🧪 [OnairosSDK] Test mode - Skipping existing account check")
            completion(false)
            return
        }
        
        // Check with API if user has existing account
        Task {
            do {
                let hasAccount = try await OnairosAPIClient.shared.checkExistingAccount()
                completion(hasAccount)
            } catch {
                // If API call fails, proceed with onboarding
                print("⚠️ [OnairosSDK] Existing account check failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    /// Show data request overlay for existing users
    private func showDataRequestOverlay(from presentingViewController: UIViewController) {
        guard let config = config else {
            completionCallback?(.failure(.configurationError("SDK not configured")))
            return
        }
        
        let overlayController = DataRequestOverlayController(
            config: config,
            onConfirm: { [weak self] in
                self?.startDataCollection()
            },
            onCancel: { [weak self] in
                self?.completionCallback?(.failure(.userCancelled))
            }
        )
        
        presentingViewController.present(overlayController, animated: true)
    }
    
    /// Start universal onboarding flow
    private func startUniversalOnboarding(from presentingViewController: UIViewController) {
        guard let config = config else {
            completionCallback?(.failure(.configurationError("SDK not configured")))
            return
        }
        
        print("🔍 [DEBUG] startUniversalOnboarding called")
        
        let state = OnboardingState()
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        // Store coordinator reference to prevent deallocation
        self.coordinator = coordinator
        
        print("🔍 [DEBUG] Created coordinator and state")
        
        // Set up completion handler ONLY once - this will be called when the full flow completes
        coordinator.onCompletion = { [weak self] result in
            print("🔍 [DEBUG] Coordinator onCompletion called with result: \(result)")
            DispatchQueue.main.async {
                // Convert OnboardingResult to Result<OnboardingResult, OnairosError>
                let convertedResult: Result<OnboardingResult, OnairosError>
                switch result {
                case .success(let data):
                    convertedResult = .success(.success(data))
                case .failure(let error):
                    convertedResult = .failure(error)
                }
                
                print("🔍 [DEBUG] Calling completionCallback with converted result")
                self?.completionCallback?(convertedResult)
                
                // Clear references
                self?.modalController = nil
                self?.coordinator = nil
            }
        }
        
        // Create and present modal directly
        let modalController = OnairosModalController(
            coordinator: coordinator,
            state: state,
            config: config
        )
        
        self.modalController = modalController
        
        print("🔍 [DEBUG] Created modal controller, about to present")
        
        // Present modal with animation
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        
        presentingViewController.present(modalController, animated: true) {
            print("🔍 [DEBUG] Modal presentation completed")
        }
    }
    
    /// Start data collection for existing users
    private func startDataCollection() {
        guard let config = config else {
            completionCallback?(.failure(.configurationError("SDK not configured")))
            return
        }
        
        print("🔍 [DEBUG] startDataCollection called")
        
        // For existing users, skip to training
        let state = OnboardingState()
        state.currentStep = .training
        
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        // Store coordinator reference to prevent deallocation
        self.coordinator = coordinator
        
        coordinator.onCompletion = { [weak self] result in
            print("🔍 [DEBUG] Data collection onCompletion called with result: \(result)")
            DispatchQueue.main.async {
                // Convert OnboardingResult to Result<OnboardingResult, OnairosError>
                let convertedResult: Result<OnboardingResult, OnairosError>
                switch result {
                case .success(let data):
                    convertedResult = .success(.success(data))
                case .failure(let error):
                    convertedResult = .failure(error)
                }
                
                print("🔍 [DEBUG] Calling completionCallback from data collection")
                self?.completionCallback?(convertedResult)
                
                // Clear coordinator reference
                self?.coordinator = nil
            }
        }
        
        // Start training directly
        coordinator.startTraining()
    }
    
    /// Check if user has existing session
    public func hasExistingSession() -> Bool {
        return UserDefaults.standard.bool(forKey: "OnairosSessionExists")
    }
    
    /// Clear saved session
    public func clearSession() {
        UserDefaults.standard.removeObject(forKey: "OnairosSessionExists")
        UserDefaults.standard.removeObject(forKey: "OnairosConnectedPlatforms")
        UserDefaults.standard.removeObject(forKey: "OnairosUserEmail")
    }
    
    /// Clean up resources
    private func cleanup() {
        modalController = nil
        completionCallback = nil
        coordinator = nil
    }
    
    // MARK: - PIN Management (DEPRECATED - Biometric Storage Removed)
    
    // DEPRECATED: Biometric PIN storage has been removed to prevent crashes
    // PINs are now sent directly to the backend without local biometric storage
    
    /*
    /// Store user PIN securely with biometric authentication
    /// - Parameter pin: PIN to store securely
    /// - Returns: Result indicating success or failure
    public static func storePIN(_ pin: String) async -> Result<Void, OnairosError> {
        let result = await BiometricPINManager.shared.storePIN(pin)
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.authenticationFailed(error.localizedDescription))
        }
    }
    
    /// Retrieve user PIN with biometric authentication
    /// - Returns: Result containing the PIN or error
    public static func retrievePIN() async -> Result<String, OnairosError> {
        let result = await BiometricPINManager.shared.retrievePIN()
        
        switch result {
        case .success(let pin):
            return .success(pin)
        case .failure(let error):
            return .failure(.authenticationFailed(error.localizedDescription))
        }
    }
    
    /// Check if a PIN is stored securely
    /// - Returns: True if PIN exists in secure storage
    public static func hasPIN() -> Bool {
        return BiometricPINManager.shared.hasPIN()
    }
    
    /// Delete stored PIN
    /// - Returns: Result indicating success or failure
    public static func deletePIN() -> Result<Void, OnairosError> {
        let result = BiometricPINManager.shared.deletePIN()
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.authenticationFailed(error.localizedDescription))
        }
    }
    
    /// Get biometric authentication availability
    /// - Returns: Current biometric availability status
    public static func biometricAvailability() -> BiometricAvailability {
        return BiometricPINManager.shared.biometricAvailability()
    }
    
    /// Test function to verify BiometricPINManager accessibility
    /// - Returns: True if all types are accessible and working
    public static func testBiometricPINManagerAccessibility() -> Bool {
        // Test BiometricPINManager access
        let manager = BiometricPINManager.shared
        
        // Test BiometricAvailability enum
        let availability = manager.biometricAvailability()
        let availabilityName = availability.displayName
        
        // Test BiometricPINError enum
        let testError = BiometricPINError.invalidPIN
        let errorDescription = testError.localizedDescription
        
        // Test hasPIN functionality
        let hasPIN = manager.hasPIN()
        
        print("✅ [BIOMETRIC TEST] BiometricPINManager accessibility test passed")
        print("   - Availability: \(availabilityName)")
        print("   - Has PIN: \(hasPIN)")
        print("   - Error handling: \(errorDescription)")
        
        return !availabilityName.isEmpty && !errorDescription.isEmpty
    }
    */
}

/// Custom Onairos connect button
public class OnairosConnectButton: UIButton {
    
    /// Button tap callback
    var onTapped: (() -> Void)?
    
    /// Initialize with custom text
    /// - Parameter text: Button text
    init(text: String) {
        super.init(frame: .zero)
        setupButton(text: text)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton(text: "Connect Data")
    }
    
    /// Setup button appearance and behavior
    private func setupButton(text: String) {
        // Button styling
        backgroundColor = .systemBlue
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = 12
        
        // Add Onairos logo and text
        setupButtonContent(text: text)
        
        // Add tap handler
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Set minimum size
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
    }
    
    /// Setup button content with logo and text
    private func setupButtonContent(text: String) {
        // Create logo image view with actual Onairos logo
        let logoImageView = UIImageView()
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Load Onairos logo from bundle
        if let logoImage = UIImage(named: "OnairosWhiteNoBG", in: Bundle.module, compatibleWith: nil) {
            logoImageView.image = logoImage
        } else {
            // Fallback to system icon if logo not found
            logoImageView.image = UIImage(systemName: "link.circle.fill")
            logoImageView.tintColor = .white
        }
        
        addSubview(logoImageView)
        
        // Set button title
        setTitle(text, for: .normal)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 24),
            logoImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add title label constraint if it exists
        if let titleLabel = titleLabel {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8)
            ])
        }
    }
    
    /// Handle button tap
    @objc private func buttonTapped() {
        // CRITICAL: Protect CGAffineTransform from NaN values
        let scaleTransform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        guard !scaleTransform.a.isNaN && !scaleTransform.d.isNaN else {
            print("🚨 [ERROR] Invalid scale transform in button tap animation")
            // Fallback: just call onTapped without animation
            onTapped?()
            return
        }
        
        // Add tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = scaleTransform
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        onTapped?()
    }
}

/// Data request overlay for existing users
private class DataRequestOverlayController: UIViewController {
    
    private let config: OnairosConfig
    private let onConfirm: () -> Void
    private let onCancel: () -> Void
    
    init(config: OnairosConfig, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.config = config
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Welcome Back!"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        let messageLabel = UILabel()
        messageLabel.text = "We found your existing account. Would you like to continue with data collection?"
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Continue", for: .normal)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        [titleLabel, messageLabel, confirmButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            confirmButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
            
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func confirmTapped() {
        dismiss(animated: true) {
            self.onConfirm()
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.onCancel()
        }
    }
}

/// SDK Configuration (Legacy)
public struct OnairosLegacyConfig {
    /// Debug mode enables testing features
    public let isDebugMode: Bool
    
    /// Test mode bypasses all API calls and accepts any input
    public let isTestMode: Bool
    
    /// Allow proceeding without platform connections
    public let allowEmptyConnections: Bool
    
    /// Simulate training progress for testing
    public let simulateTraining: Bool
    
    /// API base URL
    public let apiBaseURL: String
    
    /// Platforms to enable
    public let platforms: Set<Platform>
    
    /// LinkedIn client ID for LinkedIn authentication
    public let linkedInClientID: String?
    
    /// Google client ID for YouTube authentication
    public let googleClientID: String?
    
    /// Custom URL scheme for OAuth callbacks
    public let urlScheme: String
    
    /// App name to display in UI
    public let appName: String
    
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
    
    public init(
        isDebugMode: Bool = false,
        isTestMode: Bool = false,
        allowEmptyConnections: Bool = false,
        simulateTraining: Bool = false,
        apiBaseURL: String = "https://api2.onairos.uk",
        platforms: Set<Platform> = [.linkedin, .youtube, .reddit, .pinterest, .gmail],
        linkedInClientID: String? = nil,
        googleClientID: String? = nil,
        urlScheme: String,
        appName: String
    ) {
        self.isDebugMode = isDebugMode
        self.isTestMode = isTestMode
        // In test mode, automatically enable these features
        self.allowEmptyConnections = isTestMode ? true : allowEmptyConnections
        self.simulateTraining = isTestMode ? true : simulateTraining
        self.apiBaseURL = apiBaseURL
        self.platforms = platforms
        self.linkedInClientID = linkedInClientID
        self.googleClientID = googleClientID
        self.urlScheme = urlScheme
        self.appName = appName
    }
    
    /// Create a test configuration for development with default values
    /// - Returns: Test configuration that bypasses all API calls
    public static func testMode() -> OnairosLegacyConfig {
        return OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            apiBaseURL: "https://test.api.onairos.uk", // Test API endpoint
            urlScheme: "onairos-test",
            appName: "Test App"
        )
    }
    
    /// Create a debug configuration for development
    /// - Returns: Debug configuration with enhanced logging
    public static func debugMode() -> OnairosLegacyConfig {
        return OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: false,
            allowEmptyConnections: true,
            simulateTraining: true,
            apiBaseURL: "https://api2.onairos.uk",
            urlScheme: "onairos-debug",
            appName: "Debug App"
        )
    }
    
    /// Create a test configuration for development
    /// - Parameters:
    ///   - urlScheme: Your app's URL scheme
    ///   - appName: Your app's name
    /// - Returns: Test configuration that bypasses all API calls
    public static func testMode(urlScheme: String, appName: String) -> OnairosLegacyConfig {
        return OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            apiBaseURL: "https://test.api.onairos.uk", // Test API endpoint
            urlScheme: urlScheme,
            appName: appName
        )
    }
}

/// Onboarding completion result
public enum OnboardingResult {
    case success(OnboardingData)
    case failure(OnairosError)
}

/// Completion handler type
public typealias OnboardingCompletion = (OnboardingResult) -> Void

/// Successful onboarding data
public struct OnboardingData: Codable {
    public let apiURL: String
    public let token: String
    public let userData: [String: AnyCodable]
    public let connectedPlatforms: [String: PlatformData]
    public let sessionSaved: Bool
    public let inferenceData: [String: AnyCodable]?
    public let partner: String?
    public let accountInfo: [String: AnyCodable]?
    
    public init(
        apiURL: String,
        token: String,
        userData: [String: Any],
        connectedPlatforms: [String: PlatformData],
        sessionSaved: Bool,
        inferenceData: [String: Any]? = nil,
        partner: String? = nil,
        accountInfo: [String: Any]? = nil
    ) {
        self.apiURL = apiURL
        self.token = token
        self.userData = userData.mapValues { AnyCodable($0) }
        self.connectedPlatforms = connectedPlatforms
        self.sessionSaved = sessionSaved
        self.inferenceData = inferenceData?.mapValues { AnyCodable($0) }
        self.partner = partner
        self.accountInfo = accountInfo?.mapValues { AnyCodable($0) }
    }
}

/// Platform authentication data
public struct PlatformData: Codable {
    public let platform: String
    public let accessToken: String?
    public let refreshToken: String?
    public let expiresAt: Date?
    public let userData: [String: AnyCodable]?
    
    public init(
        platform: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        userData: [String: Any]? = nil
    ) {
        self.platform = platform
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.userData = userData?.mapValues { AnyCodable($0) }
    }
} 