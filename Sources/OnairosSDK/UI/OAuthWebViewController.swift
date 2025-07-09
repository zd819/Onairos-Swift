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
        
        // Configure for better OAuth compatibility
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Enable JavaScript (required for OAuth)
        configuration.preferences.javaScriptEnabled = true
        
        // Configure user content controller
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        // Add user script to handle OAuth redirects
        let userScript = WKUserScript(
            source: """
            // Handle OAuth redirects and improve compatibility
            window.addEventListener('beforeunload', function(e) {
                console.log('Page unloading: ' + window.location.href);
            });
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(userScript)
        
        // Create webview with configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure webview for OAuth compatibility
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        
        // Set proper user agent to avoid Google blocking (only if secure OAuth is enabled)
        if config.enableSecureOAuth {
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1 OnairosSDK/3.0.72"
        }
        
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
    
    /// Flag to track if we're currently loading
    private var isLoading = false
    
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
        
        // Force light mode for OAuth web view
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        // Configure secure context for OAuth
        configureSecureContext()
        
        setupUI()
        startOAuthFlow()
    }
    
    /// Configure secure context for OAuth compliance
    private func configureSecureContext() {
        // Only configure secure context if enabled in config
        guard config.enableSecureOAuth else {
            print("⚠️ [OAuth] Secure OAuth is disabled in configuration")
            return
        }
        
        print("🔒 [OAuth] Configuring secure context for OAuth")
        
        // Configure data store for secure cookies (iOS 14+)
        let dataStore = WKWebsiteDataStore.default()
        webView.configuration.websiteDataStore = dataStore
        
        // Configure SSL settings for secure communication
        webView.configuration.processPool = WKProcessPool()
        
        // Enable secure context features (iOS 17.0+)
        if #available(iOS 17.0, *) {
            webView.configuration.websiteDataStore.httpCookieStore.setCookiePolicy(.allow) { 
                print("🍪 [OAuth] Cookie policy set to allow")
            }
        } else {
            // For iOS 14-16, configure alternative secure settings
            print("🍪 [OAuth] Using iOS 14-16 compatible secure configuration")
            
            // Enable secure preferences that are available in iOS 14
            webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
            webView.configuration.allowsInlineMediaPlayback = false
            webView.configuration.mediaTypesRequiringUserActionForPlayback = .all
        }
        
        // Set secure preferences (iOS 15.4+)
        if #available(iOS 15.4, *) {
            webView.configuration.preferences.isElementFullscreenEnabled = false
        }
        
        // Set text interaction preferences (iOS 14.5+)
        if #available(iOS 14.5, *) {
            webView.configuration.preferences.isTextInteractionEnabled = true
        }
        
        // Additional security configurations for iOS 14+
        if #available(iOS 14.0, *) {
            // Disable automatic data detection to prevent security issues
            webView.configuration.dataDetectorTypes = []
            
            // Configure selection granularity for better security
            webView.configuration.selectionGranularity = .character
        }
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
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.backgroundColor = .systemBackground
        closeButton.layer.cornerRadius = 8
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.systemBlue.cgColor
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure button is interactive and receives touches
        closeButton.isUserInteractionEnabled = true
        closeButton.isEnabled = true
        
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
        isLoading = true
        loadingIndicator.startAnimating()
        
        // YouTube uses native SDK, not webview OAuth
        if platform == .youtube {
            print("⚠️ [OAuth] YouTube should use native SDK, not webview OAuth")
            showError(message: "YouTube authentication should use native SDK")
            return
        }
        
        loadingLabel?.text = "Requesting authorization URL..."
        
        // First, fetch the authorization URL from the backend
        Task {
            do {
                let result = await OnairosAPIClient.shared.getAuthorizationURL(platform: platform, userEmail: userEmail)
                
                await MainActor.run {
                    switch result {
                    case .success(let response):
                        if response.success, let authURL = response.authorizationURL(for: platform) {
                            // Successfully got authorization URL, now open it in webview
                            print("✅ [OAuth] Successfully received authorization URL for \(platform.displayName)")
                            print("🔗 [OAuth] URL: \(authURL)")
                            self.loadWebViewWithURL(authURL)
                        } else {
                            let errorMessage = response.error ?? "Failed to get authorization URL"
                            print("❌ [OAuth] Backend returned error: \(errorMessage)")
                            self.showError(message: errorMessage)
                        }
                    case .failure(let error):
                        print("❌ [OAuth] API request failed: \(error.localizedDescription)")
                        print("🔄 [OAuth] Falling back to direct URL construction")
                        
                        // Fallback to direct URL construction with POST request
                        self.fallbackToDirectOAuth()
                    }
                }
            }
        }
    }
    
    /// Load webview with the provided authorization URL
    /// - Parameter urlString: Authorization URL to load
    private func loadWebViewWithURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ [OAuth] Invalid authorization URL: \(urlString)")
            showError(message: "Invalid authorization URL received")
            return
        }
        
        print("🌐 [OAuth] Loading webview with URL: \(urlString)")
        loadingLabel?.text = "Loading authorization page..."
        
        // Create request with proper headers for OAuth compatibility
        var request = URLRequest(url: url)
        
        // Add security headers only if secure OAuth is enabled
        if config.enableSecureOAuth {
            print("🔒 [OAuth] Adding security headers for secure OAuth")
            
            // Add security headers
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
            request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
            request.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
            request.setValue("?1", forHTTPHeaderField: "Sec-Fetch-User")
            
            // Add platform-specific headers for better compatibility
            if platform == .gmail {
                request.setValue("https://accounts.google.com", forHTTPHeaderField: "Origin")
                request.setValue("https://accounts.google.com", forHTTPHeaderField: "Referer")
            }
            
            // Set proper user agent in request as well
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1 OnairosSDK/3.0.72", forHTTPHeaderField: "User-Agent")
        }
        
        webView.load(request)
    }
    
    /// Fallback to direct OAuth URL construction and POST request
    private func fallbackToDirectOAuth() {
        let authURL = buildOAuthURL()
        let request = buildOAuthPOSTRequest(url: authURL)
        
        loadingLabel?.text = "Loading authorization page..."
        webView.load(request)
    }
    
    /// Build OAuth POST request with JSON data (fallback method)
    /// - Parameter url: OAuth URL
    /// - Returns: URLRequest configured for POST
    private func buildOAuthPOSTRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add security headers for OAuth compatibility
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        
        // Add platform-specific headers for better compatibility
        if platform == .gmail {
            request.setValue("https://accounts.google.com", forHTTPHeaderField: "Origin")
            request.setValue("https://accounts.google.com", forHTTPHeaderField: "Referer")
        }
        
        // Set proper user agent
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1 OnairosSDK/3.0.72", forHTTPHeaderField: "User-Agent")
        
        // Get the actual username from UserDefaults (saved during email verification)
        let username = UserDefaults.standard.string(forKey: "onairos_username") ?? extractUsername(from: userEmail)
        let redirectURI = "\(config.urlScheme)://oauth/callback"
        
        // Build request body with session object containing username
        let requestBody: [String: Any] = [
            "response_type": "code",
            "redirect_uri": redirectURI,
            "scope": platform.oauthScopes,
            "state": generateStateParameter(),
            "email": userEmail,
            "session": [
                "username": username
            ]
        ]
        
        // Convert to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            print("❌ [OAuth] Failed to serialize request body: \(error)")
            // Fallback to form-encoded request if JSON serialization fails
            let formData = [
                "response_type": "code",
                "redirect_uri": redirectURI,
                "scope": platform.oauthScopes,
                "state": generateStateParameter(),
                "email": userEmail,
                "username": username
            ]
            
            let formString = formData.map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")
            
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = formString.data(using: .utf8)
        }
        
        return request
    }
    
    /// Extract username from email address
    /// - Parameter email: Full email address
    /// - Returns: Username (part before @)
    private func extractUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? email
    }
    
    /// Build OAuth URL for platform (legacy method - kept for fallback)
    /// - Returns: OAuth authorization URL
    private func buildOAuthURL() -> URL {
        let baseURL = config.apiBaseURL
        let urlString = "\(baseURL)/\(platform.rawValue)/authorize"
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid OAuth URL: \(urlString)")
        }
        
        return url
    }
    

    
    /// Generate state parameter for OAuth security
    /// - Returns: Random state string
    private func generateStateParameter() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement() ?? "a" })
    }
    
    /// Handle close button tap
    @objc private func closeButtonTapped() {
        print("🔍 [OAuth] Cancel button tapped - dismissing OAuth flow")
        
        // Stop any ongoing loading
        webView.stopLoading()
        loadingIndicator.stopAnimating()
        
        // Call completion with user cancelled error
        completion(.failure(.userCancelled))
        
        // Dismiss the view controller
        dismiss(animated: true) {
            print("🔍 [OAuth] OAuth flow dismissed after cancel")
        }
    }
}

// MARK: - WKNavigationDelegate
extension OAuthWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle SSL certificate validation for secure OAuth only if enabled
        guard config.enableSecureOAuth else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // For Google OAuth, we trust their certificates
        if challenge.protectionSpace.host.contains("google.com") || 
           challenge.protectionSpace.host.contains("accounts.google.com") ||
           challenge.protectionSpace.host.contains("googleapis.com") {
            print("🔒 [OAuth] Trusting Google SSL certificate for \(challenge.protectionSpace.host)")
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // For other domains, use default validation
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        loadingIndicator.startAnimating()
        loadingLabel?.text = "Loading authorization page..."
        
        // Ensure cancel button remains active during loading
        closeButton.isEnabled = true
        closeButton.isUserInteractionEnabled = true
        
        // Show progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 1.0
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        loadingIndicator.stopAnimating()
        loadingLabel?.text = ""
        
        // Ensure cancel button remains active after loading
        closeButton.isEnabled = true
        closeButton.isUserInteractionEnabled = true
        
        // Hide progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressView?.alpha = 0.0
        }
        
        // Check if we've finished loading the success page onairos.uk/Home
        if let url = webView.url {
            let urlString = url.absoluteString
            
            if urlString.contains("onairos.uk/Home") {
                print("✅ [OAuth] Finished loading onairos.uk/Home - OAuth completed successfully")
                loadingLabel?.text = "✅ Authorization successful!"
                handleSuccessfulRedirect()
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        loadingIndicator.stopAnimating()
        loadingLabel?.text = "Failed to load authorization page"
        
        // Ensure cancel button remains active after error
        closeButton.isEnabled = true
        closeButton.isUserInteractionEnabled = true
        
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
        isLoading = false
        loadingIndicator.stopAnimating()
        loadingLabel?.text = "Failed to connect to authorization server"
        
        // Ensure cancel button remains active after error
        closeButton.isEnabled = true
        closeButton.isUserInteractionEnabled = true
        
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
        
        // Check if this is our custom URL scheme callback (for legacy support)
        if url.scheme == config.urlScheme && url.host == "oauth" {
            print("✅ [OAuth] Detected custom URL scheme callback - treating as successful")
            handleOAuthCallback(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Check if this is the specific success redirect to onairos.uk/Home
        if url.absoluteString.contains("onairos.uk/Home") {
            print("✅ [OAuth] Detected redirect to onairos.uk/Home - OAuth completed successfully")
            loadingLabel?.text = "✅ Authorization successful!"
            handleSuccessfulRedirect()
            decisionHandler(.cancel)
            return
        }
        
        // Update loading message based on URL only if we're currently loading
        if isLoading {
            if url.absoluteString.contains("authorize") {
                loadingLabel?.text = "Preparing authorization..."
            } else if url.absoluteString.contains("login") {
                loadingLabel?.text = "Loading sign-in page..."
            } else if url.absoluteString.contains("callback") {
                loadingLabel?.text = "Processing authorization..."
            }
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
        print("🔍 [OAuth] Processing callback URL: \(url.absoluteString)")
        
        // For custom URL scheme callbacks, extract auth code if present
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else {
            print("⚠️ [OAuth] No query items found in callback URL")
            completion(.failure(.authenticationFailed("Invalid callback URL")))
            dismiss(animated: true)
            return
        }
        
        // Extract authorization code if present
        if let authCode = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ [OAuth] Authorization code found in callback")
            loadingLabel?.text = "✅ Authorization complete!"
            completion(.success(authCode))
            
            // Dismiss with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dismiss(animated: true)
            }
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            print("❌ [OAuth] Error found in callback: \(error)")
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
            completion(.failure(.authenticationFailed(errorDescription)))
            dismiss(animated: true)
        } else {
            print("❌ [OAuth] No authorization code found in callback")
            completion(.failure(.authenticationFailed("No authorization code received")))
            dismiss(animated: true)
        }
    }
}

// MARK: - Platform OAuth Extensions
// Note: oauthScopes is now defined in OnboardingModels.swift as a public property 