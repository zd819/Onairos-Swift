import UIKit
import Foundation
import LocalAuthentication

/// PIN creation step view controller
@MainActor
public class PINStepViewController: BaseStepViewController {
    
    /// PIN input field
    private let pinTextField = UITextField()
    
    /// PIN input container view
    private let pinInputContainer = UIView()
    
    /// Requirements validation view
    private let requirementsView = UIView()
    
    /// PIN requirements checker
    private let pinRequirements = PINRequirements()
    
    /// Requirement validation labels
    private var requirementLabels: [UILabel] = []
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Create Your PIN"
        subtitleLabel.text = "Secure your account with a strong PIN"
        
        // Configure buttons
        primaryButton.setTitle("Create PIN", for: .normal)
        secondaryButton.setTitle("Back", for: .normal)
        
        // Setup PIN input
        setupPINInput()
        
        // Setup requirements view
        setupRequirementsView()
        
        // Bind to state
        bindToState()
    }
    
    /// Setup PIN input field
    private func setupPINInput() {
        // Container view
        pinInputContainer.backgroundColor = .systemGray6
        pinInputContainer.layer.cornerRadius = 12
        pinInputContainer.layer.borderWidth = 1
        pinInputContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Text field
        pinTextField.placeholder = "Enter your PIN (8+ characters)"
        pinTextField.isSecureTextEntry = true
        pinTextField.font = .systemFont(ofSize: 16)
        pinTextField.textColor = .label
        pinTextField.keyboardType = .default
        pinTextField.addTarget(self, action: #selector(pinTextChanged), for: .editingChanged)
        pinTextField.delegate = self
        
        // Add show/hide PIN button
        let showHideButton = UIButton(type: .system)
        showHideButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showHideButton.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        showHideButton.addTarget(self, action: #selector(togglePINVisibility), for: .touchUpInside)
        showHideButton.tintColor = .systemGray
        
        // Add to container
        pinInputContainer.addSubview(pinTextField)
        pinInputContainer.addSubview(showHideButton)
        contentStackView.addArrangedSubview(pinInputContainer)
        
        // Setup constraints
        pinTextField.translatesAutoresizingMaskIntoConstraints = false
        showHideButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pinInputContainer.heightAnchor.constraint(equalToConstant: 48),
            
            pinTextField.leadingAnchor.constraint(equalTo: pinInputContainer.leadingAnchor, constant: 16),
            pinTextField.trailingAnchor.constraint(equalTo: showHideButton.leadingAnchor, constant: -8),
            pinTextField.topAnchor.constraint(equalTo: pinInputContainer.topAnchor),
            pinTextField.bottomAnchor.constraint(equalTo: pinInputContainer.bottomAnchor),
            
            showHideButton.trailingAnchor.constraint(equalTo: pinInputContainer.trailingAnchor, constant: -16),
            showHideButton.centerYAnchor.constraint(equalTo: pinInputContainer.centerYAnchor),
            showHideButton.widthAnchor.constraint(equalToConstant: 24),
            showHideButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    /// Setup PIN requirements validation view
    private func setupRequirementsView() {
        requirementsView.backgroundColor = .clear
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "PIN Requirements:"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        requirementsView.addSubview(titleLabel)
        
        // Create stack view for requirements
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        
        // Create requirement labels
        let requirements = [
            "At least 8 characters",
            "Contains numbers",
            "Contains special characters"
        ]
        
        for requirement in requirements {
            let label = UILabel()
            label.text = "✗ \(requirement)"
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = .systemRed
            requirementLabels.append(label)
            stackView.addArrangedSubview(label)
        }
        
        requirementsView.addSubview(stackView)
        contentStackView.addArrangedSubview(requirementsView)
        
        // Setup secure PIN storage info card
        setupSecurePINInfoCard()
        
        // Setup constraints
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: requirementsView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: requirementsView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: requirementsView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: requirementsView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: requirementsView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: requirementsView.bottomAnchor)
        ])
    }
    
    /// Setup secure PIN storage info card
    private func setupSecurePINInfoCard() {
        // Create info card container
        let infoCard = UIView()
        infoCard.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        infoCard.layer.cornerRadius = 12
        infoCard.layer.borderWidth = 1
        infoCard.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        
        // Create horizontal stack for icon and content
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 12
        horizontalStack.alignment = .top
        
        // Security icon
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "lock.shield.fill")
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        
        // Content stack for title and description
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.alignment = .leading
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "Secure PIN Storage"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemBlue
        
        // Description label
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Your PIN will be securely stored on your device and protected with biometric authentication."
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .systemBlue
        descriptionLabel.numberOfLines = 0
        
        // Add labels to content stack
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        
        // Add icon and content to horizontal stack
        horizontalStack.addArrangedSubview(iconView)
        horizontalStack.addArrangedSubview(contentStack)
        
        // Add horizontal stack to info card
        infoCard.addSubview(horizontalStack)
        
        // Add info card to main content stack
        contentStackView.addArrangedSubview(infoCard)
        
        // Setup constraints
        iconView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon constraints
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Horizontal stack constraints
            horizontalStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            horizontalStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            horizontalStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            horizontalStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])
    }
    
    /// Bind to onboarding state
    private func bindToState() {
        // Set initial value
        pinTextField.text = state.pin
        
        // Update validation
        updatePINValidation()
        updateButtonState()
    }
    
    /// Handle PIN text changes
    @objc private func pinTextChanged() {
        // SAFEGUARD: Protect against potential crashes during text changes
        guard let text = pinTextField.text else {
            print("🚨 [ERROR] pinTextChanged called with nil text")
            return
        }
        
        // SAFEGUARD: Limit PIN length to prevent performance issues
        let maxPINLength = 50
        if text.count > maxPINLength {
            let truncatedText = String(text.prefix(maxPINLength))
            pinTextField.text = truncatedText
            state.pin = truncatedText
        } else {
            state.pin = text
        }
        
        // SAFEGUARD: Wrap validation in try-catch to prevent crashes
        do {
            updatePINValidation()
            updateButtonState()
        } catch {
            print("🚨 [ERROR] PIN validation failed: \(error)")
            // Fallback: basic validation
            let hasMinLength = text.count >= 8
            let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
            let hasSpecialChars = text.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
            
            primaryButton.isEnabled = hasMinLength && hasNumbers && hasSpecialChars && !state.isLoading
            primaryButton.alpha = primaryButton.isEnabled ? 1.0 : 0.6
        }
        
        // Clear error when user starts typing
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    /// Toggle PIN visibility
    @objc private func togglePINVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        pinTextField.isSecureTextEntry = !sender.isSelected
    }
    
    /// Update PIN validation UI with error protection
    private func updatePINValidation() {
        // SAFEGUARD: Protect validation operations
        do {
            let validationResults = pinRequirements.validate(state.pin)
            
            for (index, result) in validationResults.enumerated() {
                guard index < requirementLabels.count else { continue }
                
                let label = requirementLabels[index]
                label.text = result.description
                label.textColor = result.isValid ? .systemGreen : .systemRed
            }
            
            // Update input border color
            let allValid = validationResults.allSatisfy { $0.isValid }
            if state.pin.isEmpty {
                pinInputContainer.layer.borderColor = UIColor.systemGray4.cgColor
            } else {
                pinInputContainer.layer.borderColor = allValid ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
            }
        } catch {
            print("🚨 [ERROR] updatePINValidation failed: \(error)")
            // Fallback: simple border color update
            pinInputContainer.layer.borderColor = state.pin.isEmpty ? UIColor.systemGray4.cgColor : UIColor.systemBlue.cgColor
        }
    }
    
    /// Update button state based on PIN validity with error protection
    private func updateButtonState() {
        // SAFEGUARD: Protect validation call
        let isValidPIN: Bool
        do {
            isValidPIN = state.validateCurrentStep()
        } catch {
            print("🚨 [ERROR] PIN validation crashed: \(error)")
            // Fallback validation
            isValidPIN = state.pin.count >= 8 && 
                        state.pin.rangeOfCharacter(from: .decimalDigits) != nil &&
                        state.pin.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        }
        
        primaryButton.isEnabled = isValidPIN && !state.isLoading
        primaryButton.alpha = isValidPIN ? 1.0 : 0.6
    }
    
    public override func setLoading(_ isLoading: Bool) {
        super.setLoading(isLoading)
        
        if !isLoading {
            primaryButton.setTitle("Create PIN", for: .normal)
        }
        
        pinTextField.isEnabled = !isLoading
        updateButtonState()
    }
    
    public override func primaryButtonTapped() {
        // Validate PIN before proceeding
        guard state.validateCurrentStep() else {
            state.errorMessage = "Please create a PIN that meets all requirements (8+ characters, numbers, special characters)"
            return
        }
        
        // Clear any existing error
        state.errorMessage = nil
        
        // Don't set loading state yet - wait for biometric auth
        print("🔐 [PIN] User tapped Create PIN button - starting biometric authentication")
        
        // Store PIN with biometric authentication
        Task {
            await storePINSecurely()
        }
    }
    
    /// Store PIN securely with biometric authentication and send to backend
    private func storePINSecurely() async {
        print("🔐 [PIN] Starting secure PIN storage process")
        
        // Add crash protection around the entire PIN storage process
        do {
            // Store PIN with biometric authentication (this will trigger Face ID)
            let result = await BiometricPINManager.shared.storePIN(state.pin)
            
            switch result {
            case .success:
                print("✅ [PIN] PIN stored securely with biometric protection")
                
                // NOW set loading state after successful biometric auth
                await MainActor.run {
                    primaryButton.setTitle("Submitting PIN...", for: .normal)
                    primaryButton.isEnabled = false
                    setLoading(true)
                }
                
                // Send PIN to backend with error boundary
                await submitPINToBackendSafely()
                
            case .failure(let error):
                await MainActor.run {
                    print("❌ [PIN] Failed to store PIN securely: \(error.localizedDescription)")
                    
                    // Show user-friendly error message based on error type
                    let errorMessage: String
                    switch error {
                    case .biometricNotAvailable:
                        errorMessage = "Face ID/Touch ID is not available on this device"
                    case .authenticationFailed:
                        errorMessage = "Face ID/Touch ID authentication failed. Please try again."
                    case .authenticationCancelled:
                        errorMessage = "Face ID/Touch ID authentication was cancelled. Please try again."
                    case .keychainError(let message):
                        errorMessage = "Security error: \(message)"
                    case .invalidPIN:
                        errorMessage = "Invalid PIN format"
                    case .pinNotFound:
                        errorMessage = "PIN not found"
                    }
                    
                    state.errorMessage = errorMessage
                    
                    // Button should remain in normal state since biometric auth failed
                    primaryButton.setTitle("Create PIN", for: .normal)
                    primaryButton.isEnabled = true
                    setLoading(false)
                }
            }
        } catch {
            // Catch any unexpected errors during PIN storage
            await MainActor.run {
                print("💥 [PIN] Unexpected error during PIN storage: \(error.localizedDescription)")
                state.errorMessage = "An unexpected error occurred while securing your PIN. Please try again."
                
                // Restore button state
                primaryButton.setTitle("Create PIN", for: .normal)
                primaryButton.isEnabled = true
                setLoading(false)
            }
        }
    }
    
    /// Submit PIN to backend with crash protection
    private func submitPINToBackendSafely() async {
        do {
            await submitPINToBackend()
        } catch {
            // Catch any unexpected errors during PIN submission
            await MainActor.run {
                print("💥 [PIN SUBMISSION] Unexpected error during PIN submission: \(error.localizedDescription)")
                
                // Show error but still proceed (PIN is stored locally with biometric protection)
                state.errorMessage = "PIN secured with Face ID but sync with server failed. You can continue."
                
                // Show warning state
                primaryButton.setTitle("PIN Secured with Face ID ✓", for: .normal)
                primaryButton.backgroundColor = UIColor.systemOrange
                
                // Proceed to next step after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.primaryButton.setTitle("Create PIN", for: .normal)
                    self.primaryButton.backgroundColor = UIColor.systemBlue
                    self.primaryButton.isEnabled = true
                    self.setLoading(false)
                    
                    // Proceed to next step
                    self.coordinator?.proceedToNextStep()
                }
            }
        }
    }
    
    /// Submit PIN to backend endpoint
    private func submitPINToBackend() async {
        // Get username from stored user data
        let username = UserDefaults.standard.string(forKey: "onairos_username") ?? ""
        
        guard !username.isEmpty else {
            await MainActor.run {
                print("❌ [PIN SUBMISSION] No username found in UserDefaults")
                state.errorMessage = "Username not found. Please restart the onboarding process."
                
                // Restore button state
                primaryButton.setTitle("Create PIN", for: .normal)
                primaryButton.isEnabled = true
                setLoading(false)
            }
            return
        }
        
        print("📤 [PIN SUBMISSION] Sending PIN to backend:")
        print("   - Username: \(username)")
        print("   - PIN: [REDACTED - \(state.pin.count) digits]")
        print("   - Endpoint: /store-pin/mobile")
        print("   - Timeout: 60s request, 120s resource")
        print("   - Retry: Up to 3 attempts with 2s delay")
        
        // Enable detailed logging for PIN submission debugging
        let apiClient = OnairosAPIClient.shared
        let originalLogLevel = apiClient.logLevel
        let originalDetailedLogging = apiClient.enableDetailedLogging
        
        // Temporarily enable verbose logging for PIN submission
        apiClient.logLevel = .verbose
        apiClient.enableDetailedLogging = true
        
        print("🔍 [PIN SUBMISSION] Enabled detailed logging for debugging")
        
        // Create PIN submission request
        let pinRequest = PINSubmissionRequest(
            username: username,
            pin: state.pin
        )
        
        // Submit PIN to backend with enhanced error handling
        let result = await apiClient.submitPIN(pinRequest)
        
        // Restore original logging settings
        apiClient.logLevel = originalLogLevel
        apiClient.enableDetailedLogging = originalDetailedLogging
        
        print("🔍 [PIN SUBMISSION] Restored original logging settings")
        
        await MainActor.run {
            switch result {
            case .success(let response):
                print("✅ [PIN SUBMISSION] PIN submitted successfully: \(response.message)")
                print("   - Success: \(response.success)")
                print("   - User ID: \(response.userId ?? "nil")")
                print("   - PIN Secured: \(response.pinSecured ?? false)")
                print("   - Timestamp: \(response.timestamp ?? "nil")")
                
                // Show success feedback briefly
                primaryButton.setTitle("PIN Secured with Face ID ✓", for: .normal)
                primaryButton.backgroundColor = UIColor.systemGreen
                
                // Brief success animation
                UIView.animate(withDuration: 0.3) {
                    self.primaryButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) {
                        self.primaryButton.transform = .identity
                    }
                }
                
                // Proceed to next step after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.primaryButton.setTitle("Create PIN", for: .normal)
                    self.primaryButton.backgroundColor = UIColor.systemBlue
                    self.primaryButton.isEnabled = true
                    self.setLoading(false)
                    
                    // Proceed to next step
                    self.coordinator?.proceedToNextStep()
                }
                
            case .failure(let error):
                print("❌ [PIN SUBMISSION] Failed to submit PIN: \(error.localizedDescription)")
                print("   - Error Category: \(error.category)")
                print("   - Is Recoverable: \(error.isRecoverable)")
                print("   - Recovery Suggestion: \(error.recoverySuggestion ?? "None")")
                
                // Handle different error types with appropriate user messaging
                let (userMessage, shouldProceed) = handlePINSubmissionError(error)
                
                print("   - User Message: \(userMessage)")
                print("   - Should Proceed: \(shouldProceed)")
                
                if shouldProceed {
                    // PIN is stored locally with Face ID, show warning but proceed
                    state.errorMessage = "PIN secured with Face ID but server sync failed. You can continue."
                    
                    // Show warning color briefly
                    primaryButton.setTitle("PIN Secured with Face ID ⚠️", for: .normal)
                    primaryButton.backgroundColor = UIColor.systemOrange
                    
                    // Proceed to next step after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.primaryButton.setTitle("Create PIN", for: .normal)
                        self.primaryButton.backgroundColor = UIColor.systemBlue
                        self.primaryButton.isEnabled = true
                        self.setLoading(false)
                        
                        // Proceed to next step
                        self.coordinator?.proceedToNextStep()
                    }
                } else {
                    // Critical error, don't proceed
                    state.errorMessage = userMessage
                    
                    // Show error state
                    primaryButton.setTitle("Try Again", for: .normal)
                    primaryButton.backgroundColor = UIColor.systemRed
                    primaryButton.isEnabled = true
                    setLoading(false)
                    
                    // Add retry button functionality
                    primaryButton.removeTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
                    primaryButton.addTarget(self, action: #selector(retryPINSubmission), for: .touchUpInside)
                    
                    // Reset to normal state after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.resetPINSubmissionUI()
                    }
                }
            }
        }
    }
    
    /// Handle PIN submission error and determine user messaging and next action
    /// - Parameter error: The error that occurred
    /// - Returns: Tuple of (user message, should proceed to next step)
    private func handlePINSubmissionError(_ error: OnairosError) -> (String, Bool) {
        switch error {
        case .networkUnavailable, .networkError:
            return ("Network connection issue. PIN secured with Face ID but server sync failed. You can continue.", true)
            
        case .serverError(let code, let message):
            if code >= 500 {
                return ("Server temporarily unavailable. PIN secured with Face ID. You can continue.", true)
            } else {
                return ("Server error (\(code)): \(message). Please try again.", false)
            }
            
        case .rateLimitExceeded:
            return ("Too many attempts. Please wait a moment and try again.", false)
            
        case .validationFailed(let reason):
            return ("PIN validation failed: \(reason). Please create a new PIN.", false)
            
        case .invalidCredentials:
            return ("Authentication failed. Please restart the onboarding process.", false)
            
        case .configurationError(let reason):
            return ("Configuration error: \(reason). Please contact support.", false)
            
        case .apiError(let message, _):
            // Check if it's a user-related error that allows proceeding
            if message.contains("User not found") {
                return ("User account issue. PIN secured with Face ID. You can continue.", true)
            } else {
                return ("API error: \(message). Please try again.", false)
            }
            
        case .unknownError(let message):
            if message.contains("timeout") || message.contains("connection") {
                return ("Connection timeout. PIN secured with Face ID. You can continue.", true)
            } else {
                return ("Unexpected error: \(message). Please try again.", false)
            }
            
        default:
            return ("PIN submission failed. PIN secured with Face ID. You can continue.", true)
        }
    }
    
    /// Retry PIN submission after error
    @objc private func retryPINSubmission() {
        print("🔄 [PIN SUBMISSION] User initiated retry")
        
        // Reset UI state
        resetPINSubmissionUI()
        
        // Clear any existing error
        state.errorMessage = nil
        
        // Retry the submission
        Task {
            await submitPINToBackend()
        }
    }
    
    /// Reset PIN submission UI to normal state
    private func resetPINSubmissionUI() {
        primaryButton.setTitle("Create PIN", for: .normal)
        primaryButton.backgroundColor = UIColor.systemBlue
        primaryButton.isEnabled = true
        setLoading(false)
        
        // Restore normal button action
        primaryButton.removeTarget(self, action: #selector(retryPINSubmission), for: .touchUpInside)
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
    }
    
    /// Authenticate with Face ID/Touch ID (legacy method - now handled by BiometricPINManager)
    /// - Parameter completion: Completion handler with success result
    private func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        // Check biometric availability using our new manager
        let availability = BiometricPINManager.shared.biometricAvailability()
        
        guard availability != .notAvailable else {
            print("🔐 [BIOMETRIC] Biometric authentication not available")
            completion(false)
            return
        }
        
        print("🔐 [BIOMETRIC] Biometric type available: \(availability.displayName)")
        completion(true)
    }
}

// MARK: - UITextFieldDelegate
extension PINStepViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if state.validateCurrentStep() {
            primaryButtonTapped()
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow alphanumeric characters and common special characters
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        
        // Allow reasonable PIN length (up to 50 characters for practical purposes)
        guard newLength <= 50 else { return false }
        
        // Allow alphanumeric characters and common special characters
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?")
        
        // Check if replacement string contains only allowed characters
        if !string.isEmpty && string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }
        
        return true
    }
} 