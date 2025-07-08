import UIKit

/// Platform connection step view controller
@MainActor
public class ConnectStepViewController: BaseStepViewController {
    
    /// Platform list container
    private let platformListContainer = UIView()
    
    /// Platform connection views
    private var platformViews: [PlatformConnectionView] = []
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Connect Your Accounts"
        setupSubtitleWithLink()
        
        // Configure buttons
        primaryButton.setTitle("Continue", for: .normal)
        secondaryButton.setTitle("Back", for: .normal)
        
        // Setup platform list
        setupPlatformList()
        
        // Bind to state
        bindToState()
    }
    
    /// Setup subtitle with clickable "How it's used" link
    private func setupSubtitleWithLink() {
        // Create attributed string for subtitle with link
        let baseText = "Choose which platforms to connect for personalized AI training. "
        let linkText = "How it's used →"
        let fullText = baseText + linkText
        
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Style the base text
        attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: NSRange(location: 0, length: baseText.count))
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .regular), range: NSRange(location: 0, length: baseText.count))
        
        // Style the link text
        let linkRange = NSRange(location: baseText.count, length: linkText.count)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: linkRange)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: linkRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)
        
        // Set the attributed text
        subtitleLabel.attributedText = attributedString
        
        // Make subtitle label interactive
        subtitleLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(subtitleTapped(_:)))
        subtitleLabel.addGestureRecognizer(tapGesture)
    }
    
    /// Handle subtitle tap to detect link
    @objc private func subtitleTapped(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = subtitleLabel.attributedText else { return }
        
        let baseText = "Choose which platforms to connect for personalized AI training. "
        let linkText = "How it's used →"
        let linkRange = NSRange(location: baseText.count, length: linkText.count)
        
        // Get the tapped character index
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: subtitleLabel.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = subtitleLabel.numberOfLines
        textContainer.lineBreakMode = subtitleLabel.lineBreakMode
        
        let locationOfTouchInLabel = gesture.location(in: subtitleLabel)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Check if the tap was on the link
        if NSLocationInRange(indexOfCharacter, linkRange) {
            showPrivacyDetails()
        }
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
    

    
    /// Show privacy details modal
    @objc private func showPrivacyDetails() {
        let privacyModal = PrivacyDetailsModal()
        privacyModal.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        privacyModal.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        // Configure sheet presentation (iOS 15+ only)
        if #available(iOS 15.0, *) {
            if let sheet = privacyModal.sheetPresentationController {
                sheet.detents = [UISheetPresentationController.Detent.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(privacyModal, animated: true)
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
        iconView.layer.cornerRadius = 0  // Remove circular masking
        iconView.layer.masksToBounds = false  // Allow full icon visibility
        iconView.backgroundColor = .clear
        
        // Clear any existing content first
        iconView.image = nil
        iconView.subviews.forEach { $0.removeFromSuperview() }
        
        // Load actual platform logo from Resources bundle
        let iconFileName = platform.iconFileName
        if let logoImage = UIImage(named: iconFileName, in: Bundle.module, compatibleWith: nil) {
            // Process image to handle transparency issues
            let processedImage = processImageForTransparency(logoImage, platform: platform)
            iconView.image = processedImage
            iconView.backgroundColor = .clear
            iconView.isOpaque = false
        } else {
            // Fallback to programmatically created icon if logo not found
            let iconImage = createPlatformIcon(for: platform)
            iconView.image = iconImage
        }
    }
    
    /// Process image to handle transparency issues (remove checkerboard patterns)
    private func processImageForTransparency(_ image: UIImage, platform: Platform) -> UIImage {
        // For Gmail, fix orientation issues and clean up transparency
        if platform == .gmail {
            let orientationFixedImage = fixImageOrientation(image)
            return cleanCheckerboardPattern(from: orientationFixedImage)
        }
        // For YouTube, which may have checkerboard patterns, we'll clean them up
        else if platform == .youtube {
            return cleanCheckerboardPattern(from: image)
        }
        return image
    }
    
    /// Fix image orientation issues (especially for Gmail)
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let size = image.size
        let scale = image.scale
        
        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // For Gmail, always flip 180 degrees to correct the upside-down issue
        // Rotate 180 degrees by translating to center, rotating, then translating back
        context.translateBy(x: size.width, y: size.height)
        context.rotate(by: .pi)
        
        // Draw the image
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        // Get the corrected image
        let correctedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return correctedImage
    }
    
    /// Remove checkerboard transparency pattern from image
    private func cleanCheckerboardPattern(from image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let size = image.size
        let scale = image.scale
        
        // Create a new image context with alpha
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // Set a white background to hide the checkerboard pattern
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw the original image on top
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        // Get the processed image
        let processedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return processedImage
    }
    
    /// Create platform icon programmatically with proper branding
    private func createPlatformIcon(for platform: Platform) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Set platform-specific background color
            platformColor().setFill()
            context.cgContext.fillEllipse(in: rect)
            
            // Add platform-specific icon/text
            switch platform {
            case .gmail:
                // Gmail - Draw envelope icon
                let iconRect = CGRect(x: 8, y: 8, width: 24, height: 24)
                UIColor.white.setFill()
                
                // Simple envelope shape
                let path = UIBezierPath()
                path.move(to: CGPoint(x: iconRect.minX, y: iconRect.minY + 6))
                path.addLine(to: CGPoint(x: iconRect.maxX, y: iconRect.minY + 6))
                path.addLine(to: CGPoint(x: iconRect.maxX, y: iconRect.maxY - 6))
                path.addLine(to: CGPoint(x: iconRect.minX, y: iconRect.maxY - 6))
                path.close()
                path.fill()
                
                // Envelope flap
                let flapPath = UIBezierPath()
                flapPath.move(to: CGPoint(x: iconRect.minX, y: iconRect.minY + 6))
                flapPath.addLine(to: CGPoint(x: iconRect.midX, y: iconRect.midY))
                flapPath.addLine(to: CGPoint(x: iconRect.maxX, y: iconRect.minY + 6))
                flapPath.lineWidth = 2
                UIColor.red.setStroke()
                flapPath.stroke()
                
            case .linkedin:
                // LinkedIn - Draw "in" text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let text = "in"
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attributes)
                
            case .youtube:
                // YouTube - Draw play button
                let playRect = CGRect(x: 12, y: 12, width: 16, height: 16)
                let playPath = UIBezierPath()
                playPath.move(to: CGPoint(x: playRect.minX, y: playRect.minY))
                playPath.addLine(to: CGPoint(x: playRect.maxX, y: playRect.midY))
                playPath.addLine(to: CGPoint(x: playRect.minX, y: playRect.maxY))
                playPath.close()
                UIColor.white.setFill()
                playPath.fill()
                
            case .reddit:
                // Reddit - Draw "r/" text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let text = "r/"
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attributes)
                
            case .pinterest:
                // Pinterest - Draw "P" text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let text = "P"
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attributes)
            }
        }
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
            config: config,
            userEmail: state.email
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

