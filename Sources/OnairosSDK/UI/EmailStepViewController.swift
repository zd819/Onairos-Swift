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
        
        // Focus on email field
        DispatchQueue.main.async {
            self.emailTextField.becomeFirstResponder()
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
        state.email = emailTextField.text ?? ""
        updateButtonState()
        
        // Clear error when user starts typing
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    /// Update button state based on email validity
    private func updateButtonState() {
        let isValidEmail = state.validateCurrentStep()
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
        print("🔍 [DEBUG] Email validation: \(state.validateCurrentStep())")
        
        // Validate email before proceeding
        guard state.validateCurrentStep() else {
            print("🔍 [DEBUG] Email validation failed in primaryButtonTapped")
            state.errorMessage = "Please enter a valid email address"
            return
        }
        
        print("🔍 [DEBUG] Email validation passed - clearing error and proceeding")
        
        // Clear any existing error
        state.errorMessage = nil
        
        // Proceed to next step
        print("🔍 [DEBUG] Calling super.primaryButtonTapped()")
        super.primaryButtonTapped()
    }
}

// MARK: - UITextFieldDelegate
extension EmailStepViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if state.validateCurrentStep() {
            primaryButtonTapped()
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow all changes for email input
        return true
    }
} 