# 🔑 API Key System Usage Example

## ✅ **IMPLEMENTATION COMPLETE**

The Swift SDK now has the same API key authentication system as React Native! Here's how to use it:

## YouTube Authentication Setup

### Prerequisites

To enable YouTube data access, you need to set up Google Sign-In authentication. This requires a Google Cloud Console project with YouTube API access.

### Quick Setup Instructions

1. **Create a Google Cloud Console Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the YouTube Data API v3

2. **Configure OAuth 2.0 Credentials**
   - Go to "Credentials" in the Google Cloud Console
   - Click "Create Credentials" → "OAuth 2.0 Client IDs"
   - Select "iOS" as the application type
   - Enter your app's bundle identifier
   - Download the `GoogleService-Info.plist` file

3. **Add Google Services to Your Project**
   - Add the `GoogleService-Info.plist` file to your Xcode project
   - Make sure it's included in your target

4. **Configure URL Schemes**
   Add the following to your `Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```
   *(Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist`)*

5. **Handle URL Callbacks**
   Add this to your `AppDelegate.swift`:
   ```swift
   import GoogleSignIn

   func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       return GIDSignIn.sharedInstance.handle(url)
   }
   ```

### SDK Configuration

Once you have your Google client ID, initialize the SDK with YouTube support:

```swift
// Method 1: Admin Key with YouTube
try await OnairosSDK.shared.initializeWithAdminKey(
    environment: .production,
    enableLogging: true,
    googleClientID: "YOUR_GOOGLE_CLIENT_ID"
)

// Method 2: Custom API Key with YouTube
try await OnairosSDK.shared.initializeWithApiKey(
    "your-api-key",
    environment: .production,
    enableLogging: false,
    googleClientID: "YOUR_GOOGLE_CLIENT_ID"
)

// Method 3: Full Configuration
let config = OnairosConfig(
    apiKey: "your-api-key",
    environment: .production,
    enableLogging: false,
    timeout: 30.0,
    googleClientID: "YOUR_GOOGLE_CLIENT_ID"
)
try await OnairosSDK.shared.initializeApiKey(config: config)
```

### Finding Your Google Client ID

Your Google client ID can be found in the `GoogleService-Info.plist` file under the `CLIENT_ID` key, or you can extract it programmatically:

```swift
guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let plist = NSDictionary(contentsOfFile: path),
      let clientId = plist["CLIENT_ID"] as? String else {
    fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
}

// Use clientId for SDK initialization
try await OnairosSDK.shared.initializeWithAdminKey(
    googleClientID: clientId
)
```

### Important Notes

- **YouTube authentication requires a Google client ID** - without it, YouTube connections will fail
- The SDK will automatically detect if YouTube authentication is configured
- If no Google client ID is provided, you'll see a warning message but other platforms will still work
- Make sure your Google Cloud project has the YouTube Data API v3 enabled

## Basic Usage

### Simple Initialization

### **1. Initialize with Admin Key (for Testing)**
```swift
import OnairosSDK

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                // Initialize with admin key for testing
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .development,
                    enableLogging: true,
                    timeout: 30.0
                )
                
                print("✅ SDK initialized with admin key!")
                
                // Now you can use the SDK normally
                setupConnectButton()
                
            } catch {
                print("❌ SDK initialization failed: \(error)")
            }
        }
    }
    
    private func setupConnectButton() {
        let connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data")
        // Add button to your view...
    }
}
```

### **2. Initialize with Custom API Key (for Production)**
```swift
Task {
    do {
        try await OnairosSDK.shared.initializeWithApiKey(
            "your-developer-api-key-here",
            environment: .production,
            enableLogging: false,
            timeout: 30.0
        )
        
        print("✅ SDK initialized with developer key!")
        
    } catch {
        print("❌ SDK initialization failed: \(error)")
    }
}
```

### **3. Manual Configuration (Advanced)**
```swift
Task {
    do {
        let config = OnairosConfig(
            apiKey: "OnairosIsAUnicorn2025", // Admin key
            environment: .development,
            enableLogging: true,
            timeout: 30.0
        )
        
        try await OnairosSDK.shared.initializeApiKey(config: config)
        
        print("✅ SDK initialized with custom config!")
        
    } catch {
        print("❌ SDK initialization failed: \(error)")
    }
}
```

## 🔧 **What Happens Under the Hood**

### **1. Authentication Headers**
All API requests now include:
```http
Authorization: Bearer OnairosIsAUnicorn2025
Content-Type: application/json
User-Agent: OnairosSwift/1.0.0
X-API-Key-Type: admin
X-Timestamp: 2024-01-01T00:00:00.000Z
```

### **2. Automatic Environment Configuration**
- **Development**: Uses `https://dev-api.onairos.uk`
- **Production**: Uses `https://api2.onairos.uk`

### **3. Email Verification with Username**
- After email verification, the SDK saves the user's `userName` from the response
- This username is automatically included in all OAuth requests:
```swift
// OAuth requests now include session data:
{
  "platform": "pinterest",
  "session": {
    "username": "user123" // From email verification response
  }
}
```

## 🎯 **Migration Guide**

### **Before (Legacy)**
```swift
let config = OnairosLegacyConfig(
    urlScheme: "myapp://oauth",
    appName: "My App",
    apiBaseURL: "https://api2.onairos.uk",
    isDebugMode: true
)

OnairosSDK.shared.initialize(config: config)
```

### **After (API Key System)**
```swift
Task {
    try await OnairosSDK.shared.initializeWithAdminKey(
        environment: .development,
        enableLogging: true
    )
}
```

## 🚀 **Complete Example**

```swift
import UIKit
import OnairosSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeSDK()
    }
    
    private func initializeSDK() {
        Task {
            do {
                // Initialize with admin key for testing
                try await OnairosSDK.shared.initializeWithAdminKey()
                
                print("✅ SDK ready!")
                setupUI()
                
            } catch {
                print("❌ SDK initialization failed: \(error)")
                showErrorAlert(error)
            }
        }
    }
    
    private func setupUI() {
        let connectButton = OnairosSDK.shared.createConnectButton { result in
            switch result {
            case .success(let data):
                print("✅ Onboarding completed!")
                print("Connected platforms: \(data.connectedPlatforms.keys)")
                
            case .failure(let error):
                print("❌ Onboarding failed: \(error)")
            }
        }
        
        connectButton.frame = CGRect(x: 50, y: 200, width: 250, height: 50)
        view.addSubview(connectButton)
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "SDK Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

## 🎉 **Result**

✅ **API Key Authentication**: All requests include proper Bearer token  
✅ **Environment Management**: Automatic URL switching based on environment  
✅ **Username in OAuth**: Session data includes username for backend processing  
✅ **Backward Compatibility**: Legacy initialization still works  
✅ **Error Handling**: Proper validation and error reporting  

The Swift SDK now has **feature parity** with the React Native SDK's authentication system! 🚀 