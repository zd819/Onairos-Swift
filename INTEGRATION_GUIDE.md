# Onairos Swift SDK - LLM/AI Assistant Integration Guide

> **Optimized for LLMs, Coding Assistants, and Cursor**  
> Complete copy-paste instructions for automated integration

## 🤖 AI Assistant Quick Setup

### Step 1: Add Package Dependency

**For Package.swift projects:**
```swift
// Add to Package.swift dependencies array
.package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.1")

// Add to target dependencies
.product(name: "OnairosSDK", package: "Onairos-Swift")
```

**For Xcode projects:**
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/zd819/Onairos-Swift.git`
3. Version: `1.0.1` or `Up to Next Major`

### Step 2: Required Dependencies Setup

**IMPORTANT: OnairosSDK automatically includes all required dependencies!**

**For Package.swift projects (RECOMMENDED):**
```swift
dependencies: [
    .package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.1")
    // ✅ SocketIO and GoogleSignIn are automatically included!
],
targets: [
    .target(
        name: "YourAppName",
        dependencies: [
            .product(name: "OnairosSDK", package: "Onairos-Swift")
            // ✅ No need to add SocketIO or GoogleSignIn manually
        ]
    )
]
```

**For Xcode projects:**
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/zd819/Onairos-Swift.git`
3. Version: `1.0.1` or `Up to Next Major`
4. ✅ **All dependencies (SocketIO, GoogleSignIn) are automatically resolved!**

**What gets installed automatically:**
- ✅ OnairosSDK (main SDK)
- ✅ SocketIO (~16.0.0) - for real-time AI training
- ✅ GoogleSignIn (~7.0.0) - for YouTube authentication
- ✅ All required frameworks and dependencies

### Step 3: iOS Configuration Files

**Create/Update Info.plist:**
```xml
<!-- Add to Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>onairos-oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR-APP-SCHEME</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>google-signin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR-GOOGLE-CLIENT-ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
    <string>googlemail</string>
</array>
```

**Create GoogleService-Info.plist:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project → Enable YouTube Data API v3
3. Create OAuth 2.0 credentials for iOS
4. Download `GoogleService-Info.plist`
5. Add to Xcode project root

### Step 4: AppDelegate Setup

**SwiftUI App:**
```swift
import SwiftUI
import GoogleSignIn
import OnairosSDK

@main
struct YourApp: App {
    init() {
        configureGoogleSignIn()
        configureOnairosSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: handleURL)
        }
    }
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    private func configureOnairosSDK() {
        let config = OnairosConfig(
            isDebugMode: true, // Set false for production
            urlScheme: "YOUR-APP-SCHEME", // Replace with your scheme
            appName: "Your App Name"
        )
        OnairosSDK.shared.initialize(config: config)
    }
    
    private func handleURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
}
```

**UIKit AppDelegate:**
```swift
import UIKit
import GoogleSignIn
import OnairosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // Configure Onairos SDK
        let config = OnairosConfig(
            isDebugMode: true, // Set false for production
            urlScheme: "YOUR-APP-SCHEME", // Replace with your scheme
            appName: "Your App Name"
        )
        OnairosSDK.shared.initialize(config: config)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
```

### Step 5: Implementation Code

**SwiftUI Implementation:**
```swift
import SwiftUI
import OnairosSDK

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Your App")
                .font(.title)
            
            // Onairos Connect Button
            OnairosConnectButtonView()
        }
        .padding()
    }
}

struct OnairosConnectButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let button = OnairosSDK.shared.createConnectButton(text: "Connect Your Data")
        return button
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
```

**UIKit Implementation:**
```swift
import UIKit
import OnairosSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Create Onairos connect button
        let connectButton = OnairosSDK.shared.createConnectButton(text: "Connect Your Data")
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(connectButton)
        
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 280),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
```

### Step 6: Advanced Configuration (Optional)

**Custom Configuration:**
```swift
let config = OnairosConfig(
    isDebugMode: false, // Production mode
    allowEmptyConnections: false, // Require platform connections
    simulateTraining: false, // Use real Socket.IO training
    apiBaseURL: "https://api2.onairos.uk", // Default API
    platforms: [.instagram, .youtube, .reddit, .pinterest, .gmail], // Enabled platforms
    opacityAPIKey: "YOUR-OPACITY-API-KEY", // For Instagram
    googleClientID: "YOUR-GOOGLE-CLIENT-ID", // For YouTube
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
```

