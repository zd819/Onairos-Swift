# Onairos Swift SDK

A comprehensive Swift SDK for iOS that provides universal onboarding with social media authentication and AI model training.

## Features

- 🚀 **Complete Onboarding Flow**: Email verification, platform connections, PIN creation, and AI training
- 📱 **Native iOS Design**: Bottom sheet modal with 80% screen height and smooth animations
- 🔐 **Multiple Authentication Methods**: 
  - Instagram (Opacity SDK)
  - YouTube (Google Sign-In SDK) 
  - OAuth WebView (Reddit, Pinterest, Gmail)
- 🤖 **AI Training Integration**: Real-time Socket.IO connection with progress tracking
- 🛡️ **Comprehensive Error Handling**: User-friendly error messages with recovery suggestions
- 🧪 **Debug Mode Support**: Testing features and simulation modes
- ♿ **Accessibility Ready**: VoiceOver support and keyboard navigation

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/onairos/onairos-swift-sdk", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/onairos/onairos-swift-sdk`

## Quick Start

### 1. Basic Setup

```swift
import OnairosSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Onairos SDK
        let config = OnairosConfig(
            isDebugMode: true, // Enable for testing
            urlScheme: "your-app-scheme",
            appName: "Your App Name"
        )
        
        OnairosSDK.shared.initialize(config: config)
        
        return true
    }
}
```

### 2. Present Onboarding

```swift
import OnairosSDK

class ViewController: UIViewController {
    
    @IBAction func startOnboarding(_ sender: UIButton) {
        OnairosSDK.shared.presentOnboarding(from: self) { result in
            switch result {
            case .success(let data):
                print("Onboarding completed!")
                print("Connected platforms: \(data.connectedPlatforms)")
                print("Session saved: \(data.sessionSaved)")
                
            case .failure(let error):
                print("Onboarding failed: \(error.localizedDescription)")
            }
        }
    }
}
```

## Configuration Options

```swift
let config = OnairosConfig(
    isDebugMode: false,                    // Enable debug features
    allowEmptyConnections: false,          // Allow proceeding without platform connections
    simulateTraining: false,               // Simulate AI training progress
    apiBaseURL: "https://api2.onairos.uk", // API base URL
    platforms: [.instagram, .youtube, .reddit, .pinterest, .gmail], // Enabled platforms
    opacityAPIKey: "your-opacity-key",     // Instagram Opacity SDK key
    googleClientID: "your-google-client-id", // YouTube Google Sign-In client ID
    urlScheme: "your-app-scheme",          // Custom URL scheme for OAuth
    appName: "Your App Name"               // App name displayed in UI
)
```

## Platform Authentication Setup

### Instagram (Opacity SDK)

1. Add Opacity SDK to your project
2. Configure your Opacity API key:

```swift
let config = OnairosConfig(
    opacityAPIKey: "your-opacity-api-key",
    // ... other config
)
```

### YouTube (Google Sign-In)

1. Add GoogleService-Info.plist to your project
2. Configure URL scheme in Info.plist:

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

3. Handle URL callbacks in AppDelegate:

```swift
import GoogleSignIn

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
```

### OAuth Platforms (Reddit, Pinterest, Gmail)

Configure custom URL scheme for OAuth callbacks:

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

## Onboarding Flow

The SDK provides a complete 6-step onboarding process:

1. **Email Input** - User enters email address
2. **Email Verification** - 6-digit code verification
3. **Platform Connection** - Connect social media accounts
4. **Success Screen** - "Never Connect Again" message with auto-advance
5. **PIN Creation** - Secure PIN with validation requirements
6. **AI Training** - Real-time training progress with Socket.IO

### Step Details

#### Email Verification
- Basic email format validation
- API integration for sending verification codes
- Development mode accepts any 6-digit code

#### Platform Connections
- Instagram: Requires Opacity SDK integration
- YouTube: Uses Google Sign-In SDK with YouTube scopes
- Others: OAuth WebView flow with deep link handling

#### PIN Requirements
- Minimum 8 characters
- Must contain numbers
- Must contain special characters
- Real-time validation with visual feedback

#### AI Training
- Socket.IO connection to training server
- Real-time progress updates
- Fallback simulation mode
- Auto-completion when training finishes

