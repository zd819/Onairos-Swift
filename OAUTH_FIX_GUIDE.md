# OAuth Authorization Fix Guide

## 🔍 Issues Identified and Fixed

### 1. **API URL Configuration Issue** ✅ FIXED
**Problem**: The SDK was using `https://dev-api.onairos.uk` (development API) instead of `https://api2.onairos.uk` (production API) for OAuth endpoints.

**Solution**: Updated all configuration methods to use production API by default:
- `OnairosConfig.testMode()` now uses `.production` environment
- `OnairosConfig.debugMode()` now uses `.production` environment  
- `initializeWithAdminKey()` now defaults to `.production` environment

### 2. **Network Error -999 (Cancelled Request)** ✅ FIXED
**Problem**: The -999 error typically occurs when:
- Wrong API endpoints are being called
- URL scheme configuration is missing
- Network requests are being cancelled due to configuration issues

**Solution**: Now using the correct production API endpoints that are properly configured and available.

---

## 🚀 What You Need to Do

### 1. **Configure URL Scheme in Your App**
Add this to your app's `Info.plist` file:

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

**Replace `your-app-scheme` with your actual app's URL scheme** (e.g., `myapp`, `companyapp`, etc.)

### 2. **Initialize SDK with Proper Configuration**
Use one of these initialization methods:

#### Option A: Simple Admin Key Initialization (Recommended)
```swift
import OnairosSDK

// In your AppDelegate or SceneDelegate
Task {
    do {
        try await OnairosSDK.shared.initializeWithAdminKey(
            environment: .production,  // Now uses production API
            enableLogging: true
        )
        print("✅ SDK initialized successfully")
    } catch {
        print("❌ SDK initialization failed: \(error)")
    }
}
```

#### Option B: Legacy Configuration (Always Works)
```swift
import OnairosSDK

let config = OnairosLegacyConfig(
    isDebugMode: true,
    isTestMode: false,  // Set to false for real OAuth
    allowEmptyConnections: true,
    simulateTraining: true,
    apiBaseURL: "https://api2.onairos.uk",  // Production API
    urlScheme: "your-app-scheme",  // Match your Info.plist
    appName: "Your App Name"
)

OnairosSDK.shared.initialize(config: config)
```

### 3. **Handle OAuth Callbacks (Optional)**
Add this to your `AppDelegate.swift` or `SceneDelegate.swift`:

```swift
// For AppDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Handle OAuth callbacks
    if url.scheme == "your-app-scheme" && url.host == "oauth" {
        // OAuth callback handled automatically by SDK
        return true
    }
    return false
}

// For SceneDelegate
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    
    if url.scheme == "your-app-scheme" && url.host == "oauth" {
        // OAuth callback handled automatically by SDK
    }
}
```

---

## 🧪 Testing the Fix

### 1. **Test with Pinterest/Reddit/Gmail**
These platforms use OAuth WebView and should now work properly:

```swift
// After SDK initialization
let connectButton = OnairosSDK.shared.createConnectButton { result in
    switch result {
    case .success(let data):
        print("✅ OAuth successful!")
        print("Connected platforms: \(data.connectedPlatforms)")
    case .failure(let error):
        print("❌ OAuth failed: \(error)")
    }
}
```

### 2. **Check the Logs**
You should now see:
```
🔍 [OAuth] Navigating to: https://api2.onairos.uk/pinterest/authorize
📤 Making authenticated request to: /pinterest/authorize
📥 Response received: 200
```

Instead of the old error:
```
❌ [ERROR] OAuth failed for Pinterest: Network error: The operation couldn't be completed. (NSURLErrorDomain error -999.)
🔍 [OAuth] Navigating to: https://dev-api.onairos.uk/reddit/authorize
```

---

## 🔧 Why This Fixes the Issue

### 1. **Correct API Endpoints**
- **Before**: `https://dev-api.onairos.uk/platform/authorize` (development API - not fully configured)
- **After**: `https://api2.onairos.uk/platform/authorize` (production API - properly configured)

### 2. **Proper OAuth Flow**
The OAuth flow now works as follows:
1. User taps "Connect" on a platform
2. SDK opens WebView to `https://api2.onairos.uk/{platform}/authorize`
3. User signs in on the platform's official page
4. Platform redirects to `https://api2.onairos.uk/callback`
5. Backend processes the OAuth code and redirects to `https://onairos.uk/Home`
6. SDK detects the success redirect and completes the flow

### 3. **Network Error Resolution**
- The -999 error was caused by the development API endpoints not being properly configured
- Production API endpoints are live and properly handle OAuth requests
- URL scheme configuration ensures proper callback handling

---

## 🚨 Important Notes

1. **URL Scheme**: Make sure your URL scheme in Info.plist matches what you pass to the SDK
2. **YouTube**: Still uses Google Sign-In SDK (different flow) - this fix doesn't affect YouTube
3. **Test Mode**: If you want to bypass OAuth entirely for testing, use `isTestMode: true`
4. **Production**: The production API is safe to use for development - it's the working OAuth endpoint

---

## 🎯 Expected Behavior After Fix

### ✅ Working OAuth Flow:
1. Tap "Connect" on Pinterest/Reddit/Gmail
2. WebView opens with platform's login page
3. User signs in successfully
4. Page shows "Authorization successful!" or redirects to success page
5. Modal closes and platform shows as "Connected ✓"

### ❌ If Still Not Working:
1. Check URL scheme in Info.plist matches SDK configuration
2. Verify internet connection
3. Check console logs for specific error messages
4. Try with `isTestMode: true` to bypass OAuth entirely

The OAuth authorization pages should now load properly and complete the authentication flow successfully! 