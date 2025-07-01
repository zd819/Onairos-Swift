import UIKit

/// Platform connection step view controller
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
    private let iconView = UIView()
    
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
        
        // Platform icon (placeholder)
        iconView.backgroundColor = platformColor()
        iconView.layer.cornerRadius = 20
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
        case .instagram:
            return UIColor(red: 0.8, green: 0.3, blue: 0.8, alpha: 1.0) // Purple/Pink
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
            actionButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            actionButton.setTitleColor(.systemBlue, for: .normal)
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
            // Connect
            coordinator?.connectToPlatform(platform)
        }
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