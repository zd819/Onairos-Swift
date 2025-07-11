# YouTube Authentication Dual Mode Setup

## 🎯 Overview

The Onairos Swift SDK now supports **two modes** for YouTube authentication:

1. **Admin/Testing Mode**: Uses hardcoded Google Client ID for internal testing
2. **Normal App Mode**: Uses consuming app's own Google Client ID for production

## 🔧 Technical Changes Made

### YouTubeAuthManager.swift Updates

1. **Added hardcoded admin client ID:**
   ```swift
   private struct Config {
       // Admin/Testing mode client ID (hardcoded for internal testing)
       static let adminClientID = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
   }
   ```

2. **Added dual initialization methods:**
   ```swift
   // For admin/testing mode
   public func initialize()
   
   // For normal consuming apps
   public func initialize(clientID: String)
   ```

3. **Enhanced logging to show which mode is being used**

## 📱 Usage Instructions

### For Your Admin/Testing (Current Need)

**1. Add to AppDelegate.swift:**
```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize for admin/testing mode (uses hardcoded client ID)
        YouTubeAuthManager.shared.initialize()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return YouTubeAuthManager.shared.handleURL(url)
    }
}
```

**2. Add to Info.plist:**
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

### For Future Normal Consuming Apps

**1. Add to AppDelegate.swift:**
```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize with their own Google Client ID
        YouTubeAuthManager.shared.initialize(clientID: "THEIR_GOOGLE_CLIENT_ID")
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return YouTubeAuthManager.shared.handleURL(url)
    }
}
```

**2. They add their own URL scheme to Info.plist based on their Google Client ID**

## 🔍 How It Works

### Admin/Testing Mode
- Uses hardcoded Google Client ID: `1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com`
- URL scheme: `com.googleusercontent.apps.1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o`
- Call: `YouTubeAuthManager.shared.initialize()` (no parameters)

### Normal App Mode
- Uses app's own Google Client ID
- URL scheme: `com.googleusercontent.apps.{CLIENT_ID}`
- Call: `YouTubeAuthManager.shared.initialize(clientID: "their_client_id")`

## 📚 Documentation Updated

- `README.md`: Added quick setup for both modes
- `YOUTUBE_INTEGRATION_SETUP.md`: Updated with dual mode instructions
- `YouTubeAuthManager.swift`: Enhanced with dual initialization methods

## ✅ Benefits

1. **Backward Compatible**: Existing admin/testing setups continue to work
2. **Flexible**: Normal apps can use their own Google Client IDs
3. **Clear Separation**: Different modes for different use cases
4. **Better Logging**: Shows which mode is being used for debugging

## 🚀 Next Steps

1. **For your current testing**: Use admin/testing mode (no client ID needed)
2. **For production apps**: Instruct them to use normal app mode with their own client ID
3. **Documentation**: Point consuming apps to `YOUTUBE_INTEGRATION_SETUP.md` for complete setup instructions 