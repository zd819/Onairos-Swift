# OnairosSDK Integration Guide

## Overview

OnairosSDK is a comprehensive iOS SDK for social media authentication and data training. It provides seamless integration with multiple platforms including LinkedIn, YouTube, Reddit, Pinterest, and Gmail.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/onairos-swift-sdk.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/YOUR_USERNAME/onairos-swift-sdk.git`
3. Select version and add to your target

### Dependencies

OnairosSDK includes the following dependencies:
- **SocketIO**: For real-time communication
- **GoogleSignIn**: For YouTube authentication (OAuth)

> **Note**: The GoogleSignIn dependency is required for YouTube authentication. When building for iOS, this dependency works perfectly. Command-line builds may show warnings about macOS compatibility, but this doesn't affect iOS app integration.

## Basic Integration

### 1. Import the SDK

```swift
import OnairosSDK
```

### 2. Initialize the SDK

```swift
// Method 1: Using Admin Key (Recommended for production)
Task {
    do {
        try await OnairosSDK.shared.initializeWithAdminKey(
            environment: .production,
            enableLogging: false
        )
        print("✅ SDK initialized successfully")
    } catch {
        print("❌ SDK initialization failed: \(error)")
    }
}

// Method 2: Using Custom API Key
Task {
    do {
        try await OnairosSDK.shared.initializeWithApiKey(
            "your-api-key",
            environment: .production,
            enableLogging: false
        )
        print("✅ SDK initialized successfully")
    } catch {
        print("❌ SDK initialization failed: \(error)")
    }
}

// Method 3: Legacy Configuration (for testing)
let config = OnairosConfig(
    apiKey: "your-api-key",
    environment: .development,
    enableLogging: true,
    isTestMode: true,
    isDebugMode: true,
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

OnairosSDK.shared.initialize(config: config)
```

### 3. Add Connect Button

```swift
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create connect button
        let connectButton = OnairosSDK.shared.createConnectButton { result in
            switch result {
            case .success(let data):
                print("✅ Connection successful: \(data)")
            case .failure(let error):
                print("❌ Connection failed: \(error)")
            }
        }
        
        // Add to view
        view.addSubview(connectButton)
        
        // Set up constraints
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

## Advanced Configuration

### Environment Configuration

```swift
// Development environment
let config = OnairosConfig(
    apiKey: "dev-api-key",
    environment: .development,
    enableLogging: true,
    isTestMode: false,
    isDebugMode: true,
    urlScheme: "your-app-dev",
    appName: "Your App (Dev)"
)

// Production environment
let config = OnairosConfig(
    apiKey: "prod-api-key",
    environment: .production,
    enableLogging: false,
    isTestMode: false,
    isDebugMode: false,
    urlScheme: "your-app",
    appName: "Your App"
)
```

### Test Mode Configuration

```swift
// Test mode - simulates connections without real API calls
let testConfig = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: testConfig)
```

### Debug Mode Configuration

```swift
// Debug mode - enables detailed logging
let debugConfig = OnairosConfig.debugMode()
OnairosSDK.shared.initialize(config: debugConfig)
```

## Platform-Specific Setup

### YouTube Authentication

For YouTube authentication, you need to configure Google Sign-In:

1. **Add Google Services Configuration**:
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add it to your Xcode project

2. **Configure URL Schemes**:
   ```xml
   <!-- In your Info.plist -->
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>your-app-scheme</string>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

3. **Initialize YouTube Authentication**:
   ```swift
   YouTubeAuthManager.shared.initialize(clientID: "your-google-client-id")
   ```

### LinkedIn Authentication

LinkedIn uses OAuth 2.0 with custom URL schemes:

```swift
// Configure in Info.plist
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-scheme</string>
        </array>
    </dict>
</array>
```

## Error Handling

```swift
let connectButton = OnairosSDK.shared.createConnectButton { result in
    switch result {
    case .success(let data):
        // Handle successful connection
        print("Connected successfully: \(data)")
        
    case .failure(let error):
        // Handle different error types
        switch error {
        case .networkUnavailable:
            print("Network is unavailable")
        case .userCancelled:
            print("User cancelled the operation")
        case .authenticationFailed(let reason):
            print("Authentication failed: \(reason)")
        case .invalidConfiguration(let reason):
            print("Invalid configuration: \(reason)")
        case .googleSignInFailed(let reason):
            print("Google Sign-In failed: \(reason)")
        case .trainingFailed(let reason):
            print("Training failed: \(reason)")
        default:
            print("Unknown error: \(error.localizedDescription)")
        }
    }
}
```

## Customization

### Custom Button Text

```swift
let customButton = OnairosSDK.shared.createConnectButton(
    text: "Connect Your Accounts"
) { result in
    // Handle result
}
```

### Custom Styling

```swift
let connectButton = OnairosSDK.shared.createConnectButton { result in
    // Handle result
}

// Customize appearance
connectButton.backgroundColor = .systemBlue
connectButton.setTitleColor(.white, for: .normal)
connectButton.layer.cornerRadius = 12
connectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
```

## Testing

### Test Mode

```swift
// Enable test mode to simulate connections without real API calls
let testConfig = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: testConfig)
```

### Debug Logging

```swift
// Enable debug logging to see detailed SDK operations
let debugConfig = OnairosConfig.debugMode()
OnairosSDK.shared.initialize(config: debugConfig)
```

## Common Issues and Solutions

### 1. GoogleSignIn Build Warnings

**Issue**: Command-line builds show GoogleSignIn macOS compatibility warnings.

**Solution**: This is normal and doesn't affect iOS apps. The warning occurs because Swift Package Manager checks all platform compatibility, but when building an iOS app, only iOS compatibility matters.

### 2. URL Scheme Configuration

**Issue**: OAuth redirects not working.

**Solution**: Ensure your URL schemes are properly configured in `Info.plist` and match the schemes used in your OAuth configurations.

### 3. Network Connectivity

**Issue**: Connection failures in test environments.

**Solution**: Use test mode for development:
```swift
let config = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: config)
```

## Best Practices

1. **Initialize Early**: Initialize the SDK in `application(_:didFinishLaunchingWithOptions:)`
2. **Handle Errors**: Always handle connection errors gracefully
3. **Use Test Mode**: Use test mode during development to avoid unnecessary API calls
4. **Secure API Keys**: Never hardcode production API keys in your source code
5. **URL Schemes**: Use unique URL schemes to avoid conflicts with other apps

## Support

For issues, questions, or feature requests:
- Create an issue on GitHub
- Check the troubleshooting guide
- Review the API documentation

## License

This SDK is released under the MIT License. See LICENSE file for details.