import UIKit
import WebKit

/// OAuth WebView controller for platform authentication
@MainActor
public class OAuthWebViewController: UIViewController {
    
    /// Platform being authenticated
    private let platform: Platform
    
    /// Configuration
    private let config: OnairosConfig
    
    /// User email for username extraction
    private let userEmail: String
    
    /// Completion callback
    private let completion: (Result<String, OnairosError>) -> Void
    
    /// WebView for OAuth
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    /// Loading indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    /// Close button
    private let closeButton = UIButton(type: .system)
    
    /// Progress view
    private var progressView: UIProgressView?
    
    /// Loading label
    private var loadingLabel: UILabel?
    
    /// Initialize OAuth WebView controller
    /// - Parameters:
    ///   - platform: Platform to authenticate
    ///   - config: SDK configuration
    ///   - userEmail: User email for username extraction
    ///   - completion: Completion callback with auth code
    init(
        platform: Platform,
        config: OnairosConfig,
        userEmail: String,
        completion: @escaping (Result<String, OnairosError>) -> Void
    ) {
        self.platform = platform
        self.config = config
        self.userEmail = userEmail
        self.completion = completion
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .formSheet
        if #available(iOS 15.0, *) {
            sheetPresentationController?.detents = [.large()]
            sheetPresentationController?.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startOAuthFlow()
    }
    
    /// Setup UI components
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Header view
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "Connect to \(platform.displayName)"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Sign in to authorize access"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Close button
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading label
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading authorization page..."
        loadingLabel.font = .systemFont(ofSize: 14, weight: .regular)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress view
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.alpha = 0
        
        // Add subviews
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(webView)
        view.addSubview(loadingIndicator)
        view.addSubview(loadingLabel)
        view.addSubview(progressView)
        
        // Store references for later use
        self.progressView = progressView
        self.loadingLabel = loadingLabel
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 70),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            // WebView
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Loading label
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            loadingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    /// Start OAuth authentication flow
    private func startOAuthFlow() {
        let authURL = buildOAuthURL()
        let request = URLRequest(url: authURL)
        
        loadingIndicator.startAnimating()
        webView.load(request)
    }
    
    /// Build OAuth URL for platform
    /// - Returns: OAuth authorization URL
    private func buildOAuthURL() -> URL {
        let baseURL = config.apiBaseURL
        let redirectURI = "\(config.urlScheme)://oauth/callback"
        
        // Extract username from email (part before @)
        let username = extractUsername(from: userEmail)
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/\(platform.rawValue)/authorize") else {
            // Fallback to a basic URL if components creation fails
            return URL(string: "\(baseURL)/\(platform.rawValue)/authorize")!
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: platform.oauthScopes),
            URLQueryItem(name: "state", value: generateStateParameter()),
            URLQueryItem(name: "email", value: userEmail),
            URLQueryItem(name: "username", value: username)
        ]
        
        return urlComponents.url ?? URL(string: "\(baseURL)/\(platform.rawValue)/authorize")!
    }
    
    /// Extract username from email address
    /// - Parameter email: Full email address
    /// - Returns: Username (part before @)
    private func extractUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? email
    }
    
    /// Generate state parameter for OAuth security
    /// - Returns: Random state string
    private func generateStateParameter() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement() ?? "a" })
    }
    
    /// Handle close button tap
    @objc private func closeButtonTapped() {
        completion(.failure(.userCancelled))
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension OAuthWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
        loadingLabel?.text = "Loading authorization page..."
        
        // Show progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 1.0
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        loadingLabel?.text = ""
        
        // Hide progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 0.0
        }
        
        // Check if we've been redirected to the success page
        if let url = webView.url, url.absoluteString.contains("onairos.uk/Home") {
            // Backend has successfully processed the OAuth callback
            loadingLabel?.text = "Authorization successful!"
            handleSuccessfulRedirect()
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        loadingLabel?.text = "Failed to load authorization page"
        
        // Hide progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 0.0
        }
        
        // Show error message
        showError(message: "Connection failed. Please check your internet connection and try again.")
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.completion(.failure(.networkError(error.localizedDescription)))
            self.dismiss(animated: true)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        loadingLabel?.text = "Failed to connect to authorization server"
        
        // Hide progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 0.0
        }
        
        // Show error message
        showError(message: "Unable to connect to \(platform.displayName). Please try again later.")
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.completion(.failure(.networkError(error.localizedDescription)))
            self.dismiss(animated: true)
        }
    }
    
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        print("🔍 [OAuth] Navigating to: \(url.absoluteString)")
        
        // Check if this is our custom URL scheme callback (fallback)
        if url.scheme == config.urlScheme && url.host == "oauth" {
            handleOAuthCallback(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Check if this is the backend success redirect
        if url.absoluteString.contains("onairos.uk/Home") {
            loadingLabel?.text = "Completing authorization..."
            // Allow the navigation to complete, then handle success
            decisionHandler(.allow)
            return
        }
        
        // Update loading message based on URL
        if url.absoluteString.contains("authorize") {
            loadingLabel?.text = "Preparing authorization..."
        } else if url.absoluteString.contains("login") {
            loadingLabel?.text = "Loading sign-in page..."
        } else if url.absoluteString.contains("callback") {
            loadingLabel?.text = "Processing authorization..."
        }
        
        // Allow all other navigation
        decisionHandler(.allow)
    }
    
    /// Show error message to user
    /// - Parameter message: Error message to display
    private func showError(message: String) {
        let alertController = UIAlertController(title: "Authorization Error", message: message, preferredStyle: .alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.startOAuthFlow()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.completion(.failure(.userCancelled))
            self?.dismiss(animated: true)
        }
        
        alertController.addAction(retryAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    /// Handle successful backend redirect
    private func handleSuccessfulRedirect() {
        // Show success feedback
        loadingLabel?.text = "✅ Authorization successful!"
        
        // Generate a success token for the platform connection
        let successToken = generateStateParameter()
        completion(.success(successToken))
        
        // Dismiss with a slight delay to ensure smooth UI transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dismiss(animated: true)
        }
    }
    
    /// Handle OAuth callback URL (fallback method)
    /// - Parameter url: Callback URL with auth code
    private func handleOAuthCallback(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else {
            completion(.failure(.authenticationFailed("Invalid callback URL")))
            dismiss(animated: true)
            return
        }
        
        // Extract authorization code
        if let authCode = queryItems.first(where: { $0.name == "code" })?.value {
            loadingLabel?.text = "✅ Authorization complete!"
            completion(.success(authCode))
            
            // Dismiss with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dismiss(animated: true)
            }
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
            completion(.failure(.authenticationFailed(errorDescription)))
            dismiss(animated: true)
        } else {
            completion(.failure(.authenticationFailed("No authorization code received")))
            dismiss(animated: true)
        }
    }
}

// MARK: - Platform OAuth Extensions
// Note: oauthScopes is now defined in OnboardingModels.swift as a public property 