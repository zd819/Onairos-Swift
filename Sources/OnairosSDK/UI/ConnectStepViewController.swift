import UIKit

/// Platform connection step view controller
@MainActor
public class ConnectStepViewController: BaseStepViewController {
    
    /// Platform list container
    private let platformListContainer = UIView()
    
    /// Privacy message label
    private let privacyMessageLabel = UILabel()
    
    /// Platform connection views
    private var platformViews: [PlatformConnectionView] = []
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Connect Your Accounts"
        subtitleLabel.text = "Choose which platforms to connect for personalized AI training"
        
        // Configure buttons
        primaryButton.setTitle("Continue", for: .normal)
        secondaryButton.setTitle("Back", for: .normal)
        
        // Setup platform list
        setupPlatformList()
        
        // Setup privacy message
        setupPrivacyMessage()
        
        // Bind to state
        bindToState()
    }
    
    /// Setup platform connection list
    private func setupPlatformList() {
        platformListContainer.backgroundColor = .clear
        
        // Create stack view for platforms
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        
        // Add platform views for enabled platforms
        for platform in config.platforms.sorted(by: { $0.rawValue < $1.rawValue }) {
            let platformView = PlatformConnectionView(
                platform: platform,
                coordinator: coordinator,
                state: state,
                config: config
            )
            platformViews.append(platformView)
            stackView.addArrangedSubview(platformView)
        }
        
        platformListContainer.addSubview(stackView)
        contentStackView.addArrangedSubview(platformListContainer)
        
        // Setup constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: platformListContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: platformListContainer.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: platformListContainer.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: platformListContainer.bottomAnchor)
        ])
    }
    
    /// Setup privacy message
    private func setupPrivacyMessage() {
        privacyMessageLabel.text = "🔒 None of your app data is shared with ANYONE"
        privacyMessageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        privacyMessageLabel.textColor = .systemGreen
        privacyMessageLabel.textAlignment = .center
        privacyMessageLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        privacyMessageLabel.layer.cornerRadius = 8
        privacyMessageLabel.layer.masksToBounds = true
        
        contentStackView.addArrangedSubview(privacyMessageLabel)
        
        privacyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            privacyMessageLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    /// Bind to onboarding state
    private func bindToState() {
        updateButtonState()
        
        // Observe connected platforms changes
        state.$connectedPlatforms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonState()
            }
            .store(in: &cancellables)
    }
    
    /// Update button state based on connections
    private func updateButtonState() {
        let hasConnections = !state.connectedPlatforms.isEmpty
        let canProceed = hasConnections || config.allowEmptyConnections || config.isDebugMode
        
        primaryButton.isEnabled = canProceed && !state.isLoading
        primaryButton.alpha = canProceed ? 1.0 : 0.6
        
        // Update button text based on connections
        if hasConnections {
            primaryButton.setTitle("Continue", for: .normal)
        } else if config.allowEmptyConnections || config.isDebugMode {
            primaryButton.setTitle("Skip for Now", for: .normal)
        } else {
            primaryButton.setTitle("Connect at Least One", for: .normal)
        }
    }
    
    public override func setLoading(_ isLoading: Bool) {
        super.setLoading(isLoading)
        
        if !isLoading {
            updateButtonState()
        }
        
        platformViews.forEach { $0.setLoading(isLoading) }
    }
    
    public override func primaryButtonTapped() {
        // Clear any existing error
        state.errorMessage = nil
        
        // Check if we can proceed
        let hasConnections = !state.connectedPlatforms.isEmpty
        let canProceed = hasConnections || config.allowEmptyConnections || config.isDebugMode
        
        if !canProceed {
            state.errorMessage = "Please connect at least one platform to continue"
            return
        }
        
        // Proceed to next step
        super.primaryButtonTapped()
    }
}

/// Individual platform connection view
private class PlatformConnectionView: UIView {
    
    /// Platform information
    private let platform: Platform
    
    /// Coordinator reference
    private weak var coordinator: OnboardingCoordinator?
    
    /// State reference
    private let state: OnboardingState
    
    /// Configuration
    private let config: OnairosConfig
    
    /// Platform icon
    private let iconView = UIImageView()
    
    /// Platform name label
    private let nameLabel = UILabel()
    
    /// Connection status label
    private let statusLabel = UILabel()
    
    /// Connect/Disconnect button
    private let actionButton = UIButton(type: .system)
    
