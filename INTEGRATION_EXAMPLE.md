# OnairosSDK Integration Example

This document provides comprehensive examples of how to integrate the OnairosSDK into your iOS application.

## YouTube Authentication Setup

The OnairosSDK now uses the native Google Sign-In SDK with enhanced configuration for YouTube authentication.

### Configuration

The YouTube authentication is pre-configured with the following settings:

```swift
// These are automatically configured in YouTubeAuthManager
private struct Config {
    static let webClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
    static let iosClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
    static let scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
    static let offlineAccess = true
    static let forceCodeForRefreshToken = true
}
```

### Basic Usage

```swift
import OnairosSDK

class YourViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize YouTube authentication
        // Uses the pre-configured client ID by default
        YouTubeAuthManager.shared.initialize()
        
        // Or use a custom client ID if needed
        // YouTubeAuthManager.shared.initialize(clientID: "your-custom-client-id")
        
        // Try to restore previous sign-in state
        Task {
            let restored = await YouTubeAuthManager.shared.restorePreviousSignIn()
            if restored {
                print("Previous YouTube session restored")
            }
        }
    }
    
    @IBAction func authenticateYouTube(_ sender: UIButton) {
        Task {
            do {
                let credentials = try await YouTubeAuthManager.shared.authenticate()
                
                // Success! Use the credentials
                print("YouTube authentication successful!")
                print("Access Token: \(credentials.accessToken)")
                print("User Email: \(credentials.userInfo["email"] ?? "N/A")")
                print("User Name: \(credentials.userInfo["name"] ?? "N/A")")
                print("Has Offline Access: \(credentials.hasOfflineAccess)")
                
                // Check if token is valid
                if !credentials.isExpired {
                    // Use the credentials to make YouTube API calls
                    await makeYouTubeAPICall(with: credentials)
                }
                
            } catch {
                // Handle authentication error
                print("YouTube authentication failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func makeYouTubeAPICall(with credentials: YouTubeCredentials) async {
        // Example YouTube API call
        let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // Process the response
            print("YouTube API Response: \(String(data: data, encoding: .utf8) ?? "No data")")
        } catch {
            print("YouTube API call failed: \(error.localizedDescription)")
        }
    }
    
    @IBAction func checkAuthStatus(_ sender: UIButton) {
        if YouTubeAuthManager.shared.isSignedIn() {
            if let currentUser = YouTubeAuthManager.shared.getCurrentUser() {
                print("User is signed in: \(currentUser.userInfo["email"] ?? "N/A")")
                
                // Check if token needs refresh
                if currentUser.expiresSoon {
                    Task {
                        do {
                            let refreshedCredentials = try await YouTubeAuthManager.shared.refreshTokenIfNeeded()
                            print("Token refreshed successfully")
                        } catch {
                            print("Token refresh failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            print("User is not signed in")
        }
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        YouTubeAuthManager.shared.signOut()
        print("YouTube sign out successful")
    }
}
```

### Advanced Usage with Error Handling

