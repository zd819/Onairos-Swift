# YouTube Authentication Setup Guide

This guide shows you how to set up YouTube authentication for the OnairosSDK, which is required for accessing YouTube data.

## Prerequisites

Before you begin, you need:
- A Google Cloud Console account
- An iOS app project
- OnairosSDK integrated into your project

## Step 1: Google Cloud Console Setup

### 1.1 Create or Select a Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID for reference

### 1.2 Enable YouTube Data API v3
1. In the Google Cloud Console, go to **APIs & Services** > **Library**
2. Search for "YouTube Data API v3"
3. Click on it and press **Enable**

### 1.3 Create OAuth 2.0 Credentials
1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth 2.0 Client IDs**
3. If prompted, configure the OAuth consent screen first
4. Select **iOS** as the application type
5. Enter your app's bundle identifier (e.g., `com.yourcompany.yourapp`)
6. Click **Create**
7. Download the `GoogleService-Info.plist` file

## Step 2: iOS Project Configuration

### 2.1 Add Google Services File
1. Drag the `GoogleService-Info.plist` file into your Xcode project
2. Make sure it's added to your target
3. Ensure it's included in your app bundle

### 2.2 Configure URL Schemes
Add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>google-signin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**To find your REVERSED_CLIENT_ID:**
1. Open the `GoogleService-Info.plist` file
2. Find the `REVERSED_CLIENT_ID` key
3. Copy its value and paste it in the XML above

### 2.3 Handle URL Callbacks
Add this to your `AppDelegate.swift`:

```swift
import UIKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
```

## Step 3: SDK Integration

### 3.1 Extract Google Client ID
There are two ways to get your Google client ID:

**Method 1: Extract from GoogleService-Info.plist**
```swift
import OnairosSDK

func setupSDK() {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
        fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
    }
    
    Task {
        do {
            try await OnairosSDK.shared.initializeWithAdminKey(
                environment: .production,
                enableLogging: true,
                googleClientID: clientId
            )
            print("✅ SDK initialized with YouTube support")
        } catch {
            print("❌ SDK initialization failed: \(error)")
        }
    }
}
```

**Method 2: Hard-code the client ID**
```swift
import OnairosSDK

func setupSDK() {
    Task {
        do {
            try await OnairosSDK.shared.initializeWithAdminKey(
                environment: .production,
                enableLogging: true,
                googleClientID: "YOUR_GOOGLE_CLIENT_ID_HERE"
            )
            print("✅ SDK initialized with YouTube support")
        } catch {
            print("❌ SDK initialization failed: \(error)")
        }
    }
}
```

### 3.2 Using Custom API Key
If you have your own API key, use it instead of the admin key:

```swift
try await OnairosSDK.shared.initializeWithApiKey(
    "your-api-key",
    environment: .production,
    enableLogging: false,
    googleClientID: "YOUR_GOOGLE_CLIENT_ID"
)
```

### 3.3 Full Configuration
For more control, use the full configuration:

```swift
let config = OnairosConfig(
    apiKey: "your-api-key",
    environment: .production,
    enableLogging: false,
    timeout: 30.0,
    googleClientID: "YOUR_GOOGLE_CLIENT_ID"
)

try await OnairosSDK.shared.initializeApiKey(config: config)
```

## Step 4: Testing YouTube Authentication

### 4.1 Basic Test
```swift
import OnairosSDK

func testYouTubeAuth() {
    Task {
        do {
            let credentials = try await YouTubeAuthManager.shared.authenticate()
            print("✅ YouTube authentication successful!")
            print("Access token: \(credentials.accessToken)")
            print("User email: \(credentials.userInfo["email"] ?? "N/A")")
        } catch {
            print("❌ YouTube authentication failed: \(error)")
        }
    }
}
```

### 4.2 Check Authentication Status
```swift
func checkYouTubeStatus() {
    if YouTubeAuthManager.shared.isSignedIn() {
        print("✅ User is signed in to YouTube")
        if let user = YouTubeAuthManager.shared.getCurrentUser() {
            print("Current user: \(user.userInfo["email"] ?? "N/A")")
        }
    } else {
        print("❌ User is not signed in to YouTube")
    }
}
```

