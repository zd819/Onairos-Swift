import UIKit

/// Email input step view controller
@MainActor
public class EmailStepViewController: BaseStepViewController {
    
    /// Email input field
    private let emailTextField = UITextField()
    
    /// Email input container view
    private let emailInputContainer = UIView()
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Welcome to Onairos"
        subtitleLabel.text = "Enter your email to get started"
        
        // Configure buttons
        primaryButton.setTitle("Continue", for: .normal)
        secondaryButton.setTitle("Cancel", for: .normal)
        
        // Setup email input
        setupEmailInput()
        
        // Bind to state
        bindToState()
    }
    
    /// Setup email input field
    private func setupEmailInput() {
        // Container view
        emailInputContainer.backgroundColor = .systemGray6
        emailInputContainer.layer.cornerRadius = 12
        emailInputContainer.layer.borderWidth = 1
        emailInputContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Text field
        emailTextField.placeholder = "Enter your email address"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.font = .systemFont(ofSize: 16)
        emailTextField.textColor = .label
        emailTextField.addTarget(self, action: #selector(emailTextChanged), for: .editingChanged)
        emailTextField.delegate = self
        
        // SAFEGUARD: Set return key type for better UX
        emailTextField.returnKeyType = .continue
        
        // Add to container
        emailInputContainer.addSubview(emailTextField)
        contentStackView.addArrangedSubview(emailInputContainer)
        
        // Setup constraints
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emailInputContainer.heightAnchor.constraint(equalToConstant: 48),
            
            emailTextField.leadingAnchor.constraint(equalTo: emailInputContainer.leadingAnchor, constant: 16),
            emailTextField.trailingAnchor.constraint(equalTo: emailInputContainer.trailingAnchor, constant: -16),
            emailTextField.topAnchor.constraint(equalTo: emailInputContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailInputContainer.bottomAnchor)
        ])
        
        // SAFEGUARD: Delay focus to ensure view is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Double-check the text field still exists before focusing
            if self.emailTextField.superview != nil {
                self.emailTextField.becomeFirstResponder()
            }
        }
    }
    
    /// Bind to onboarding state
    private func bindToState() {
        // Set initial value
        emailTextField.text = state.email
        
        // Update button state based on email validity
        updateButtonState()
    }
    
    /// Handle email text changes
    @objc private func emailTextChanged() {
        // SAFEGUARD: Protect against potential crashes during text changes
        guard let text = emailTextField.text else {
            print("🚨 [ERROR] emailTextChanged called with nil text")
            return
        }
        
        // SAFEGUARD: Limit email length to prevent performance issues
        let maxEmailLength = 254
        if text.count > maxEmailLength {
            let truncatedText = String(text.prefix(maxEmailLength))
            emailTextField.text = truncatedText
            state.email = truncatedText
        } else {
            state.email = text
        }
        
        // SAFEGUARD: Wrap validation in try-catch to prevent crashes
        do {
            updateButtonState()
        } catch {
            print("🚨 [ERROR] updateButtonState failed: \(error)")
            // Fallback: enable button for basic email format
            primaryButton.isEnabled = text.contains("@") && text.contains(".")
            primaryButton.alpha = primaryButton.isEnabled ? 1.0 : 0.6
        }
        
        // Clear error when user starts typing
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    /// Update button state based on email validity
    private func updateButtonState() {
        // SAFEGUARD: Protect validation call
        let isValidEmail: Bool
        do {
            isValidEmail = state.validateCurrentStep()
        } catch {
            print("🚨 [ERROR] Email validation crashed: \(error)")
            // Fallback validation
            isValidEmail = !state.email.isEmpty && state.email.contains("@") && state.email.contains(".")
        }
        
        primaryButton.isEnabled = isValidEmail && !state.isLoading
        primaryButton.alpha = isValidEmail ? 1.0 : 0.6
    }
    
    public override func setLoading(_ isLoading: Bool) {
        super.setLoading(isLoading)
        
        if !isLoading {
            primaryButton.setTitle("Continue", for: .normal)
        }
        
        emailTextField.isEnabled = !isLoading
        updateButtonState()
    }
    
    public override func primaryButtonTapped() {
        print("🔍 [DEBUG] EmailStepViewController.primaryButtonTapped() called")
        print("🔍 [DEBUG] Current email: '\(state.email)'")
        
        // SAFEGUARD: Ensure we have valid state before proceeding
        guard !state.isLoading else {
            print("🚨 [WARNING] primaryButtonTapped called while loading, ignoring")
            return
        }
        
        // SAFEGUARD: Protect validation call
        let isValidEmail: Bool
        do {
            isValidEmail = state.validateCurrentStep()
            print("🔍 [DEBUG] Email validation: \(isValidEmail)")
        } catch {
            print("🚨 [ERROR] Email validation crashed in primaryButtonTapped: \(error)")
            // Fallback validation
            isValidEmail = !state.email.isEmpty && state.email.contains("@") && state.email.contains(".")
            print("🔍 [DEBUG] Fallback email validation: \(isValidEmail)")
        }
        
        // Validate email before proceeding
        guard isValidEmail else {
            print("🔍 [DEBUG] Email validation failed in primaryButtonTapped")
            state.errorMessage = "Please enter a valid email address"
            return
        }
        
        print("🔍 [DEBUG] Email validation passed - clearing error and proceeding")
        
        // Clear any existing error
        state.errorMessage = nil
        
        // SAFEGUARD: Dismiss keyboard before proceeding to prevent keyboard-related crashes
        emailTextField.resignFirstResponder()
        
        // Proceed to next step
        print("🔍 [DEBUG] Calling super.primaryButtonTapped()")
        super.primaryButtonTapped()
    }
}

// MARK: - UITextFieldDelegate
extension EmailStepViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // SAFEGUARD: Ensure we have a valid text field and state
        guard textField == emailTextField else {
            print("🚨 [ERROR] textFieldShouldReturn called with wrong text field")
            return false
        }
        
        // SAFEGUARD: Protect validation call
        let isValid: Bool
        do {
            isValid = state.validateCurrentStep()
        } catch {
            print("🚨 [ERROR] Validation failed in textFieldShouldReturn: \(error)")
            // Fallback validation
            isValid = !(textField.text?.isEmpty ?? true) && 
                     (textField.text?.contains("@") ?? false) && 
                     (textField.text?.contains(".") ?? false)
        }
        
        if isValid {
            primaryButtonTapped()
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // SAFEGUARD: Ensure we have the correct text field
        guard textField == emailTextField else {
            print("🚨 [ERROR] shouldChangeCharactersIn called with wrong text field")
            return false
        }
        
        // SAFEGUARD: Prevent extremely long input that could cause performance issues
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // Limit to reasonable email length (RFC 5321 specifies 254 characters max)
        if prospectiveText.count > 254 {
            print("🚨 [WARNING] Email input too long, truncating")
            return false
        }
        
        // Allow all reasonable changes for email input
        return true
    }
    
    // SAFEGUARD: Add text field lifecycle methods to prevent crashes
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        // Ensure this is our text field
        guard textField == emailTextField else { return }
        
        // Clear any existing errors when user starts editing
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        // Ensure this is our text field
        guard textField == emailTextField else { return }
        
        // Update state with final text value
        state.email = textField.text ?? ""
    }
} 