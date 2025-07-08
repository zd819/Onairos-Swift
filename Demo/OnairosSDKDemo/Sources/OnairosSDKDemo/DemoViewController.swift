import UIKit
import OnairosSDK

class DemoViewController: UIViewController {
    
    private var connectButton: UIButton?
    private var statusLabel: UILabel!
    private var initButton: UIButton!
    private var clearButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Initialize SDK on app launch
        initializeSDK()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Onairos SDK Demo"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "SDK Status: Not Initialized"
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Initialize button
        initButton = UIButton(type: .system)
        initButton.setTitle("Initialize SDK", for: .normal)
        initButton.backgroundColor = .systemBlue
        initButton.setTitleColor(.white, for: .normal)
        initButton.layer.cornerRadius = 12
        initButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        initButton.translatesAutoresizingMaskIntoConstraints = false
        initButton.addTarget(self, action: #selector(initializeSDKTapped), for: .touchUpInside)
        view.addSubview(initButton)
        
        // Clear session button
        clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear Session", for: .normal)
        clearButton.backgroundColor = .systemRed
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 12
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearSessionTapped), for: .touchUpInside)
        view.addSubview(clearButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            initButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            initButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            initButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            initButton.heightAnchor.constraint(equalToConstant: 50),
            
            clearButton.topAnchor.constraint(equalTo: initButton.bottomAnchor, constant: 20),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            clearButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func initializeSDK() {
        Task {
            do {
                // Method 1: Initialize with admin key (recommended for development)
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .production,  // Use production API for OAuth to work
                    enableLogging: true
                )
                
                await MainActor.run {
                    self.statusLabel.text = "✅ SDK Status: Initialized with Admin Key"
                    self.addConnectButton()
                }
                
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "❌ SDK Status: Failed to initialize\n\(error.localizedDescription)"
                }
                
                // Fallback to legacy method
                self.initializeSDKLegacy()
            }
        }
    }
    
    private func initializeSDKLegacy() {
        // Method 2: Legacy initialization (always works)
        let config = OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true, // This prevents API calls during development
            allowEmptyConnections: true,
            simulateTraining: true,
            urlScheme: "onairos-demo",
            appName: "Onairos Demo App"
        )
        
        OnairosSDK.shared.initialize(config: config)
        
        statusLabel.text = "✅ SDK Status: Initialized with Legacy Config (Test Mode)"
        addConnectButton()
    }
    
    @objc private func initializeSDKTapped() {
        // Show different initialization options
        let alert = UIAlertController(title: "Initialize SDK", message: "Choose initialization method", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Admin Key (Async)", style: .default) { _ in
            self.initializeWithAdminKey()
        })
        
        alert.addAction(UIAlertAction(title: "Legacy Config (Test Mode)", style: .default) { _ in
            self.initializeSDKLegacy()
        })
        
        alert.addAction(UIAlertAction(title: "Custom API Key", style: .default) { _ in
            self.showCustomAPIKeyInput()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func initializeWithAdminKey() {
        Task {
            do {
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .development,
                    enableLogging: true
                )
                
                await MainActor.run {
                    self.statusLabel.text = "✅ SDK Status: Initialized with Admin Key"
                    self.addConnectButton()
                }
                
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "❌ SDK Status: Failed\n\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func showCustomAPIKeyInput() {
        let alert = UIAlertController(title: "Custom API Key", message: "Enter your API key", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter API Key"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Initialize", style: .default) { _ in
            guard let apiKey = alert.textFields?.first?.text, !apiKey.isEmpty else {
                self.statusLabel.text = "❌ SDK Status: No API key provided"
                return
            }
            
            self.initializeWithCustomKey(apiKey)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func initializeWithCustomKey(_ apiKey: String) {
        Task {
            do {
                try await OnairosSDK.shared.initializeWithApiKey(
                    apiKey,
                    environment: .development,
                    enableLogging: true
                )
                
                await MainActor.run {
                    self.statusLabel.text = "✅ SDK Status: Initialized with Custom Key"
                    self.addConnectButton()
                }
                
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "❌ SDK Status: Failed\n\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func addConnectButton() {
        // Remove existing connect button if any
        connectButton?.removeFromSuperview()
        
        // Create new connect button using SDK
        connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.handleOnboardingSuccess(data)
                case .failure(let error):
                    self.handleOnboardingError(error)
                }
            }
        }
        
        guard let connectButton = connectButton else { return }
        
        view.addSubview(connectButton)
        
        NSLayoutConstraint.activate([
            connectButton.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 40),
            connectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            connectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            connectButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func clearSessionTapped() {
        OnairosSDK.shared.clearSession()
        statusLabel.text = "🧹 Session cleared"
        
        // Show alert
        let alert = UIAlertController(title: "Session Cleared", message: "User session has been cleared", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func handleOnboardingSuccess(_ data: OnboardingData) {
        print("🎉 Onboarding completed successfully!")
        print("Connected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))")
        
        let alert = UIAlertController(
            title: "Success! 🎉",
            message: "Onboarding completed successfully!\n\nConnected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default))
        present(alert, animated: true)
        
        statusLabel.text = "✅ Onboarding completed successfully!"
    }
    
    private func handleOnboardingError(_ error: OnairosError) {
        print("❌ Onboarding failed: \(error.localizedDescription)")
        
        let alert = UIAlertController(
            title: "Onboarding Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        statusLabel.text = "❌ Onboarding failed: \(error.localizedDescription)"
    }
} 