    /// Loading indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    /// Initialize platform connection view
    init(
        platform: Platform,
        coordinator: OnboardingCoordinator?,
        state: OnboardingState,
        config: OnairosConfig
    ) {
        self.platform = platform
        self.coordinator = coordinator
        self.state = state
        self.config = config
        
        super.init(frame: .zero)
        
        setupUI()
        updateConnectionState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Setup UI components
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        
        // Platform icon
        setupPlatformIcon()
        addSubview(iconView)
        
        // Platform name
        nameLabel.text = platform.displayName
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        addSubview(nameLabel)
        
        // Status label
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        addSubview(statusLabel)
        
        // Action button
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        addSubview(actionButton)
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    /// Setup platform icon
    private func setupPlatformIcon() {
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 20
        iconView.layer.masksToBounds = true
        iconView.backgroundColor = .clear
        
        // Clear any existing content first
        iconView.image = nil
        iconView.subviews.forEach { $0.removeFromSuperview() }
        
        let fileName = platform.iconFileName
        let fileNameWithoutExtension = String(fileName.dropLast(4)) // Remove .png
        
        print("🔍 [DEBUG] Loading icon for \(platform.displayName)")
        print("🔍 [DEBUG] Filename: \(fileName)")
        print("🔍 [DEBUG] Without extension: \(fileNameWithoutExtension)")
        
        // Debug: Print bundle information
        print("🔍 [DEBUG] Bundle.module: \(Bundle.module)")
        print("🔍 [DEBUG] Bundle.module.bundlePath: \(Bundle.module.bundlePath)")
        
        // Try the most direct approach first - Bundle.module with exact filename
        if let iconImage = UIImage(named: fileNameWithoutExtension, in: Bundle.module, compatibleWith: nil) {
            iconView.image = iconImage
            print("✅ [SUCCESS] Loaded \(platform.displayName) icon with method 1 (Bundle.module, no extension)")
            print("✅ [SUCCESS] Icon size: \(iconImage.size)")
            return
        }
        
        // Try Bundle.module with full filename
        if let iconImage = UIImage(named: fileName, in: Bundle.module, compatibleWith: nil) {
            iconView.image = iconImage
            print("✅ [SUCCESS] Loaded \(platform.displayName) icon with method 2 (Bundle.module, with extension)")
            print("✅ [SUCCESS] Icon size: \(iconImage.size)")
            return
        }
        
        // Try direct file path access
        if let resourcePath = Bundle.module.path(forResource: fileNameWithoutExtension, ofType: "png") {
            print("🔍 [DEBUG] Found resource path: \(resourcePath)")
            if let directImage = UIImage(contentsOfFile: resourcePath) {
                iconView.image = directImage
                print("✅ [SUCCESS] Loaded \(platform.displayName) icon with direct file access")
                print("✅ [SUCCESS] Icon size: \(directImage.size)")
                return
            }
        }
        
        // Try alternative resource path
        if let resourcePath = Bundle.module.path(forResource: fileName, ofType: nil) {
            print("🔍 [DEBUG] Found alternative resource path: \(resourcePath)")
            if let directImage = UIImage(contentsOfFile: resourcePath) {
                iconView.image = directImage
                print("✅ [SUCCESS] Loaded \(platform.displayName) icon with alternative direct file access")
                print("✅ [SUCCESS] Icon size: \(directImage.size)")
                return
            }
        }
        
        // Try main bundle as fallback
        if let iconImage = UIImage(named: fileNameWithoutExtension, in: Bundle.main, compatibleWith: nil) {
            iconView.image = iconImage
            print("✅ [SUCCESS] Loaded \(platform.displayName) icon from main bundle")
            print("✅ [SUCCESS] Icon size: \(iconImage.size)")
            return
        }
        
        // List all resources in the bundle for debugging
        if let resourcePath = Bundle.module.resourcePath {
            print("🔍 [DEBUG] Bundle resource path: \(resourcePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("🔍 [DEBUG] Bundle contents: \(contents)")
            } catch {
                print("🚨 [ERROR] Failed to list bundle contents: \(error)")
            }
        }
        
        // Final fallback: use colored background with system icon
        print("🚨 [FINAL FALLBACK] Using colored background for \(platform.displayName)")
        iconView.backgroundColor = platformColor()
        
        let systemIconView = UIImageView()
        systemIconView.contentMode = .scaleAspectFit
        systemIconView.tintColor = .white
        systemIconView.image = platformSystemIcon()
        systemIconView.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.addSubview(systemIconView)
        NSLayoutConstraint.activate([
            systemIconView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            systemIconView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            systemIconView.widthAnchor.constraint(equalToConstant: 24),
            systemIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    /// Get platform-specific system icon
    /// - Returns: Platform system icon
    private func platformSystemIcon() -> UIImage? {
        switch platform {
        case .linkedin:
            return UIImage(systemName: "person.crop.rectangle")
        case .youtube:
            return UIImage(systemName: "play.rectangle")
        case .reddit:
            return UIImage(systemName: "bubble.left.and.bubble.right")
        case .pinterest:
            return UIImage(systemName: "pin")
        case .gmail:
            return UIImage(systemName: "envelope")
        }
    }
    
    /// Setup Auto Layout constraints
    private func setupConstraints() {
        [iconView, nameLabel, statusLabel, actionButton, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Container height
            heightAnchor.constraint(equalToConstant: 72),
            
            // Icon
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),
            
            // Action button
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 80),
            actionButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
    }
    
    /// Get platform-specific color
    /// - Returns: Platform color
    private func platformColor() -> UIColor {
        switch platform {
        case .linkedin:
            return UIColor(red: 0.0, green: 0.47, blue: 0.75, alpha: 1.0) // LinkedIn Blue
        case .youtube:
            return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Red
        case .reddit:
            return UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0) // Orange-Red
        case .pinterest:
            return UIColor(red: 0.9, green: 0.0, blue: 0.2, alpha: 1.0) // Red
        case .gmail:
            return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) // Red
        }
    }
    
    /// Update connection state UI
    private func updateConnectionState() {
        let isConnected = state.connectedPlatforms.contains(platform.rawValue)
        
        if isConnected {
            statusLabel.text = "Connected ✓"
            statusLabel.textColor = .systemGreen
            actionButton.setTitle("Disconnect", for: .normal)
            actionButton.backgroundColor = .systemRed.withAlphaComponent(0.1)
            actionButton.setTitleColor(.systemRed, for: .normal)
        } else {
            statusLabel.text = "Not connected"
            statusLabel.textColor = .secondaryLabel
            actionButton.setTitle("Connect", for: .normal)
            actionButton.backgroundColor = .black
            actionButton.setTitleColor(.white, for: .normal)
        }
    }
    
    /// Handle action button tap
    @objc private func actionButtonTapped() {
        let isConnected = state.connectedPlatforms.contains(platform.rawValue)
        
        if isConnected {
            // Disconnect
            state.connectedPlatforms.remove(platform.rawValue)
            updateConnectionState()
        } else {
            // Connect - show WebView for OAuth platforms
            if platform.authMethod == .oauth {
                showOAuthWebView()
            } else {
                coordinator?.connectToPlatform(platform)
            }
        }
    }
    
    /// Show OAuth WebView for platform authentication
    private func showOAuthWebView() {
        guard let parentViewController = findParentViewController() else { return }
        
        setLoading(true)
        
        let oauthController = OAuthWebViewController(
            platform: platform,
            config: config
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success(let authToken):
                    // Handle successful OAuth
                    self?.handleOAuthSuccess(authToken: authToken)
                case .failure(let error):
                    // Handle OAuth failure
                    self?.handleOAuthFailure(error: error)
                }
            }
        }
        
