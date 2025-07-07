import UIKit
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
        pinTextField.placeholder = "Enter your PIN (min 8 characters)"
        pinTextField.isSecureTextEntry = true
        pinTextField.font = .systemFont(ofSize: 16)
        pinTextField.textColor = .label
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
        state.pin = pinTextField.text ?? ""
        updatePINValidation()
        updateButtonState()
        
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
    
    /// Update PIN validation UI
    private func updatePINValidation() {
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
    }
    
    /// Update button state based on PIN validity
    private func updateButtonState() {
        let isValidPIN = state.validateCurrentStep()
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
            state.errorMessage = "Please create a PIN that meets all requirements"
            return
        }
        
        // Clear any existing error
        state.errorMessage = nil
        
        // Update button to show storage is in progress
        primaryButton.setTitle("Securing PIN...", for: .normal)
        primaryButton.isEnabled = false
        setLoading(true)
        
        // Store PIN with biometric authentication
        Task {
            await storePINSecurely()
        }
    }
    
    /// Store PIN securely with biometric authentication and send to backend
    private func storePINSecurely() async {
        do {
            // Store PIN with biometric authentication
            let result = await BiometricPINManager.shared.storePIN(state.pin)
            
            switch result {
            case .success:
                print("✅ [PIN] PIN stored securely with biometric protection")
                
                // Send PIN to backend
                await submitPINToBackend()
                
            case .failure(let error):
                await MainActor.run {
                    print("❌ [PIN] Failed to store PIN securely: \(error.localizedDescription)")
                    
                    // Show user-friendly error message
                    state.errorMessage = "Failed to secure your PIN: \(error.localizedDescription)"
                    
                    // Restore button state
                    primaryButton.setTitle("Create PIN", for: .normal)
                    primaryButton.isEnabled = true
                    setLoading(false)
                }
            }
        }
    }
    
    /// Submit PIN to backend endpoint
    private func submitPINToBackend() async {
        do {
            // Get username from stored user data
            let username = UserDefaults.standard.string(forKey: "onairos_username") ?? ""
            
            print("📤 [PIN SUBMISSION] Sending PIN to backend:")
            print("   - Username: \(username)")
            print("   - PIN: [REDACTED]")
            
            // Create PIN submission request
            let pinRequest = PINSubmissionRequest(
                username: username,
                pin: state.pin
            )
            
            // Submit PIN to backend
            let result = await OnairosAPIClient.shared.submitPIN(pinRequest)
            
            switch result {
            case .success(let response):
                await MainActor.run {
                    print("✅ [PIN SUBMISSION] PIN submitted successfully: \(response.message)")
                    
                    // Restore button state and proceed
                    primaryButton.setTitle("Create PIN", for: .normal)
                    primaryButton.isEnabled = true
                    setLoading(false)
                    
                    // Proceed to next step
                    coordinator?.proceedToNextStep()
                }
                
            case .failure(let error):
                await MainActor.run {
                    print("❌ [PIN SUBMISSION] Failed to submit PIN: \(error.localizedDescription)")
                    
                    // Show error but still proceed (PIN is stored locally)
                    state.errorMessage = "PIN secured locally but failed to sync with server. You can continue."
                    
                    // Restore button state and proceed anyway
                    primaryButton.setTitle("Create PIN", for: .normal)
                    primaryButton.isEnabled = true
                    setLoading(false)
                    
                    // Proceed to next step after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.coordinator?.proceedToNextStep()
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                print("❌ [PIN SUBMISSION] Unexpected error: \(error.localizedDescription)")
                
                // Show error but still proceed (PIN is stored locally)
                state.errorMessage = "PIN secured locally but failed to sync with server. You can continue."
                
                // Restore button state and proceed anyway
                primaryButton.setTitle("Create PIN", for: .normal)
                primaryButton.isEnabled = true
                setLoading(false)
                
                // Proceed to next step after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.coordinator?.proceedToNextStep()
                }
            }
        }
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
        // Allow reasonable PIN length (up to 50 characters)
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 50
    }
} 