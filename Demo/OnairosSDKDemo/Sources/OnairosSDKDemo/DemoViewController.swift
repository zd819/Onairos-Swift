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
            target: self,
            completion: handleOnboardingResult
        )
        
        // Custom text button
        customButton = OnairosSDK.shared.createConnectButton(
            text: "Start Onboarding",
            target: self,
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
        let config = OnairosConfig(
            isDebugMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            platforms: [.instagram, .youtube, .reddit, .pinterest, .gmail],
            urlScheme: "onairos-demo",
            appName: "Onairos Demo App"
        )
        
        OnairosSDK.shared.initialize(config: config)
        
        // Check for existing session
        if OnairosSDK.shared.hasExistingSession() {
            statusLabel.text = "Welcome back! Session found."
            statusLabel.textColor = .systemGreen
        }
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
        
        let resultText = """
        ✅ ONBOARDING COMPLETED
        
        📧 Email: \(data.email ?? "N/A")
        🔗 Connected Platforms: \(data.connectedPlatforms.joined(separator: ", "))
        💾 Session Saved: \(data.sessionSaved ? "Yes" : "No")
        🤖 AI Training: \(data.trainingCompleted ? "Completed" : "Pending")
        
        📊 User Data:
        \(formatUserData(data.userData))
        
        🔗 Platform Data:
        \(formatPlatformData(data.platformData))
        """
        
        resultTextView.text = resultText
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