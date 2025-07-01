# 🚀 Onairos Swift SDK - Integration Guide

This guide shows you how to integrate the Onairos SDK into your iOS app for seamless onboarding with social media authentication and AI training.

## 📋 Quick Integration Checklist

- [ ] Add SDK to your project
- [ ] Configure SDK in AppDelegate
- [ ] Add connect button to your UI
- [ ] Handle onboarding results
- [ ] Configure platform authentication (optional)
- [ ] Test the integration

## 🛠 Step 1: Add SDK to Your Project

### Using Xcode (Recommended)

1. Open your iOS project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL: `https://github.com/YOUR_USERNAME/onairos-swift-sdk`
4. Select version `1.0.0` or later
5. Add to your target

### Using Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/onairos-swift-sdk.git", from: "1.0.0")
]
```

## ⚙️ Step 2: Configure SDK

### Basic Configuration

In your `AppDelegate.swift`:

```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Onairos SDK
        let config = OnairosConfig(
            isDebugMode: false,                    // Set to true for testing
            allowEmptyConnections: false,          // Allow skipping platform connections
            simulateTraining: false,               // Simulate AI training for testing
            platforms: [.instagram, .youtube, .reddit, .pinterest, .gmail],
            urlScheme: "your-app-scheme",          // Your app's URL scheme
            appName: "Your App Name"               // Display name in UI
        )
        
        OnairosSDK.shared.initialize(config: config)
        
        return true
    }
}
```

### Advanced Configuration

```swift
let config = OnairosConfig(
    isDebugMode: false,
    allowEmptyConnections: true,
    simulateTraining: false,
    apiBaseURL: "https://api2.onairos.uk",       // Custom API URL
    platforms: [.youtube, .reddit],              // Only specific platforms
    opacityAPIKey: "your-opacity-key",           // Instagram Opacity SDK key
    googleClientID: "your-google-client-id",     // YouTube authentication
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
```

## 🎨 Step 3: Add Connect Button

### Method 1: SDK-Generated Button (Recommended)

```swift
import UIKit
import OnairosSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOnairosButton()
    }
    
    private func setupOnairosButton() {
        // Create button with default "Connect Data" text
        let connectButton = OnairosSDK.shared.createConnectButton(
            target: self,
            completion: handleOnboardingResult
        )
        
        // Or with custom text
        let customButton = OnairosSDK.shared.createConnectButton(
            text: "Start Onboarding",
            target: self,
            completion: handleOnboardingResult
        )
        
        // Add to your view
        view.addSubview(connectButton)
        
        // Setup constraints
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func handleOnboardingResult(_ result: Result<OnboardingResult, OnairosError>) {
        switch result {
        case .success(let data):
            print("✅ Onboarding completed!")
            print("Connected platforms: \(data.connectedPlatforms)")
            print("Session saved: \(data.sessionSaved)")
            
        case .failure(let error):
            print("❌ Onboarding failed: \(error.localizedDescription)")
        }
    }
}
```

### Method 2: Custom Button

```swift
@IBAction func customButtonTapped(_ sender: UIButton) {
    OnairosSDK.shared.presentOnboarding(from: self) { result in
        switch result {
        case .success(let data):
            // Handle success
            self.onOnboardingSuccess(data)
            
        case .failure(let error):
            // Handle error
            self.onOnboardingError(error)
        }
    }
}
```

## 📱 Step 4: Handle Results

### Success Handling

```swift
private func onOnboardingSuccess(_ data: OnboardingResult) {
    // User completed onboarding successfully
    
    // Check what platforms were connected
    for platform in data.connectedPlatforms {
        print("✅ Connected to \(platform)")
    }
    
    // Check if session was saved
    if data.sessionSaved {
        print("💾 Session saved - user won't need to onboard again")
    }
    
    // Check if AI training completed
    if data.trainingCompleted {
        print("🤖 AI training completed")
        
        // Access user data
        if let email = data.email {
            print("📧 User email: \(email)")
        }
        
        // Access platform data
        for (platform, platformData) in data.platformData {
            print("🔗 \(platform) data available")
        }
    }
    
    // Continue with your app flow
    navigateToMainApp()
}
```

### Error Handling

```swift
private func onOnboardingError(_ error: OnairosError) {
    switch error {
    case .userCancelled:
        print("User cancelled onboarding")
        // Maybe show a "Skip for now" option
        
    case .networkUnavailable:
        showAlert("Please check your internet connection and try again")
        
    case .platformUnavailable(let platform):
        showAlert("\(platform) is currently unavailable. Please try again later.")
        
    case .validationFailed(let message):
        showAlert("Validation error: \(message)")
        
    case .authenticationFailed(let message):
        showAlert("Authentication failed: \(message)")
        
    default:
        showAlert("An error occurred: \(error.localizedDescription)")
        
        // Show recovery suggestion if available
        if !error.recoverySuggestion.isEmpty {
            print("💡 Suggestion: \(error.recoverySuggestion)")
        }
    }
}
```

## 🔐 Step 5: Platform Authentication Setup

### YouTube (Google Sign-In)

1. **Add GoogleService-Info.plist** to your project
2. **Configure URL scheme** in Info.plist:

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

3. **Handle URL callbacks** in AppDelegate:

```swift
import GoogleSignIn

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
```

### OAuth Platforms (Reddit, Pinterest, Gmail)

1. **Configure URL scheme** in Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>onairos-oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-scheme</string>
        </array>
    </dict>
</array>
```