**Handle Completion:**
```swift
// Manual presentation with completion handler
OnairosSDK.shared.presentOnboarding(from: self) { result in
    switch result {
    case .success(let data):
        print("Onboarding completed successfully")
        print("Connected platforms: \(data.connectedPlatforms.keys)")
        // Handle success - user data available
        
    case .failure(let error):
        print("Onboarding failed: \(error.localizedDescription)")
        // Handle error
    }
}
```

## 🛠️ Automated Setup Script

**Run this in your project directory:**
```bash
# Create required files structure
mkdir -p Sources/YourApp
touch Sources/YourApp/App.swift
touch Sources/YourApp/ContentView.swift

# Add Package.swift if not exists
if [ ! -f Package.swift ]; then
cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [.iOS(.v14)],
    products: [
        .executable(name: "YourApp", targets: ["YourApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.1"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "YourApp",
            dependencies: [
                .product(name: "OnairosSDK", package: "Onairos-Swift")
            ]
        )
    ]
)
EOF
fi

echo "✅ Onairos SDK setup complete!"
echo "📝 Don't forget to:"
echo "   1. Replace YOUR-APP-SCHEME with your actual URL scheme"
echo "   2. Add GoogleService-Info.plist to your project"
echo "   3. Update Info.plist with URL schemes"
```

## 🔧 Troubleshooting for AI Assistants

### Common Issues & Fixes

**1. "Package Resolution Failed" Error:**
```bash
# Solution A: Clear package cache
rm -rf .build
rm Package.resolved
# Then rebuild

# Solution B: In Xcode
# File → Swift Packages → Reset Package Caches
# Product → Clean Build Folder
# Then rebuild
```

**2. "No such module 'OnairosSDK'" Error:**
```swift
// Ensure repository is public and accessible
// Check Package.swift has correct dependency:
.package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.1")

// Verify import statement:
import OnairosSDK  // Correct
```

**3. GoogleService-Info.plist not found:**
```swift
// Add this check in your configuration
guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
    print("⚠️ GoogleService-Info.plist missing - YouTube auth will fail")
    return
}
```

**4. URL Scheme not working:**
```xml
<!-- Verify in Info.plist -->
<string>your-app-scheme</string> <!-- Must match OnairosConfig.urlScheme -->
```

**5. Build errors:**
```bash
# Clean and rebuild
swift package clean
swift package resolve
swift build

# Or in Xcode:
# Product → Clean Build Folder
# File → Swift Packages → Resolve Package Versions
```

**6. Dependency conflicts:**
```swift
// If you get version conflicts, use exact versions:
.package(url: "https://github.com/zd819/Onairos-Swift.git", exact: "1.0.1")
```

## 📋 Verification Checklist

Copy this checklist for AI assistants to verify setup:

- [ ] Package dependency added to Package.swift or Xcode
- [ ] GoogleService-Info.plist added to project
- [ ] Info.plist updated with URL schemes
- [ ] AppDelegate/App configured with Google Sign-In
- [ ] OnairosSDK initialized with correct config
- [ ] Connect button added to UI
- [ ] URL scheme matches between Info.plist and config
- [ ] Project builds without errors
- [ ] Button appears and is tappable

## 🚀 Production Deployment

**Before releasing:**
```swift
let config = OnairosConfig(
    isDebugMode: false, // ← Change to false
    allowEmptyConnections: false, // ← Require connections
    simulateTraining: false, // ← Use real training
    urlScheme: "your-production-scheme",
    appName: "Your App Name"
)
```

**Required for production:**
- [ ] Opacity API key for Instagram
- [ ] Google Cloud Project with YouTube API enabled
- [ ] Production URL schemes registered
- [ ] App Store privacy declarations updated

---

## 📞 Support

For AI assistants encountering issues:
1. Check the verification checklist above
2. Ensure all dependencies are properly resolved
3. Verify URL schemes match exactly
4. Test in debug mode first before production

**Repository:** https://github.com/zd819/Onairos-Swift  
**Version:** 1.0.1+