```swift
import OnairosSDK

class AdvancedYouTubeViewController: UIViewController {
    
    private var currentCredentials: YouTubeCredentials?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupYouTubeAuth()
    }
    
    private func setupYouTubeAuth() {
        // Initialize with enhanced configuration
        YouTubeAuthManager.shared.initialize()
        
        // Check if authentication is available
        guard YouTubeAuthManager.shared.isAvailable() else {
            print("YouTube authentication is not available")
            return
        }
        
        // Try to restore previous session
        Task {
            let restored = await YouTubeAuthManager.shared.restorePreviousSignIn()
            if restored {
                self.currentCredentials = YouTubeAuthManager.shared.getCurrentUser()
                await self.updateUI()
            }
        }
    }
    
    private func authenticateWithRetry() async {
        do {
            let credentials = try await YouTubeAuthManager.shared.authenticate()
            self.currentCredentials = credentials
            
            // Validate the credentials
            if credentials.isExpired {
                print("Warning: Received expired credentials")
                try await refreshCredentials()
            }
            
            await updateUI()
            
        } catch let error as YouTubeAuthError {
            await handleYouTubeAuthError(error)
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func refreshCredentials() async throws {
        guard let _ = currentCredentials else {
            throw YouTubeAuthError.noAccessToken
        }
        
        do {
            let refreshedCredentials = try await YouTubeAuthManager.shared.refreshTokenIfNeeded()
            self.currentCredentials = refreshedCredentials
            print("Credentials refreshed successfully")
        } catch {
            print("Failed to refresh credentials: \(error.localizedDescription)")
            throw YouTubeAuthError.tokenRefreshFailed(error.localizedDescription)
        }
    }
    
    private func handleYouTubeAuthError(_ error: YouTubeAuthError) async {
        switch error {
        case .googleSignInNotConfigured:
            print("Google Sign-In configuration error. Check GoogleService-Info.plist")
            
        case .noAccessToken:
            print("No access token received. Retrying authentication...")
            await authenticateWithRetry()
            
        case .tokenRefreshFailed(let reason):
            print("Token refresh failed: \(reason)")
            // Clear current credentials and require re-authentication
            self.currentCredentials = nil
            YouTubeAuthManager.shared.signOut()
            
        case .userCancelled:
            print("User cancelled YouTube authentication")
            
        case .networkError(let reason):
            print("Network error: \(reason)")
            // Maybe retry after a delay
            
        case .offlineAccessNotAvailable:
            print("Offline access not available")
            // Handle offline access requirements
        }
        
        await updateUI()
    }
    
    @MainActor
    private func updateUI() {
        // Update your UI based on authentication state
        if let credentials = currentCredentials {
            // User is authenticated
            print("User authenticated: \(credentials.userInfo["name"] ?? "Unknown")")
            print("Offline access available: \(credentials.hasOfflineAccess)")
        } else {
            // User is not authenticated
            print("User not authenticated")
        }
    }
    
    private func performYouTubeOperation() async {
        guard let credentials = currentCredentials else {
            print("No credentials available")
            return
        }
        
        // Check if token is expired or expires soon
        if credentials.isExpired || credentials.expiresSoon {
            do {
                try await refreshCredentials()
            } catch {
                print("Failed to refresh token: \(error.localizedDescription)")
                return
            }
        }
        
        // Perform YouTube API operations
        await makeYouTubeAPICall(with: credentials)
    }
    
    private func makeYouTubeAPICall(with credentials: YouTubeCredentials) async {
        // Example: Get user's YouTube channel information
        let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    // Token is invalid, try to refresh
                    try await refreshCredentials()
                    // Retry the request with new token
                    request.setValue("Bearer \(currentCredentials?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
                    let (retryData, _) = try await URLSession.shared.data(for: request)
                    processYouTubeResponse(retryData)
                } else if httpResponse.statusCode == 200 {
                    processYouTubeResponse(data)
                } else {
                    print("YouTube API error: \(httpResponse.statusCode)")
                }
            }
            
        } catch {
            print("YouTube API call failed: \(error.localizedDescription)")
        }
    }
    
    private func processYouTubeResponse(_ data: Data) {
        // Process the YouTube API response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("YouTube API Response: \(jsonString)")
        }
    }
}
```

### URL Scheme Handling

Make sure to handle the URL callback in your app delegate:

```swift
// In your AppDelegate.swift or SceneDelegate.swift
import OnairosSDK

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if YouTubeAuthManager.shared.handleURL(url) {
        return true
    }
    return false
}
```

### Features

The updated YouTube authentication manager provides:

1. **Pre-configured Settings**: Uses the exact client IDs and scopes you specified
2. **Offline Access**: Supports offline access through refresh tokens
3. **Token Management**: Automatic token refresh and expiration checking
4. **Enhanced Error Handling**: Comprehensive error types and handling
5. **Session Restoration**: Ability to restore previous authentication sessions
6. **Native SDK Integration**: Uses the official Google Sign-In iOS SDK

### Configuration Notes

- The `webClientId` and `iosClientId` are now hardcoded in the configuration
- YouTube readonly scope is automatically included
- Offline access is enabled through refresh tokens
- Server auth code is available only during initial authentication

### Important API Changes

**Server Auth Code**: The server auth code is only available during the initial authentication flow (`result.serverAuthCode`). It's not available when retrieving current user or refreshing tokens. This is normal behavior for the Google Sign-In SDK.

**Offline Access**: Offline access is determined by the presence of either a server auth code (initial sign-in) or a refresh token (subsequent sessions).

## Complete OnairosSDK Integration

## ❌ Common Build Errors and Solutions

### Error 1: "Extra argument 'apiKey' in call"
**Problem:** You're calling the wrong initialization method.

**❌ Wrong:**
```swift
OnairosSDK.shared.initialize(apiKey: "your-key")
```

**✅ Correct:**
```swift
// Option 1: Legacy method (always works)
let config = OnairosLegacyConfig(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
OnairosSDK.shared.initialize(config: config)

// Option 2: New async method
try await OnairosSDK.shared.initializeWithAdminKey()
```

### Error 2: "Value of type 'OnairosSDK' has no member 'initialize'"
**Problem:** Import or version issue.

**✅ Solution:** Make sure you have the correct import and SDK version.

### Error 3: Asset Catalog Issues
**Problem:** Missing proper app icon structure.

**✅ Solution:** Create proper Assets.xcassets structure (see below).

---

## 🚀 Complete Working Example

