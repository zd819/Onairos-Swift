import UIKit

/// Email verification step view controller
@MainActor
public class VerifyStepViewController: BaseStepViewController {
    
    /// Code input fields container
    private let codeInputContainer = UIView()
    
    /// Individual code input fields
    private var codeInputFields: [UITextField] = []
    
    /// Development mode indicator
    private let devModeLabel = UILabel()
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Verify Your Email"
        subtitleLabel.text = "Enter the 6-digit code sent to\n\(state.email)"
        
        // Configure buttons
        primaryButton.setTitle("Verify", for: .normal)
        secondaryButton.setTitle("Back to Email", for: .normal)
        
        // Setup code input
        setupCodeInput()
        
        // Show development mode indicator if needed
        if config.isDebugMode {
            setupDevModeIndicator()
        }
        
        // Bind to state
        bindToState()
    }
    
    /// Setup 6-digit code input fields
    private func setupCodeInput() {
        codeInputContainer.backgroundColor = .clear
        
        // Create stack view for code inputs
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        
        // Create 6 input fields
        for i in 0..<6 {
            let textField = createCodeInputField(tag: i)
            codeInputFields.append(textField)
            stackView.addArrangedSubview(textField)
        }
        
        codeInputContainer.addSubview(stackView)
        contentStackView.addArrangedSubview(codeInputContainer)
        
        // Setup constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            codeInputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            stackView.leadingAnchor.constraint(equalTo: codeInputContainer.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: codeInputContainer.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: codeInputContainer.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: codeInputContainer.bottomAnchor)
        ])
        
        // Focus on first field
        DispatchQueue.main.async {
            self.codeInputFields.first?.becomeFirstResponder()
        }
    }
    
    /// Create individual code input field
    /// - Parameter tag: Field index
    /// - Returns: Configured text field
    private func createCodeInputField(tag: Int) -> UITextField {
        let textField = UITextField()
        textField.tag = tag
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 24, weight: .semibold)
        textField.keyboardType = .numberPad
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.delegate = self
        textField.addTarget(self, action: #selector(codeTextChanged(_:)), for: .editingChanged)
        
        // Set fixed size
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalToConstant: 48),
            textField.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return textField
    }
    
    /// Setup development mode indicator
    private func setupDevModeIndicator() {
        devModeLabel.text = "Development Mode: Any code will work"
        devModeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        devModeLabel.textColor = .systemOrange
        devModeLabel.textAlignment = .center
        devModeLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        devModeLabel.layer.cornerRadius = 8
        devModeLabel.layer.masksToBounds = true
        
        contentStackView.addArrangedSubview(devModeLabel)
        
        devModeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            devModeLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    /// Bind to onboarding state
    private func bindToState() {
        updateButtonState()
    }
    
    /// Handle code text changes
    @objc private func codeTextChanged(_ textField: UITextField) {
        // Limit to single digit
        if let text = textField.text, text.count > 1 {
            textField.text = String(text.prefix(1))
        }
        
        // Update border color
        updateFieldAppearance(textField)
        
        // Auto-advance to next field
        if let text = textField.text, !text.isEmpty {
            moveToNextField(from: textField.tag)
        }
        
        // Update state and button
        updateVerificationCode()
        updateButtonState()
        
        // Clear error when user starts typing
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    /// Update field appearance based on content
    /// - Parameter textField: Text field to update
    private func updateFieldAppearance(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            textField.layer.borderColor = UIColor.systemBlue.cgColor
            textField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else {
            textField.layer.borderColor = UIColor.systemGray4.cgColor
            textField.backgroundColor = .systemGray6
        }
    }
    
    /// Move focus to next input field
    /// - Parameter currentIndex: Current field index
    private func moveToNextField(from currentIndex: Int) {
        let nextIndex = currentIndex + 1
        if nextIndex < codeInputFields.count {
            codeInputFields[nextIndex].becomeFirstResponder()
        } else {
            // All fields filled, try to verify
            view.endEditing(true)
            if state.validateCurrentStep() {
                primaryButtonTapped()
            }
        }
    }
    
    /// Move focus to previous input field
    /// - Parameter currentIndex: Current field index
    private func moveToPreviousField(from currentIndex: Int) {
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            codeInputFields[previousIndex].becomeFirstResponder()
        }
    }
    
    /// Update verification code in state
    private func updateVerificationCode() {
        let code = codeInputFields.compactMap { $0.text }.joined()
        state.verificationCode = code
    }
    
    /// Update button state based on code validity
    private func updateButtonState() {
        let isValidCode = state.validateCurrentStep()
        primaryButton.isEnabled = isValidCode && !state.isLoading
        primaryButton.alpha = isValidCode ? 1.0 : 0.6
    }
    
    public override func setLoading(_ isLoading: Bool) {
        super.setLoading(isLoading)
        
        if !isLoading {
            primaryButton.setTitle("Verify", for: .normal)
        }
        
        codeInputFields.forEach { $0.isEnabled = !isLoading }
        updateButtonState()
    }
    
    public override func primaryButtonTapped() {
        // Validate code before proceeding
        guard state.validateCurrentStep() else {
            state.errorMessage = "Please enter the complete 6-digit code"
            return
        }
        
        // Clear any existing error
        state.errorMessage = nil
        
        // Proceed to next step
        super.primaryButtonTapped()
    }
    
    /// Clear all input fields
    private func clearAllFields() {
        codeInputFields.forEach { textField in
            textField.text = ""
            updateFieldAppearance(textField)
        }
        updateVerificationCode()
        updateButtonState()
        codeInputFields.first?.becomeFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension VerifyStepViewController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only allow single digits
        if string.isEmpty {
            // Allow deletion
            return true
        }
        
        // Check if it's a digit
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        
        // Only allow single digit input
        return allowedCharacters.isSuperset(of: characterSet) && string.count == 1 && textField.text?.count == 0
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateFieldAppearance(textField)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateFieldAppearance(textField)
    }
    
    /// Handle backspace to move to previous field
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
} 