### 4.3 Sign Out
```swift
func signOutOfYouTube() {
    YouTubeAuthManager.shared.signOut()
    print("✅ Signed out of YouTube")
}
```

## Step 5: Integration with Onboarding

The SDK will automatically use YouTube authentication when users connect to YouTube during the onboarding process:

```swift
func startOnboarding() {
    let button = OnairosSDK.shared.createConnectButton { result in
        switch result {
        case .success(let data):
            print("✅ Onboarding completed!")
            print("Connected platforms: \(data.connectedPlatforms)")
        case .failure(let error):
            print("❌ Onboarding failed: \(error)")
        }
    }
    
    // Present the onboarding modal
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.rootViewController?.present(button, animated: true)
    }
}
```

## Troubleshooting

### Common Issues

1. **"Google Sign-In not initialized" Error**
   - Make sure you've added the `GoogleService-Info.plist` file to your project
   - Verify the Google client ID is correctly passed to the SDK

2. **"No presenting view controller available" Error**
   - Ensure your app has a valid window and root view controller
   - This usually happens when calling authentication too early in the app lifecycle

3. **OAuth callback not working**
   - Check that your URL scheme is correctly configured in `Info.plist`
   - Verify the `REVERSED_CLIENT_ID` matches your Google Services file
   - Make sure you're handling the URL callback in `AppDelegate`

4. **YouTube API quota exceeded**
   - Check your Google Cloud Console for API usage
   - You may need to request a quota increase

### Debug Tips

1. **Enable verbose logging**:
   ```swift
   try await OnairosSDK.shared.initializeWithAdminKey(
       environment: .production,
       enableLogging: true,  // This enables detailed logs
       googleClientID: "YOUR_CLIENT_ID"
   )
   ```

2. **Check authentication availability**:
   ```swift
   if YouTubeAuthManager.shared.isAvailable() {
       print("✅ YouTube authentication is configured")
   } else {
       print("❌ YouTube authentication is not available")
   }
   ```

3. **Monitor authentication state**:
   ```swift
   print("Is signed in: \(YouTubeAuthManager.shared.isSignedIn())")
   ```

## Example Implementation

Here's a complete example of setting up YouTube authentication:

```swift
import UIKit
import OnairosSDK
import GoogleSignIn

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
    }
    
    private func setupSDK() {
        // Extract Google client ID from GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        // Initialize SDK with YouTube support
        Task {
            do {
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .production,
                    enableLogging: true,
                    googleClientID: clientId
                )
                print("✅ SDK initialized with YouTube support")
                
                // Check if YouTube authentication is available
                if YouTubeAuthManager.shared.isAvailable() {
                    print("✅ YouTube authentication is ready")
                } else {
                    print("❌ YouTube authentication is not available")
                }
                
            } catch {
                print("❌ SDK initialization failed: \(error)")
            }
        }
    }
    
    @IBAction func startOnboarding(_ sender: UIButton) {
        let button = OnairosSDK.shared.createConnectButton { result in
            switch result {
            case .success(let data):
                print("✅ Onboarding completed!")
                print("Connected platforms: \(data.connectedPlatforms)")
            case .failure(let error):
                print("❌ Onboarding failed: \(error)")
            }
        }
        
        present(button, animated: true)
    }
    
    @IBAction func testYouTubeAuth(_ sender: UIButton) {
        Task {
            do {
                let credentials = try await YouTubeAuthManager.shared.authenticate()
                print("✅ YouTube authentication successful!")
                print("Access token: \(credentials.accessToken)")
                print("User email: \(credentials.userInfo["email"] ?? "N/A")")
            } catch {
                print("❌ YouTube authentication failed: \(error)")
            }
        }
    }
}
```

## Next Steps

After setting up YouTube authentication:
1. Test the authentication flow thoroughly
2. Implement proper error handling in your app
3. Consider adding user feedback for authentication states
4. Review Google's YouTube API documentation for additional features

For more information, refer to the main [Integration Guide](INTEGRATION_GUIDE.md) and [API Key Usage Example](API_KEY_USAGE_EXAMPLE.md). 