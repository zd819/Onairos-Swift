# Quick Test Guide - YouTube Authentication

## Test the Updated YouTube Authentication

### 1. Basic Test Setup

```swift
import OnairosSDK

// In your AppDelegate or SceneDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Initialize SDK with test mode
    let config = OnairosConfig.testMode(
        urlScheme: "your-app-scheme",
        appName: "Your App Name"
    )
    OnairosSDK.shared.initialize(config: config)
    
    return true
}

// Handle URL callbacks for Google Sign-In
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if YouTubeAuthManager.shared.handleURL(url) {
        return true
    }
    return false
}
```

### 2. Test YouTube Connection

```swift
import UIKit
import OnairosSDK

class TestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create connect button
        let connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data") { result in
            switch result {
            case .success(let onboardingResult):
                print("✅ Success: \(onboardingResult)")
            case .failure(let error):
                print("❌ Error: \(error.localizedDescription)")
            }
        }
        
        // Add to view
        view.addSubview(connectButton)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 200),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
```

### 3. Test YouTube Authentication Directly

```swift
import OnairosSDK

class YouTubeTestViewController: UIViewController {
    
    @IBAction func testYouTubeAuth(_ sender: UIButton) {
        Task {
            do {
                // Test YouTube authentication directly
                let credentials = try await YouTubeAuthManager.shared.authenticate()
                
                print("✅ YouTube Authentication Success!")
                print("Access Token: \(credentials.accessToken)")
                print("User Email: \(credentials.userInfo["email"] ?? "N/A")")
                print("User Name: \(credentials.userInfo["name"] ?? "N/A")")
                print("Has Offline Access: \(credentials.hasOfflineAccess)")
                
                // Show success alert
                let alert = UIAlertController(
                    title: "YouTube Connected!",
                    message: "Successfully connected to YouTube account: \(credentials.userInfo["email"] ?? "Unknown")",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                
            } catch {
                print("❌ YouTube Authentication Failed: \(error.localizedDescription)")
                
                // Show error alert
                let alert = UIAlertController(
                    title: "Authentication Failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}
```

### 4. Expected Behavior

When you tap "Connect" on the YouTube platform:

1. ✅ **Google Sign-In Modal Opens**: The native Google Sign-In web view should appear
2. ✅ **YouTube Permission Request**: Google will ask for YouTube readonly permissions
3. ✅ **Authentication Success**: After signing in, you should get YouTube credentials
4. ✅ **Platform Marked as Connected**: The YouTube platform should show "Connected ✓"
5. ✅ **User Info Available**: Email, name, and other user info should be populated

### 5. Debug Information

Enable debug logging to see the authentication flow:

```swift
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
OnairosSDK.shared.initialize(config: config)

// Check initialization status
print("YouTube Auth Available: \(YouTubeAuthManager.shared.isAvailable())")
print("YouTube Auth Signed In: \(YouTubeAuthManager.shared.isSignedIn())")
```

### 6. Configuration Checklist

Make sure you have:

- [ ] **GoogleService-Info.plist** added to your project
- [ ] **URL Scheme** configured in Info.plist with your reversed client ID
- [ ] **Google Sign-In SDK** dependency added (should be automatic via Package.swift)
- [ ] **YouTube Data API v3** enabled in Google Cloud Console
- [ ] **OAuth consent screen** configured in Google Cloud Console

### 7. Troubleshooting

**If YouTube authentication fails:**

1. Check console logs for specific error messages
2. Verify GoogleService-Info.plist is in your project
3. Ensure URL scheme matches your Google OAuth configuration
4. Check that YouTube Data API v3 is enabled in Google Cloud Console

**If the Google Sign-In modal doesn't appear:**

1. Verify the SDK is properly initialized
2. Check that YouTube platform is enabled in your configuration
3. Ensure you're testing on a physical device (simulator may have issues)

### 8. Test Flow

1. **Email Step**: Enter any email (test mode accepts anything)
2. **Verification Step**: Enter any 6-digit code (test mode accepts anything)
3. **Connect Step**: Tap "Connect" on YouTube
4. **Google Sign-In**: Complete the Google authentication flow
5. **Success**: YouTube should show "Connected ✓"
6. **Continue**: Proceed through the remaining steps

The new YouTube authentication uses your exact configuration:
- **Client IDs**: `1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com`
- **Scopes**: `https://www.googleapis.com/auth/youtube.readonly`
- **Offline Access**: Enabled for refresh tokens
- **Native SDK**: Uses Google Sign-In iOS SDK for smooth authentication

This should provide a seamless YouTube authentication experience that matches your React Native implementation! 