/// Privacy details modal view controller
private class PrivacyDetailsModal: UIViewController {
    
    /// Main scroll view
    private let scrollView = UIScrollView()
    
    /// Content view
    private let contentView = UIView()
    
    /// Main stack view
    private let stackView = UIStackView()
    
    /// Got it button
    private let gotItButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    /// Setup UI components
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // Configure content view
        scrollView.addSubview(contentView)
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        
        // Setup header
        setupHeader()
        
        // Setup content
        setupContent()
        
        // Setup footer
        setupFooter()
    }
    
    /// Setup header with back button and title
    private func setupHeader() {
        let headerContainer = UIView()
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "How Enoch uses personal data"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        
        headerContainer.addSubview(backButton)
        headerContainer.addSubview(titleLabel)
        
        // Setup constraints
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            headerContainer.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        stackView.addArrangedSubview(headerContainer)
    }
    
    /// Setup content with privacy information
    private func setupContent() {
        // Create bullet points container with more spacing
        let bulletPointsContainer = UIView()
        
        // Create vertical stack for bullet points with increased spacing
        let bulletPointsStack = UIStackView()
        bulletPointsStack.axis = .vertical
        bulletPointsStack.spacing = 40 // Increased spacing between bullet points
        bulletPointsStack.alignment = .center
        bulletPointsStack.distribution = .equalSpacing
        
        // Create bullet points
        let bulletPoints = [
            "Enoch legally accesses your platform data with explicit permission for this event only - never stored post-session and auto-deleted.",
            "Enoch NEVER sells your data. You are a user, not a commodity.",
            "Data collected builds your Onairos persona, enabling personalized experiences across future products while prioritizing your data sovereignty."
        ]
        
        for bulletText in bulletPoints {
            let bulletContainer = createBulletPoint(text: bulletText)
            bulletPointsStack.addArrangedSubview(bulletContainer)
        }
        
        bulletPointsContainer.addSubview(bulletPointsStack)
        
        // Setup constraints for bullet points container
        bulletPointsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bulletPointsStack.topAnchor.constraint(equalTo: bulletPointsContainer.topAnchor, constant: 40),
            bulletPointsStack.leadingAnchor.constraint(equalTo: bulletPointsContainer.leadingAnchor, constant: 20),
            bulletPointsStack.trailingAnchor.constraint(equalTo: bulletPointsContainer.trailingAnchor, constant: -20),
            bulletPointsStack.bottomAnchor.constraint(equalTo: bulletPointsContainer.bottomAnchor, constant: -40)
        ])
        
        stackView.addArrangedSubview(bulletPointsContainer)
    }
    
    /// Create a bullet point view
    /// - Parameter text: Bullet point text
    /// - Returns: Container view with bullet point
    private func createBulletPoint(text: String) -> UIView {
        let container = UIView()
        
        // Create horizontal stack for better centering
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 12
        horizontalStack.alignment = .top
        horizontalStack.distribution = .fill
        
        // Bullet point
        let bulletLabel = UILabel()
        bulletLabel.text = "•"
        bulletLabel.font = .systemFont(ofSize: 20, weight: .bold)
        bulletLabel.textColor = .label
        bulletLabel.textAlignment = .center
        
        // Text label
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.textAlignment = .left
        
        // Add to horizontal stack
        horizontalStack.addArrangedSubview(bulletLabel)
        horizontalStack.addArrangedSubview(textLabel)
        
        container.addSubview(horizontalStack)
        
        // Setup constraints
        bulletLabel.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Bullet label width
            bulletLabel.widthAnchor.constraint(equalToConstant: 24),
            
            // Horizontal stack constraints
            horizontalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            horizontalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            horizontalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            horizontalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    /// Setup footer with Got it button
    private func setupFooter() {
        // Add spacer to push button to bottom
        let spacerView = UIView()
        spacerView.backgroundColor = .clear
        stackView.addArrangedSubview(spacerView)
        
        let footerContainer = UIView()
        
        // Got it button
        gotItButton.setTitle("Got it", for: .normal)
        gotItButton.backgroundColor = .black
        gotItButton.setTitleColor(.white, for: .normal)
        gotItButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        gotItButton.layer.cornerRadius = 12
        gotItButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        
        footerContainer.addSubview(gotItButton)
        
        // Setup constraints
        gotItButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gotItButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor, constant: 20),
            gotItButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor, constant: -20),
            gotItButton.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: 60),
            gotItButton.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -20),
            gotItButton.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        stackView.addArrangedSubview(footerContainer)
        
        // Set spacer height to push button to bottom
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
    }
    
    /// Setup Auto Layout constraints
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    /// Dismiss the modal
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
} 