2. **Handle deep links** in AppDelegate:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Handle OAuth callbacks
    if url.scheme == "your-app-scheme" && url.host == "oauth" {
        // OAuth callback will be handled automatically by SDK
        return true
    }
    
    return false
}
```

### Instagram (Opacity SDK)

1. **Add Opacity SDK** to your project
2. **Configure API key** in OnairosConfig:

```swift
let config = OnairosConfig(
    opacityAPIKey: "your-opacity-api-key",
    // ... other config
)
```

## 🧪 Step 6: Testing

### Debug Mode

Enable debug mode for testing:

```swift
let config = OnairosConfig(
    isDebugMode: true,
    allowEmptyConnections: true,  // Skip platform connections
    simulateTraining: true        // Simulate AI training
)
```

Debug mode features:
- ✅ All email verification codes accepted
- ✅ Platform connections can be skipped
- ✅ Training progress is simulated
- ✅ Enhanced logging

### Session Management

```swift
// Check if user has existing session
if OnairosSDK.shared.hasExistingSession() {
    // User has completed onboarding before
    print("Welcome back!")
} else {
    // Show onboarding for new user
    showOnboardingButton()
}

// Clear session (for testing)
OnairosSDK.shared.clearSession()
```

## 🎯 Advanced Features

### Custom Error Reporting

```swift
class MyErrorReporter: ErrorReporting {
    func reportError(_ error: OnairosError, context: [String: Any]?) {
        // Send to your analytics service
        Analytics.track("onairos_error", properties: [
            "error": error.localizedDescription,
            "category": error.category.rawValue
        ])
    }
}

// Set custom error reporter
OnairosSDK.shared.setErrorReporter(MyErrorReporter())
```

### Custom Styling

The SDK uses system colors and adapts to light/dark mode automatically. UI elements follow iOS design guidelines:

- ✅ 24px corner radius for modal
- ✅ System blue primary color
- ✅ Proper contrast ratios
- ✅ Dynamic type support

## 🚨 Troubleshooting

### Common Issues

**1. Button doesn't appear**
```swift
// Make sure SDK is initialized
OnairosSDK.shared.initialize(config: config)

// Check button constraints
connectButton.translatesAutoresizingMaskIntoConstraints = false
```

**2. Keyboard blocks input fields**
- ✅ SDK automatically handles keyboard avoidance
- ✅ Input fields scroll into view automatically
- ✅ Works with all device sizes

**3. OAuth callbacks not working**
```swift
// Verify URL scheme in Info.plist
// Check deep link handling in AppDelegate
// Test URL scheme format: "your-app://oauth/callback"
```

**4. Training progress stuck**
```swift
// Enable debug mode for testing
let config = OnairosConfig(
    isDebugMode: true,
    simulateTraining: true  // Use simulation for testing
)
```

### Debug Logging

Enable verbose logging:

```swift
let config = OnairosConfig(
    isDebugMode: true
    // ... other config
)
```

## 📊 Analytics Integration

Track onboarding events:

```swift
private func handleOnboardingResult(_ result: Result<OnboardingResult, OnairosError>) {
    switch result {
    case .success(let data):
        // Track successful onboarding
        Analytics.track("onboarding_completed", properties: [
            "platforms": data.connectedPlatforms,
            "session_saved": data.sessionSaved,
            "training_completed": data.trainingCompleted
        ])
        
    case .failure(let error):
        // Track onboarding errors
        Analytics.track("onboarding_failed", properties: [
            "error": error.localizedDescription,
            "category": error.category.rawValue
        ])
    }
}
```

## 🔄 Migration from React Native

If migrating from the React Native SDK:

- ✅ Same API endpoints and data structures
- ✅ Identical onboarding flow
- ✅ Compatible session management
- ✅ Same platform authentication

## 📞 Support

Need help?

- 📧 **Email**: support@onairos.com
- 📖 **Documentation**: https://docs.onairos.com
- 🐛 **Issues**: https://github.com/onairos/onairos-swift-sdk/issues
- 💬 **Discord**: https://discord.gg/onairos

## 🎉 You're Ready!

Your Onairos SDK integration is complete! Users can now:

1. **Tap the connect button** → Opens onboarding modal
2. **Enter email** → Receives verification code
3. **Verify email** → Proceeds to platform connections
4. **Connect platforms** → OAuth/native authentication
5. **Create PIN** → Secure account setup
6. **AI training** → Real-time progress with Socket.IO
7. **Complete** → Returns data to your app

The SDK handles all the complexity while providing a smooth, native iOS experience! 🚀