## Session Management

```swift
// Check if user has existing session
if OnairosSDK.shared.hasExistingSession() {
    // User has completed onboarding before
    print("Welcome back!")
} else {
    // Show onboarding for new user
    OnairosSDK.shared.presentOnboarding(from: self) { result in
        // Handle result
    }
}

// Clear saved session
OnairosSDK.shared.clearSession()
```

## Error Handling

The SDK provides comprehensive error handling with user-friendly messages:

```swift
OnairosSDK.shared.presentOnboarding(from: self) { result in
    switch result {
    case .success(let data):
        // Handle success
        break
        
    case .failure(let error):
        // Handle specific errors
        switch error {
        case .networkUnavailable:
            showAlert("Please check your internet connection")
        case .userCancelled:
            print("User cancelled onboarding")
        case .platformUnavailable(let platform):
            showAlert("\(platform) is currently unavailable")
        default:
            showAlert(error.localizedDescription)
        }
    }
}
```

## Debug Mode

Enable debug mode for testing:

```swift
let config = OnairosConfig(
    isDebugMode: true,
    allowEmptyConnections: true,  // Skip platform connections
    simulateTraining: true        // Simulate AI training
)
```

Debug mode features:
- All email verification codes accepted
- Platform connections can be skipped
- Training progress is simulated
- Enhanced logging and error reporting

## API Integration

The SDK integrates with the following Onairos API endpoints:

### Live APIs
- Platform OAuth: `/instagram/authorize`, `/youtube/native-auth`, etc.
- User Registration: `/register/enoch`
- Token Management: `/youtube/refresh-token`
- Platform Disconnection: `/revoke`
- Health Check: `/health`

### Simulated APIs (Development)
- Email Verification: `/email/verification`
- AI Training: `/enoch/trainModel/mobile` with Socket.IO

## Customization

### Custom Error Reporting

```swift
class CustomErrorReporter: ErrorReporting {
    func reportError(_ error: OnairosError, context: [String: Any]?) {
        // Send to your analytics service
        Analytics.track("onairos_error", properties: [
            "error": error.localizedDescription,
            "category": error.category.rawValue
        ])
    }
}

// Set custom error reporter
OnairosSDK.shared.setErrorReporter(CustomErrorReporter())
```

### Theme Customization

The SDK uses system colors and adapts to light/dark mode automatically. UI elements follow iOS design guidelines with:

- 24px corner radius for modal
- System blue primary color
- Proper contrast ratios
- Dynamic type support

## Testing

### Unit Tests

```bash
swift test
```

### UI Tests

The SDK includes comprehensive UI tests for each onboarding step:

```swift
func testEmailInputStep() {
    // Test email validation and progression
}

func testVerificationStep() {
    // Test 6-digit code input and validation
}

func testPlatformConnectionStep() {
    // Test platform connection flow
}
```

## Migration Guide

### From React Native SDK

The Swift SDK maintains feature parity with the React Native version:

- Same API endpoints and data structures
- Identical onboarding flow and validation
- Compatible session management
- Cross-platform user experience

## Troubleshooting

### Common Issues

**Instagram authentication not working**
- Ensure Opacity SDK is properly integrated
- Check API key configuration
- Verify production environment settings

**YouTube authentication fails**
- Verify GoogleService-Info.plist is included
- Check URL scheme configuration
- Ensure YouTube Data API v3 is enabled

**OAuth callbacks not working**
- Verify custom URL scheme in Info.plist
- Check deep link handling in AppDelegate
- Test URL scheme format

**Training progress stuck**
- Check network connectivity
- Verify Socket.IO server availability
- Enable debug mode for simulation fallback

### Debug Logging

Enable verbose logging in debug mode:

```swift
let config = OnairosConfig(
    isDebugMode: true
    // ... other config
)
```

## Support

For support and questions:
- 📧 Email: support@onairos.com
- 📖 Documentation: https://docs.onairos.com
- 🐛 Issues: https://github.com/onairos/onairos-swift-sdk/issues

## License

This SDK is proprietary software. See LICENSE file for details.

## Changelog

### 1.0.0
- Initial release
- Complete onboarding flow implementation
- Platform authentication support
- AI training integration
- Comprehensive error handling
- Debug mode and testing features 