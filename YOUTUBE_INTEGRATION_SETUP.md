# YouTube Integration Setup Guide

## 🎯 Overview

The Onairos Swift SDK supports two modes for YouTube authentication:

1. **Admin/Testing Mode**: Uses hardcoded Google Client ID for internal testing
2. **Normal App Mode**: Uses your own Google Client ID for production apps

Choose the appropriate mode based on your use case.

## ⚠️ Required Configuration

### Mode 1: Admin/Testing Mode (Onairos Internal)

Use this mode for internal testing with the hardcoded Google Client ID.

#### 1. Info.plist URL Scheme Configuration

Add the following URL scheme to your app's `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o</string>
        </array>
    </dict>
</array>
```

#### 2. App Delegate Configuration

Add URL handling to your `AppDelegate.swift`:

```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize YouTube auth manager in admin/testing mode
        YouTubeAuthManager.shared.initialize()
        return true
    }
    
    // Handle URL callbacks for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return YouTubeAuthManager.shared.handleURL(url)
    }
}
```

### Mode 2: Normal App Mode (Your Google Client ID)

Use this mode for production apps with your own Google Client ID.

#### 1. Google Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the YouTube Data API v3
4. Create OAuth 2.0 credentials for iOS
5. Note your Google Client ID

#### 2. Info.plist URL Scheme Configuration

Add your URL scheme to your app's `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Note:** Replace `YOUR_CLIENT_ID` with your actual Google Client ID (the part before `.apps.googleusercontent.com`).

#### 3. App Delegate Configuration

Add URL handling to your `AppDelegate.swift`:

```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize YouTube auth manager with your Google Client ID
        YouTubeAuthManager.shared.initialize(clientID: "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com")
        return true
    }
    
    // Handle URL callbacks for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return YouTubeAuthManager.shared.handleURL(url)
    }
}
```

**Note:** Replace `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com` with your actual Google Client ID.

### 3. Scene Delegate URL Handling (iOS 13+)

If your app uses Scene Delegate, add URL handling to your `SceneDelegate.swift`:

```swift
import UIKit
import OnairosSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = YouTubeAuthManager.shared.handleURL(url)
    }
}
```

## 📱 Usage in Your App

### Basic Integration

```swift
import OnairosSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Onairos SDK
        let config = OnairosConfig(
            baseURL: "https://api2.onairos.uk",
            apiKey: "your_api_key_here"
        )
        
        OnairosSDK.shared.initialize(with: config)
    }
    
    @IBAction func connectYouTube(_ sender: UIButton) {
        Task {
            try await OnairosSDK.shared.connectYouTube()
        }
    }
}
```

### Advanced Usage with Custom Handling

```swift
import OnairosSDK

class YouTubeConnectionViewController: UIViewController {
    
    @IBAction func connectYouTube(_ sender: UIButton) {
        Task {
            do {
                // Attempt YouTube connection
                let credentials = try await YouTubeAuthManager.shared.authenticate()
                print("✅ YouTube connected successfully!")
                print("Access Token: \(credentials.accessToken)")
                
                // Use credentials with Onairos API
                await handleYouTubeConnection(credentials: credentials)
                
            } catch let error as OnairosError {
                await handleYouTubeError(error)
            } catch {
                print("❌ Unexpected error: \(error)")
            }
        }
    }
    
    private func handleYouTubeConnection(credentials: YouTubeCredentials) async {
        // Process the YouTube connection with Onairos backend
        let result = await OnairosAPIClient.shared.authenticateYouTube(
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            idToken: credentials.idToken
        )
        
        switch result {
        case .success(let response):
            print("✅ YouTube authentication successful: \(response)")
        case .failure(let error):
            print("❌ YouTube authentication failed: \(error)")
        }
    }
    
    @MainActor
    private func handleYouTubeError(_ error: OnairosError) {
        let alertController = UIAlertController(
            title: "YouTube Connection Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
```

## 🛠 Troubleshooting

### Common Issues

#### 1. Missing URL Scheme Error
```
'Your app is missing support for the following URL schemes: com.googleusercontent.apps.1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o'
```

**Solution:** Add the URL scheme to your `Info.plist` as shown above.

#### 2. Google Sign-In Not Initialized
```
Google Sign-In not initialized
```

**Solution:** Call `YouTubeAuthManager.shared.initialize()` in your `AppDelegate`.

#### 3. No Presenting View Controller
```
No presenting view controller available
```

**Solution:** Ensure you're calling YouTube authentication from a view controller that's currently presented.

### Verification Steps

1. **Check URL Scheme Configuration:**
   ```swift
   // Add this to verify URL scheme is configured
   if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
       for urlType in urlTypes {
           if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
               print("Configured URL schemes: \(schemes)")
           }
       }
   }
   ```

2. **Check YouTube Auth Availability:**
   ```swift
   if YouTubeAuthManager.shared.isAvailable() {
       print("✅ YouTube authentication is available")
   } else {
       print("❌ YouTube authentication is not configured properly")
   }
   ```

## 📋 Complete Example App Setup

### 1. Package.swift Dependencies
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/your-org/onairos-swift-sdk.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "OnairosSDK", package: "onairos-swift-sdk")
            ]
        )
    ]
)
```

### 2. Complete Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>GoogleSignIn</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o</string>
            </array>
        </dict>
    </array>
    <!-- Your other Info.plist entries -->
</dict>
</plist>
```

### 3. Complete AppDelegate.swift
```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Onairos SDK
        let config = OnairosConfig(
            baseURL: "https://api2.onairos.uk",
            apiKey: "your_api_key_here"
        )
        OnairosSDK.shared.initialize(with: config)
        
        // Initialize YouTube authentication
        YouTubeAuthManager.shared.initialize()
        
        return true
    }
    
    // Handle URL callbacks
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return YouTubeAuthManager.shared.handleURL(url)
    }
}
```

## 🎉 You're Ready!

After completing this setup, your app should be able to authenticate with YouTube through the Onairos SDK without any URL scheme errors.

## 📞 Support

If you continue to experience issues:
1. Double-check your URL scheme configuration
2. Ensure you're calling `initialize()` in your AppDelegate
3. Verify your API key is correctly configured
4. Contact Onairos support with your configuration details

---

**Remember:** The URL scheme `com.googleusercontent.apps.1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o` is specific to the Onairos SDK's Google OAuth configuration and must be added exactly as shown. 