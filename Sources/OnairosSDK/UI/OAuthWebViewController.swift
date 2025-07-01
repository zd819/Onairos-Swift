import UIKit
import WebKit

/// OAuth WebView controller for platform authentication
public class OAuthWebViewController: UIViewController {
    
    /// Platform being authenticated
    private let platform: Platform
    
    /// Configuration
    private let config: OnairosConfig
    
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
    
    /// Initialize OAuth WebView controller
    /// - Parameters:
    ///   - platform: Platform to authenticate
    ///   - config: SDK configuration
    ///   - completion: Completion callback with auth code
    init(
        platform: Platform,
        config: OnairosConfig,
        completion: @escaping (Result<String, OnairosError>) -> Void
    ) {
        self.platform = platform
        self.config = config
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
        
        // Close button
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(webView)
        view.addSubview(closeButton)
        view.addSubview(loadingIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // WebView
            webView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
        
        var urlComponents = URLComponents(string: "\(baseURL)/\(platform.rawValue)/authorize")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: platform.oauthScopes),
            URLQueryItem(name: "state", value: generateStateParameter())
        ]
        
        return urlComponents.url!
    }
    
    /// Generate state parameter for OAuth security
    /// - Returns: Random state string
    private func generateStateParameter() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement()! })
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
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        completion(.failure(.networkError(error.localizedDescription)))
        dismiss(animated: true)
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
        
        // Check if this is our callback URL
        if url.scheme == config.urlScheme && url.host == "oauth" {
            handleOAuthCallback(url: url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    /// Handle OAuth callback URL
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
            completion(.success(authCode))
            dismiss(animated: true)
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
extension Platform {
    
    /// OAuth scopes for each platform
    var oauthScopes: String {
        switch self {
        case .reddit:
            return "identity read"
        case .pinterest:
            return "read_public"
        case .gmail:
            return "https://www.googleapis.com/auth/gmail.readonly"
        case .instagram, .youtube:
            return "" // These use different auth methods
        }
    }
} 