        parentViewController.present(oauthController, animated: true)
    }
    
    /// Handle successful OAuth authentication
    private func handleOAuthSuccess(authToken: String) {
        // Mark platform as connected in state
        state.connectedPlatforms.insert(platform.rawValue)
        
        // Persist connection state
        persistConnectionState()
        
        // Update UI to show connected state
        updateConnectionState()
        
        // Store auth token for API calls
        storeAuthToken(authToken)
        
        // Provide user feedback
        showSuccessMessage()
        
        // Notify coordinator if available
        coordinator?.handlePlatformConnected(platform)
        
        print("✅ [SUCCESS] \(platform.displayName) connected successfully")
    }
    
    /// Handle OAuth authentication failure
    private func handleOAuthFailure(error: OnairosError) {
        // Show user-friendly error message
        showErrorMessage(for: error)
        
        print("❌ [ERROR] OAuth failed for \(platform.displayName): \(error.localizedDescription)")
    }
    
    /// Persist connection state to UserDefaults
    private func persistConnectionState() {
        let connectionKey = "onairos_connected_platforms"
        let connectedPlatforms = Array(state.connectedPlatforms)
        UserDefaults.standard.set(connectedPlatforms, forKey: connectionKey)
        
        // Also store individual platform connection timestamp
        let timestampKey = "onairos_\(platform.rawValue)_connected_at"
        UserDefaults.standard.set(Date(), forKey: timestampKey)
        
        print("💾 [STORAGE] Persisted connection state for \(platform.displayName)")
    }
    
    /// Store auth token securely
    private func storeAuthToken(_ token: String) {
        let tokenKey = "onairos_\(platform.rawValue)_token"
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Set expiration time (tokens typically expire after 1 hour)
        let expirationKey = "onairos_\(platform.rawValue)_token_expires"
        let expirationDate = Date().addingTimeInterval(3600) // 1 hour
        UserDefaults.standard.set(expirationDate, forKey: expirationKey)
        
        print("🔐 [SECURITY] Stored auth token for \(platform.displayName)")
    }
    
    /// Show success message to user
    private func showSuccessMessage() {
        // Create success feedback view
        let successView = UIView()
        successView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        successView.layer.cornerRadius = 8
        successView.translatesAutoresizingMaskIntoConstraints = false
        
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let successLabel = UILabel()
        successLabel.text = "Connected to \(platform.displayName)!"
        successLabel.font = .systemFont(ofSize: 14, weight: .medium)
        successLabel.textColor = .systemGreen
        successLabel.translatesAutoresizingMaskIntoConstraints = false
        
        successView.addSubview(checkmarkImageView)
        successView.addSubview(successLabel)
        
        addSubview(successView)
        
        NSLayoutConstraint.activate([
            successView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            successView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            successView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            successView.heightAnchor.constraint(equalToConstant: 32),
            
            checkmarkImageView.leadingAnchor.constraint(equalTo: successView.leadingAnchor, constant: 8),
            checkmarkImageView.centerYAnchor.constraint(equalTo: successView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 16),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 16),
            
            successLabel.leadingAnchor.constraint(equalTo: checkmarkImageView.trailingAnchor, constant: 8),
            successLabel.centerYAnchor.constraint(equalTo: successView.centerYAnchor),
            successLabel.trailingAnchor.constraint(equalTo: successView.trailingAnchor, constant: -8)
        ])
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3) {
                successView.alpha = 0
            } completion: { _ in
                successView.removeFromSuperview()
            }
        }
    }
    
    /// Show error message to user
    private func showErrorMessage(for error: OnairosError) {
        let errorMessage: String
        
        switch error {
        case .userCancelled:
            errorMessage = "Authentication cancelled"
        case .networkError(let details):
            errorMessage = "Network error: \(details)"
        case .authenticationFailed(let reason):
            errorMessage = "Authentication failed: \(reason)"
        default:
            errorMessage = "Connection failed. Please try again."
        }
        
        // Create error feedback view
        let errorView = UIView()
        errorView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorView.layer.cornerRadius = 8
        errorView.translatesAutoresizingMaskIntoConstraints = false
        
        let errorImageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        errorImageView.tintColor = .systemRed
        errorImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let errorLabel = UILabel()
        errorLabel.text = errorMessage
        errorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        errorView.addSubview(errorImageView)
        errorView.addSubview(errorLabel)
        
        addSubview(errorView)
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            errorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            errorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            
            errorImageView.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 8),
            errorImageView.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 8),
            errorImageView.widthAnchor.constraint(equalToConstant: 16),
            errorImageView.heightAnchor.constraint(equalToConstant: 16),
            
            errorLabel.leadingAnchor.constraint(equalTo: errorImageView.trailingAnchor, constant: 8),
            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 8),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -8),
            errorLabel.bottomAnchor.constraint(equalTo: errorView.bottomAnchor, constant: -8)
        ])
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIView.animate(withDuration: 0.3) {
                errorView.alpha = 0
            } completion: { _ in
                errorView.removeFromSuperview()
            }
        }
    }
    
    /// Find parent view controller
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    /// Set loading state
    /// - Parameter isLoading: Loading state
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            actionButton.setTitle("", for: .normal)
            actionButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            actionButton.isEnabled = true
            updateConnectionState()
        }
    }
} 