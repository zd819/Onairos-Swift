import UIKit
import Foundation
import Combine

/// Main Onairos SDK interface
@MainActor
public class OnairosSDK: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = OnairosSDK()
    
    /// SDK configuration
    private var config: OnairosConfig?
    
    /// Completion callback for onboarding
    private var completionCallback: ((Result<OnboardingResult, OnairosError>) -> Void)?
    
    /// Current modal controller
    private weak var modalController: OnairosModalController?
    
    private init() {}
    
    /// Initialize the SDK with configuration
    /// - Parameter config: SDK configuration
    public func initialize(config: OnairosConfig) {
        self.config = config
        
        // Configure API client logging based on mode
        let logLevel: APILogLevel
        let enableDetailedLogging: Bool
        
        if config.isTestMode {
            logLevel = .verbose
            enableDetailedLogging = true
            print("🧪 [OnairosSDK] Test mode enabled - Full API logging active")
        } else if config.isDebugMode {
            logLevel = .debug
            enableDetailedLogging = true
            print("🐛 [OnairosSDK] Debug mode enabled - Enhanced API logging active")
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
        
        print("✅ [OnairosSDK] SDK initialized successfully")
        print("   Mode: \(config.isTestMode ? "Test" : config.isDebugMode ? "Debug" : "Production")")
        print("   API Base URL: \(config.apiBaseURL)")
        print("   Logging Level: \(logLevel)")
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
        
        let state = OnboardingState()
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        // Set up completion handler ONLY once - this will be called when the full flow completes
        coordinator.onCompletion = { [weak self] result in
            DispatchQueue.main.async {
                // Pass the result directly to the completion callback
                self?.completionCallback?(result)
                
                // Clear the modal controller reference
                self?.modalController = nil
            }
        }
        
        // Start the coordinator flow (this will create and present the modal)
        // Do NOT set a completion handler here - it creates duplicate callbacks
        coordinator.start(from: presentingViewController) { [weak self] result in
            // This completion is for the coordinator.start() method itself, not the full flow
            // It should only handle start-up errors, not flow completion
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self?.completionCallback?(.failure(error))
                    self?.modalController = nil
                }
            }
            // Success case is handled by coordinator.onCompletion above
        }
    }
    
    /// Start data collection for existing users
    private func startDataCollection() {
        guard let config = config else {
            completionCallback?(.failure(.configurationError("SDK not configured")))
            return
        }
        
        // For existing users, skip to training
        let state = OnboardingState()
        state.currentStep = .training
        
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        coordinator.onCompletion = { [weak self] result in
            DispatchQueue.main.async {
                // Pass the result directly to the completion callback
                self?.completionCallback?(result)
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
        // Create logo view (placeholder - replace with actual logo)
        let logoView = UIView()
        logoView.backgroundColor = .white
        logoView.layer.cornerRadius = 12
        logoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add "O" text as logo placeholder
        let logoLabel = UILabel()
        logoLabel.text = "O"
        logoLabel.font = .systemFont(ofSize: 16, weight: .bold)
        logoLabel.textColor = .systemBlue
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        logoView.addSubview(logoLabel)
        addSubview(logoView)
        
        // Set button title
        setTitle(text, for: .normal)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 24),
            logoView.heightAnchor.constraint(equalToConstant: 24),
            
            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor)
        ])
        
        // Add title label constraint if it exists
        if let titleLabel = titleLabel {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 8)
            ])
        }
    }
    
    /// Handle button tap
    @objc private func buttonTapped() {
        // Add tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
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

/// SDK Configuration
public struct OnairosConfig {
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
    
    /// Opacity API key for Instagram authentication
    public let opacityAPIKey: String?
    
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
        platforms: Set<Platform> = [.instagram, .youtube, .reddit, .pinterest, .gmail],
        opacityAPIKey: String? = nil,
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
        self.opacityAPIKey = opacityAPIKey
        self.googleClientID = googleClientID
        self.urlScheme = urlScheme
        self.appName = appName
    }
    
    /// Create a test configuration for development with default values
    /// - Returns: Test configuration that bypasses all API calls
    public static func testMode() -> OnairosConfig {
        return OnairosConfig(
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
    public static func debugMode() -> OnairosConfig {
        return OnairosConfig(
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
    public static func testMode(urlScheme: String, appName: String) -> OnairosConfig {
        return OnairosConfig(
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
    
    public init(
        apiURL: String,
        token: String,
        userData: [String: Any],
        connectedPlatforms: [String: PlatformData],
        sessionSaved: Bool,
        inferenceData: [String: Any]? = nil,
        partner: String? = nil
    ) {
        self.apiURL = apiURL
        self.token = token
        self.userData = userData.mapValues { AnyCodable($0) }
        self.connectedPlatforms = connectedPlatforms
        self.sessionSaved = sessionSaved
        self.inferenceData = inferenceData?.mapValues { AnyCodable($0) }
        self.partner = partner
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