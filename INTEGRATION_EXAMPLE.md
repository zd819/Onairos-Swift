# OnairosSDK Integration Example - Fix Build Errors

## ❌ Common Build Errors and Solutions

### Error 1: "Extra argument 'apiKey' in call"
**Problem:** You're calling the wrong initialization method.

**❌ Wrong:**
```swift
OnairosSDK.shared.initialize(apiKey: "your-key")
```

**✅ Correct:**
```swift
// Option 1: Legacy method (always works)
let config = OnairosLegacyConfig(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
OnairosSDK.shared.initialize(config: config)

// Option 2: New async method
try await OnairosSDK.shared.initializeWithAdminKey()
```

### Error 2: "Value of type 'OnairosSDK' has no member 'initialize'"
**Problem:** Import or version issue.

**✅ Solution:** Make sure you have the correct import and SDK version.

### Error 3: Asset Catalog Issues
**Problem:** Missing proper app icon structure.

**✅ Solution:** Create proper Assets.xcassets structure (see below).

---

## 🚀 Complete Working Example

### 1. AppDelegate.swift (UIKit)
```swift
import UIKit
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize OnairosSDK
        initializeOnairosSDK()
        
        return true
    }
    
    private func initializeOnairosSDK() {
        // Method 1: Legacy initialization (recommended for stability)
        let config = OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true, // This prevents API calls during development
            allowEmptyConnections: true,
            simulateTraining: true,
            urlScheme: "your-app-scheme", // Replace with your app's scheme
            appName: "Your App Name"
        )
        
        OnairosSDK.shared.initialize(config: config)
        print("✅ OnairosSDK initialized successfully")
        
        // Method 2: Async initialization (alternative)
        Task {
            do {
                try await OnairosSDK.shared.initializeWithAdminKey(
                    environment: .development,
                    enableLogging: true
                )
                print("✅ OnairosSDK initialized with admin key")
            } catch {
                print("❌ Failed to initialize SDK: \(error)")
                // Fallback to legacy method
                OnairosSDK.shared.initialize(config: config)
            }
        }
    }
    
    // Handle URL schemes for OAuth
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle OAuth callbacks here
        return true
    }
}
```

### 2. ViewController.swift
```swift
import UIKit
import OnairosSDK

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    private var connectButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Create and add the OnairosSDK connect button
        connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.handleSuccess(data)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
        
        guard let connectButton = connectButton else { return }
        
        view.addSubview(connectButton)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 200),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func handleSuccess(_ data: OnboardingData) {
        statusLabel.text = "✅ Connected successfully!"
        print("🎉 Connected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))")
        
        // Show success alert
        let alert = UIAlertController(
            title: "Success! 🎉",
            message: "Your data has been connected successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default))
        present(alert, animated: true)
    }
    
    private func handleError(_ error: OnairosError) {
        statusLabel.text = "❌ Connection failed"
        print("❌ Error: \(error.localizedDescription)")
        
        // Show error alert
        let alert = UIAlertController(
            title: "Connection Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### 3. SwiftUI App.swift
```swift
import SwiftUI
import OnairosSDK

@main
struct YourApp: App {
    
    init() {
        initializeOnairosSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: handleURL)
        }
    }
    
    private func initializeOnairosSDK() {
        // Initialize SDK
        let config = OnairosLegacyConfig(
            isDebugMode: true,
            isTestMode: true,
            allowEmptyConnections: true,
            simulateTraining: true,
            urlScheme: "your-app-scheme",
            appName: "Your App Name"
        )
        
        OnairosSDK.shared.initialize(config: config)
        print("✅ OnairosSDK initialized")
    }
    
    private func handleURL(_ url: URL) {
        // Handle OAuth callbacks
        print("Received URL: \(url)")
    }
}
```

### 4. SwiftUI ContentView.swift
```swift
import SwiftUI
import OnairosSDK

struct ContentView: View {
    @State private var showingOnboarding = false
    @State private var statusMessage = "Ready to connect"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Onairos SDK Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(statusMessage)
                .foregroundColor(.secondary)
            
            Button("Connect Your Data") {
                presentOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private func presentOnboarding() {
        // Find the current UIViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            statusMessage = "❌ Could not find view controller"
            return
        }
        
        // Present onboarding
        OnairosSDK.shared.presentOnboarding(from: rootViewController) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    statusMessage = "✅ Connected successfully!"
                    print("🎉 Connected platforms: \(data.connectedPlatforms.keys.joined(separator: ", "))")
                case .failure(let error):
                    statusMessage = "❌ Connection failed: \(error.localizedDescription)"
                    print("❌ Error: \(error)")
                }
            }
        }
    }
}
```

---

## 🔧 Fix Asset Catalog Issues

### Create proper Assets.xcassets structure:

1. **Create Assets.xcassets folder** in your project
2. **Add AppIcon.appiconset** folder inside Assets.xcassets
3. **Create Contents.json** file in AppIcon.appiconset:

```json
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## 🎯 Key Points for Success

### ✅ DO:
1. **Use the correct initialization method** - `initialize(config:)` not `initialize(apiKey:)`
2. **Use test mode for development** - prevents API call issues
3. **Handle OAuth URL schemes** - add URL scheme to Info.plist
4. **Create proper asset catalog structure**
5. **Use the completion handlers** for success/error handling

### ❌ DON'T:
1. **Don't call `initialize(apiKey:)`** - this method doesn't exist
2. **Don't use production mode during development** - can cause modal dismissal
3. **Don't forget URL schemes** - needed for OAuth platforms
4. **Don't skip error handling** - always handle both success and failure cases

---

## 🔗 URL Scheme Setup

Add this to your **Info.plist**:

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

---

## 🧪 Testing

The SDK includes **test mode** which:
- ✅ Bypasses all real API calls
- ✅ Accepts any email/verification code
- ✅ Simulates platform connections
- ✅ Prevents modal dismissal issues
- ✅ Perfect for development and testing

Use test mode by setting `isTestMode: true` in your configuration.

---

## 📞 Support

If you're still having issues:
1. Check the SDK version: `OnairosSDK.version`
2. Enable logging: `enableLogging: true`
3. Use test mode: `isTestMode: true`
4. Check the console for detailed error messages

The SDK is designed to work out of the box with minimal setup. The examples above should resolve all common build errors and get you up and running quickly. 