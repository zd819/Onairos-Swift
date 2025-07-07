import UIKit
import OnairosSDK

/// Demo view controller showing Onairos SDK integration
class DemoViewController: UIViewController {
    
    /// Onairos connect button
    private var connectButton: UIButton!
    
    /// Custom text button
    private var customButton: UIButton!
    
    /// Status label
    private let statusLabel = UILabel()
    
    /// Result text view
    private let resultTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureSDK()
    }
    
    /// Setup UI components
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Onairos SDK Demo"
        
        // Status label
        statusLabel.text = "Ready to connect data"
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Result text view
        resultTextView.font = .systemFont(ofSize: 14)
        resultTextView.backgroundColor = .systemGray6
        resultTextView.layer.cornerRadius = 8
        resultTextView.isEditable = false
        resultTextView.text = "Onboarding results will appear here..."
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create buttons
        createConnectButtons()
        
        // Add subviews
        view.addSubview(statusLabel)
        view.addSubview(connectButton)
        view.addSubview(customButton)
        view.addSubview(resultTextView)
        
        // Setup constraints
        setupConstraints()
    }
    
    /// Create connect buttons using SDK
    private func createConnectButtons() {
        // Default button
        connectButton = OnairosSDK.shared.createConnectButton(
            completion: handleOnboardingResult
        )
        
        // Custom text button
        customButton = OnairosSDK.shared.createConnectButton(
            text: "Start Onboarding",
            completion: handleOnboardingResult
        )
    }
    
    /// Setup Auto Layout constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Status label
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Connect button
            connectButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Custom button
            customButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            customButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Result text view
            resultTextView.topAnchor.constraint(equalTo: customButton.bottomAnchor, constant: 40),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    /// Configure Onairos SDK
    private func configureSDK() {
        // ✅ CORRECT CONFIGURATION FOR DEVELOPMENT:
        // Use testMode() to prevent modal dismissal issues and API failures
        let config = OnairosConfig.testMode(
            urlScheme: "onairos-demo",
            appName: "Onairos Demo App"
        )
        
        // 🚨 INCORRECT CONFIGURATIONS (commented out to show what NOT to use):
        /*
        // ❌ DON'T USE: Debug mode with production API - may cause modal dismissal
        let badConfig1 = OnairosConfig(
            isDebugMode: true,
            urlScheme: "onairos-demo",
            appName: "Onairos Demo App"
        )
        
        // ❌ DON'T USE: Production mode during development - requires real platform connections
        let badConfig2 = OnairosConfig(
            isDebugMode: false,
            isTestMode: false,
            urlScheme: "onairos-demo",
            appName: "Onairos Demo App"
        )
        */
        
        print("🔧 [DEMO] Initializing SDK with test mode configuration...")
        OnairosSDK.shared.initialize(config: config)
        print("✅ [DEMO] SDK initialized - this configuration prevents modal dismissal issues")
        
        // Check for existing session
        if OnairosSDK.shared.hasExistingSession() {
            statusLabel.text = "Welcome back! Session found."
            statusLabel.textColor = .systemGreen
            
            // Add reset session button for demo purposes
            addResetSessionButton()
        } else {
            statusLabel.text = "Ready to connect data"
            statusLabel.textColor = .label
        }
        
        // Add configuration info to result view
        let configInfo = """
        ✅ DEMO CONFIGURATION:
        
        🧪 Test Mode: Enabled
        🔄 Simulates all API calls locally
        📧 Accepts any email address
        🔐 Accepts any verification code
        🚀 Prevents modal dismissal issues
        
        🔧 For your app, use:
        OnairosConfig.testMode(
            urlScheme: "your-app-scheme",
            appName: "Your App Name"
        )
        
        📚 See integration guide for production setup
        """
        
        resultTextView.text = configInfo
    }
    
    /// Add reset session button for demo purposes
    private func addResetSessionButton() {
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Clear Saved Session", for: .normal)
        resetButton.backgroundColor = .systemRed.withAlphaComponent(0.1)
        resetButton.setTitleColor(.systemRed, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        resetButton.layer.cornerRadius = 8
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        resetButton.addTarget(self, action: #selector(resetSessionTapped), for: .touchUpInside)
        
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 32),
            resetButton.widthAnchor.constraint(equalToConstant: 160)
        ])
        
        // Update other constraints to account for the new button
        connectButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 30).isActive = true
    }
    
    /// Handle reset session button tap
    @objc private func resetSessionTapped() {
        OnairosSDK.shared.clearSession()
        
        // Update UI
        statusLabel.text = "Session cleared. Ready to connect data."
        statusLabel.textColor = .label
        
        // Remove the reset button
        view.subviews.first { $0 is UIButton && ($0 as? UIButton)?.titleLabel?.text == "Clear Saved Session" }?.removeFromSuperview()
    }
    
    /// Handle onboarding completion result
    /// - Parameter result: Onboarding result
    private func handleOnboardingResult(_ result: Result<OnboardingResult, OnairosError>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                self.handleSuccess(data)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    /// Handle successful onboarding
    /// - Parameter data: Onboarding result data
    private func handleSuccess(_ data: OnboardingResult) {
        statusLabel.text = "Onboarding completed successfully! 🎉"
        statusLabel.textColor = .systemGreen
        
        switch data {
        case .success(let onboardingData):
            let resultText = """
            ✅ ONBOARDING COMPLETED
            
            📧 Email: \(onboardingData.userData["email"]?.value as? String ?? "N/A")
            🔗 Connected Platforms: \(onboardingData.connectedPlatforms.keys.joined(separator: ", "))
            💾 Session Saved: \(onboardingData.sessionSaved ? "Yes" : "No")
            🤖 AI Training: Completed
            
            📊 User Data:
            \(formatUserData(onboardingData.userData.mapValues { $0.value }))
            
            🔗 Platform Data:
            \(formatPlatformData(onboardingData.connectedPlatforms.mapValues { $0.platform }))
            
            👤 Account Info:
            \(formatAccountInfo(onboardingData.accountInfo?.mapValues { $0.value }))
            
            🔗 API URL: \(onboardingData.apiURL)
            🔑 Token: \(onboardingData.token.prefix(20))...
            """
            
            resultTextView.text = resultText
            
        case .failure(let error):
            // This shouldn't happen since we're in handleSuccess, but handle it anyway
            handleError(error)
        }
    }
    
    /// Handle onboarding error
    /// - Parameter error: Onboarding error
    private func handleError(_ error: OnairosError) {
        statusLabel.text = "Onboarding failed"
        statusLabel.textColor = .systemRed
        
        let resultText = """
        ❌ ONBOARDING FAILED
        
        Error: \(error.localizedDescription)
        
        Category: \(error.category.rawValue)
        
        Recovery Suggestion:
        \(error.recoverySuggestion)
        
        Please try again or contact support.
        """
        
        resultTextView.text = resultText
        
        // Show alert for critical errors
        if error.category == .critical {
            showErrorAlert(error)
        }
    }
    
    /// Format user data for display
    /// - Parameter userData: User data dictionary
    /// - Returns: Formatted string
    private func formatUserData(_ userData: [String: Any]) -> String {
        var formatted = ""
        for (key, value) in userData {
            formatted += "  • \(key): \(value)\n"
        }
        return formatted.isEmpty ? "  No user data" : formatted
    }
    
    /// Format platform data for display
    /// - Parameter platformData: Platform data dictionary
    /// - Returns: Formatted string
    private func formatPlatformData(_ platformData: [String: Any]) -> String {
        var formatted = ""
        for (platform, data) in platformData {
            formatted += "  • \(platform.capitalized): Connected\n"
        }
        return formatted.isEmpty ? "  No platforms connected" : formatted
    }
    
    /// Format account info for display
    /// - Parameter accountInfo: Account info dictionary
    /// - Returns: Formatted string
    private func formatAccountInfo(_ accountInfo: [String: Any]?) -> String {
        guard let accountInfo = accountInfo else {
            return "  No existing account info"
        }
        
        var formatted = ""
        for (key, value) in accountInfo {
            formatted += "  • \(key): \(value)\n"
        }
        return formatted.isEmpty ? "  No account info" : formatted
    }
    
    /// Show error alert
    /// - Parameter error: Error to display
    private func showErrorAlert(_ error: OnairosError) {
        let alert = UIAlertController(
            title: "Onboarding Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if !error.recoverySuggestion.isEmpty {
            alert.addAction(UIAlertAction(title: "Help", style: .default) { _ in
                // Show recovery suggestion
                let helpAlert = UIAlertController(
                    title: "How to Fix",
                    message: error.recoverySuggestion,
                    preferredStyle: .alert
                )
                helpAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(helpAlert, animated: true)
            })
        }
        
        present(alert, animated: true)
    }
} 