### 1. AppDelegate.swift (UIKit)
```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize OnairosSDK
        initializeOnairosSDK()
        
        return true
    }
    
    private func initializeOnairosSDK() {
        // Method 1: Legacy initialization (recommended for stability)
        let config = OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true, // This prevents API calls during development
            allowEmptyConnections: true,
            simulateTraining: true,
            urlScheme: "your-app-scheme", // Replace with your app's scheme
            appName: "Your App Name"
        )
        
        OnairosSDK.shared.initialize(config: config)
        print("✅ OnairosSDK initialized successfully")
        
        // Method 2: Async initialization (alternative)
        Task {
            do {
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .development,
                    enableLogging: true
                )
                print("✅ OnairosSDK initialized with admin key")
            } catch {
                print("❌ Failed to initialize SDK: \(error)")
                // Fallback to legacy method
                OnairosSDK.shared.initialize(config: config)
            }
        }
    }
    
    // Handle URL schemes for OAuth
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle OAuth callbacks here
        return true
    }
}
```

### 2. ViewController.swift
```swift
import UIKit
import OnairosSDK

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    private var connectButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Create and add the OnairosSDK connect button
        connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.handleSuccess(data)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
        
        guard let connectButton = connectButton else { return }
        
        view.addSubview(connectButton)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 200),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func handleSuccess(_ data: OnboardingData) {
        statusLabel.text = "✅ Connected successfully!"
        print("🎉 Connected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))")
        
        // Show success alert
        let alert = UIAlertController(
            title: "Success! 🎉",
            message: "Your data has been connected successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default))
        present(alert, animated: true)
    }
    
    private func handleError(_ error: OnairosError) {
        statusLabel.text = "❌ Connection failed"
        print("❌ Error: \(error.localizedDescription)")
        
        // Show error alert
        let alert = UIAlertController(
            title: "Connection Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### 3. SwiftUI App.swift
```swift
import SwiftUI
import OnairosSDK

@main
struct YourApp: App {
    
    init() {
        initializeOnairosSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: handleURL)
        }
    }
    
    private func initializeOnairosSDK() {
        // Initialize SDK
        let config = OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            urlScheme: "your-app-scheme",
            appName: "Your App Name"
        )
        
        OnairosSDK.shared.initialize(config: config)
        print("✅ OnairosSDK initialized")
    }
    
    private func handleURL(_ url: URL) {
        // Handle OAuth callbacks
        print("Received URL: \(url)")
    }
}
```

### 4. SwiftUI ContentView.swift
```swift
import SwiftUI
import OnairosSDK

struct ContentView: View {
    @State private var showingOnboarding = false
    @State private var statusMessage = "Ready to connect"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Onairos SDK Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(statusMessage)
                .foregroundColor(.secondary)
            
            Button("Connect Your Data") {
                presentOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private func presentOnboarding() {
        // Find the current UIViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            statusMessage = "❌ Could not find view controller"
            return
        }
        
        // Present onboarding
        OnairosSDK.shared.presentOnboarding(from: rootViewController) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    statusMessage = "✅ Connected successfully!"
                    print("🎉 Connected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))")
                case .failure(let error):
                    statusMessage = "❌ Connection failed: \(error.localizedDescription)"
                    print("❌ Error: \(error)")
                }
            }
        }
    }
}
```

---

## 🔧 Fix Asset Catalog Issues

### Create proper Assets.xcassets structure:

1. **Create Assets.xcassets folder** in your project
2. **Add AppIcon.appiconset** folder inside Assets.xcassets
3. **Create Contents.json** file in AppIcon.appiconset:

```json
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## 🎯 Key Points for Success

### ✅ DO:
1. **Use the correct initialization method** - `initialize(config:)` not `initialize(apiKey:)`
2. **Use test mode for development** - prevents API call issues
3. **Handle OAuth URL schemes** - add URL scheme to Info.plist
4. **Create proper asset catalog structure**
5. **Use the completion handlers** for success/error handling

### ❌ DON'T:
1. **Don't call `initialize(apiKey:)`** - this method doesn't exist
2. **Don't use production mode during development** - can cause modal dismissal
3. **Don't forget URL schemes** - needed for OAuth platforms
4. **Don't skip error handling** - always handle both success and failure cases

---

## 🔗 URL Scheme Setup

Add this to your **Info.plist**:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourapp.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-scheme</string>
        </array>
    </dict>
</array>
```

---

## 🧪 Testing

The SDK includes **test mode** which:
- ✅ Bypasses all real API calls
- ✅ Accepts any email/verification code
- ✅ Simulates platform connections
- ✅ Prevents modal dismissal issues
- ✅ Perfect for development and testing

Use test mode by setting `isTestMode: true` in your configuration.

---

## 📞 Support

If you're still having issues:
1. Check the SDK version: `OnairosSDK.version`
2. Enable logging: `enableLogging: true`
3. Use test mode: `isTestMode: true`
4. Check the console for detailed error messages

The SDK is designed to work out of the box with minimal setup. The examples above should resolve all common build errors and get you up and running quickly. 