# OnairosSDK Troubleshooting Guide

## Common Compilation Errors and Solutions

### 1. "Extra argument 'apiKey' in call" Error

**Problem:** You're using the old OnairosConfig constructor format.

**Solution:** Use one of these updated approaches:

```swift
// Option 1: Use the convenience initializer (recommended for testing)
let config = OnairosConfig(
    isTestMode: true,
    isDebugMode: true,
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

// Option 2: Use the static testMode method
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

// Option 3: Use the full initializer with API key
let config = OnairosConfig(
    apiKey: "your-api-key",
    environment: .development,
    enableLogging: true,
    isTestMode: true,
    isDebugMode: true,
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
```

### 2. "Value of type 'OnairosSDK' has no member 'initialize'" Error

**Problem:** You're using an older version of the SDK or your project isn't properly referencing the latest version.

**Solution:** 
1. **Update your SDK version** to v1.2.5 or later
2. **Clean your build folder** (Product → Clean Build Folder in Xcode)
3. **Update your package** (File → Swift Packages → Update to Latest Package Versions)

```swift
// Correct initialization (available in v1.2.5+)
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
OnairosSDK.shared.initialize(config: config)
```

### 3. Asset Catalog Errors ("The app icon set must be a top level object")

**Problem:** Your app's Asset Catalog is missing required app icons or has incorrect structure.

**Solution:**
1. **In Xcode, navigate to your Asset Catalog** (usually `Assets.xcassets`)
2. **Right-click and select "New App Icon"**
3. **Name it "AppIcon"** (exactly)
4. **Add the required icon sizes** (1024x1024 for App Store, plus various sizes for devices)
5. **In your app's Build Settings**, ensure the "App Icon Source" is set to "AppIcon"

### 4. Command Generate/Compile Errors

**Problem:** Asset catalog compilation issues or missing resources.

**Solution:**
1. **Clean your build folder** (Product → Clean Build Folder)
2. **Delete derived data** (Window → Organizer → Projects → Delete Derived Data)
3. **Ensure all required assets are present** in your Asset Catalog
4. **Check your build settings** for correct Asset Catalog references

### 5. OnairosSDK Integration Issues

**Problem:** Your app can't find or properly import the OnairosSDK.

**Solution:**
1. **Ensure you're using the correct import** statement:
   ```swift
   import OnairosSDK
   ```

2. **Check your Package.swift** or Swift Package Manager configuration:
   ```swift
   .package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.2.5")
   ```

3. **For CocoaPods**, ensure your Podfile includes:
   ```ruby
   pod 'OnairosSDK', '~> 1.2.5'
   ```

### 6. Version Compatibility Issues

**Problem:** Using deprecated or removed methods.

**Solution:**
- **Always use the latest SDK version** (v1.2.5+)
- **Check the CHANGELOG.md** for breaking changes
- **Use the recommended initialization pattern**:

```swift
// Recommended for development/testing
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

// Initialize the SDK
OnairosSDK.shared.initialize(config: config)

// Create connect button
let connectButton = OnairosSDK.shared.createConnectButton { result in
    switch result {
    case .success(let onboardingResult):
        print("Onboarding successful: \(onboardingResult)")
    case .failure(let error):
        print("Onboarding failed: \(error)")
    }
}
```

### 7. Swift Version Compatibility

**Problem:** Swift version mismatches or compiler issues.

**Solution:**
1. **Ensure you're using Swift 5.9+** (required for OnairosSDK)
2. **Check your Xcode version** (14.0+ recommended)
3. **Update your project's Swift version** in Build Settings

### 8. Missing Dependencies

**Problem:** Required dependencies aren't properly linked.

**Solution:**
The OnairosSDK automatically includes these dependencies:
- SocketIO
- GoogleSignIn-iOS

If you're getting dependency errors:
1. **Update your Package.swift** to include OnairosSDK properly
2. **Let Xcode resolve package dependencies** automatically
3. **Don't manually add these dependencies** - they're included with OnairosSDK

## Getting Help

If you're still experiencing issues:

1. **Check the Integration Guide** (`INTEGRATION_GUIDE.md`)
2. **Review the API Key Usage Example** (`API_KEY_USAGE_EXAMPLE.md`)
3. **Look at the Demo App** (`Demo/OnairosSDKDemo/`)
4. **Check the Test App** (`TestApp/`) for working examples

## Quick Test

To verify your setup is working:

```swift
import OnairosSDK

// Test the SDK
let config = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: config)

print("✅ OnairosSDK is working properly!")
```

This should compile and run without errors if your setup is correct. 