# Onairos Swift SDK - LLM/AI Assistant Integration Guide

> **Optimized for LLMs, Coding Assistants, and Cursor**  
> Complete copy-paste instructions for automated integration

## 🚨 **LATEST UPDATE v1.0.28 - Complete Flow Fixed**

**All modal dismissal issues RESOLVED! Complete onboarding flow now works perfectly:**
- ✅ Modal stays open through all steps (email → verify → connect → PIN → training)
- ✅ Beautiful UI with official Onairos branding
- ✅ Comprehensive debug logging for troubleshooting
- ✅ All constructor mismatches fixed
- ✅ Memory leaks prevented with proper coordinator lifecycle

## 🚨 CRITICAL: Fix for Modal Dismissal Issues

**If your modal closes immediately after entering an email, follow this fix:**

### The Problem
Three main issues can cause unexpected modal dismissal:
1. **API Failure**: Email verification API calls fail and dismiss the modal
2. **Wrong Configuration**: Using debug mode with production API causes failures
3. **Missing Error Handling**: API errors aren't handled gracefully

### The Solution ✅

**Use `OnairosConfig.testMode()` for development:**

```swift
import OnairosSDK

// ✅ CORRECT - Prevents modal dismissal issues
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

OnairosSDK.shared.initialize(config: config)

// ❌ WRONG - May cause modal dismissal on API failures
let badConfig = OnairosConfig(
    isDebugMode: true,  // Makes real API calls that can fail
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)
```

### Why Test Mode Works
- ✅ **No real API calls** - Eliminates network failure points
- ✅ **Accepts any email** - No validation failures
- ✅ **Accepts any verification code** - No authentication issues
- ✅ **Complete flow simulation** - Email → Verify → Connect → PIN → Training
- ✅ **Prevents modal dismissal** - No error conditions that trigger dismissal

### Configuration Comparison

| Mode | API Calls | Modal Stability | Use Case |
|------|-----------|-----------------|----------|
| `testMode()` | ❌ Simulated | ✅ Stable | Development & Testing |
| `isDebugMode: true` | ✅ Real | ⚠️ May dismiss on failure | API debugging only |
| Production | ✅ Real | ✅ Stable (when working) | Live app |

## 🤖 AI Assistant Quick Setup

### Step 1: Add Package Dependency

**For Package.swift projects:**
```swift
// Add to Package.swift dependencies array
.package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.28")

// Add to target dependencies
.product(name: "OnairosSDK", package: "Onairos-Swift")
```

**For Xcode projects:**
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/zd819/Onairos-Swift.git`
3. Version: `1.0.28` or `Up to Next Major`

### Step 2: Required Dependencies Setup

**IMPORTANT: OnairosSDK automatically includes all required dependencies!**

**For Package.swift projects (RECOMMENDED):**
```swift
dependencies: [
    .package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.28")
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
3. Version: `1.0.28` or `Up to Next Major`
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
        // CRITICAL: Use testMode() for development to avoid premature modal dismissal
        let config = OnairosConfig.testMode(
            urlScheme: "YOUR-APP-SCHEME", // Replace with your scheme
            appName: "Your App Name"
        )
        
        // Alternative production config:
        // let config = OnairosConfig(
        //     isDebugMode: false,
        //     urlScheme: "YOUR-APP-SCHEME",
        //     appName: "Your App Name"
        // )
        
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
        // CRITICAL: Use testMode() for development to avoid premature modal dismissal
        let config = OnairosConfig.testMode(
            urlScheme: "YOUR-APP-SCHEME", // Replace with your scheme
            appName: "Your App Name"
        )
        
        // Alternative production config:
        // let config = OnairosConfig(
        //     isDebugMode: false,
        //     urlScheme: "YOUR-APP-SCHEME",
        //     appName: "Your App Name"
        // )
        
        OnairosSDK.shared.initialize(config: config)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
```

### Step 5: Complete Onboarding Flow Documentation

**🎯 The Complete 6-Step Onboarding Journey:**

1. **📧 Email Step**: User enters their email address
   - Validates email format in real-time
   - In test mode: accepts any valid email format
   - In production: sends verification email via API

2. **✅ Verification Step**: User enters 6-digit verification code
   - Validates code format (6 digits)
   - In test mode: accepts any 6-digit code
   - In production: validates against sent code

3. **🔗 Connect Step**: User connects social media platforms
   - Instagram (via Opacity SDK)
   - YouTube (via Google Sign-In)
   - Reddit, Pinterest, Gmail (via OAuth)
   - Can proceed with or without connections in debug/test mode

4. **🎉 Success Step**: Brief success confirmation screen
   - Auto-advances after 1.5-2 seconds
   - Shows "Success!" message

5. **🔐 PIN Step**: User creates secure PIN
   - Minimum 8 characters
   - Must include numbers and special characters
   - Real-time validation with visual feedback

6. **🤖 Training Step**: AI model training
   - Real-time progress updates via WebSocket
   - Progress bar with status messages
   - Completes when training reaches 100%

**🎨 Beautiful UI Features:**
- ✅ Official Onairos logo throughout the flow
- ✅ Smooth animations and transitions
- ✅ Loading states and progress indicators
- ✅ Error handling with helpful messages
- ✅ Responsive design for all screen sizes

### Step 6: Critical Configuration Fix

**🚨 IMPORTANT: Using v1.0.28 - All Issues Fixed!**

If your modal closes immediately after entering an email, you're likely using the wrong configuration. **You MUST use `testMode()` during development:**

```swift
// ✅ CORRECT - Use this for development/testing
let config = OnairosConfig.testMode(
    urlScheme: "your-app-scheme",
    appName: "Your App Name"
)

// ❌ WRONG - This may cause premature modal dismissal
let config = OnairosConfig(
    isDebugMode: true,
    urlScheme: "your-app-scheme", 
    appName: "Your App Name"
)
```

**Why testMode() is required:**
- ✅ Bypasses all API calls that might fail during development
- ✅ Accepts any email/verification code for testing
- ✅ Ensures the full flow: Email → Verify → Connect → PIN → Training
- ✅ Prevents premature modal dismissal

### Step 6: Implementation Code

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
        .package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.11"),
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

### Recent Fixes (v1.0.11)

**🚨 SWIFT 6.1 COMPATIBILITY FIXES:**

**v1.0.11 (Latest):**
- ✅ **Fixed Swift 6.1 concurrency issues** - Resolved MainActor isolation errors in TrainingStepViewController
- ✅ **Fixed "Call to main actor-isolated instance method" errors** - Proper Task { @MainActor in } usage
- ✅ **Strict concurrency compliance** - All UI operations properly isolated to main actor
- ✅ **Complete Swift 6.1 compatibility** - Zero compilation errors with strict concurrency checking

**v1.0.10:**
- ✅ **Fixed OnairosError enum cases** - Added missing networkError, authenticationFailed, validationFailed, and serverError cases
- ✅ **Complete error handling** - All OnairosError usage now properly defined throughout the SDK
- ✅ **Resolved "Type has no member" errors** - Fixed all remaining Swift 6.1 compilation issues
- ✅ **Enhanced error categorization** - Improved error descriptions and recovery suggestions

**v1.0.9:**
- ✅ **Fixed Swift 6.1 generic type inference issues** - Resolved "Generic parameter 'T' could not be inferred" errors
- ✅ **Fixed OnairosAPIClient access level** - Made initializer public to resolve private protection level errors
- ✅ **Split performRequest methods** - Separated into specific methods to avoid overloading conflicts
- ✅ **Fixed method signature mismatches** - Resolved "Argument passed to call that takes no arguments" errors
- ✅ **Complete Swift 6.1 compatibility** - All compilation issues resolved for latest Swift version

**v1.0.8:**
- ✅ **Fixed final SocketIO compatibility** - Removed invalid `.connectTimeout` option
- ✅ **Complete SocketIO 16.0.0+ compatibility** - Only valid configuration options used

**v1.0.7:**
- ✅ **Fixed OnboardingCoordinator constructor issues** - Resolved UserRegistrationRequest parameter mismatch
- ✅ **Fixed SocketIO API compatibility** - Updated .compress and .connectTimeout for newer versions
- ✅ **Fixed DeviceInfo Codable conformance** - Removed problematic default value assignments
- ✅ **Fixed all remaining compilation errors** - Complete compatibility with latest Swift/Xcode

**⚠️ IMPORTANT: Versions 1.0.1-1.0.10 had compilation bugs. Use v1.0.11 or later for Swift 6.1.**

**If upgrading from any earlier version:**
```bash
# Clear package cache and rebuild
rm -rf .build
rm Package.resolved
swift package clean
swift package resolve
swift build
```

### Common Issues & Fixes

**1. "Package Resolution Failed" Error:**
```bash
# Solution A: Clear package cache
rm -rf .build
rm Package.resolved
swift package clean
swift package resolve
# Then rebuild

# Solution B: In Xcode
# File → Swift Packages → Reset Package Caches
# Product → Clean Build Folder
# File → Swift Packages → Update to Latest Package Versions
# Then rebuild
```

**2. "No such module 'OnairosSDK'" Error:**
```swift
// Ensure repository is public and accessible
// Check Package.swift has correct dependency:
.package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.11")

// Verify import statement:
import OnairosSDK  // Correct

// If still failing, force update:
// swift package update
// Or in Xcode: File → Swift Packages → Update to Latest Package Versions
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

**5. Swift Compilation Errors:**
```swift
// Common errors and solutions:

// Error: "Cannot find 'UIDevice' in scope"
// Solution: Fixed in v1.0.6+ (added missing UIKit import)

// Error: "Type 'UserRegistrationRequest' does not conform to protocol 'Decodable'"
// Solution: Fixed in v1.0.6+ (proper Codable implementation)

// Error: "Cannot convert value of type 'Array<String>' to expected argument type '[String : PlatformData]'"
// Solution: Fixed in v1.0.7 (corrected constructor parameters)

// Error: "Enum case 'compress' has no associated values"
// Solution: Fixed in v1.0.7 (updated SocketIO API usage)

// Error: "Type has no member 'timeout'"
// Solution: Fixed in v1.0.7 (changed to .connectTimeout)

// Error: "Generic parameter 'T' could not be inferred"
// Solution: Fixed in v1.0.9 (split performRequest methods for type safety)

// Error: "'OnairosAPIClient' initializer is inaccessible due to 'private' protection level"
// Solution: Fixed in v1.0.9 (made initializer public)

// Error: "Argument passed to call that takes no arguments"
// Solution: Fixed in v1.0.9 (corrected method signatures)

// Error: "expected 'func' keyword in instance method declaration"
// Solution: Fixed in v1.0.4+ (removed invalid protected keyword)

// Error: "Failed frontend command"
// Solution: Update to v1.0.9 and clean build

// Error: "Type 'OnairosError' has no member 'networkError'"
// Solution: Fixed in v1.0.10 (added missing enum cases)

// Error: "Type 'OnairosError' has no member 'authenticationFailed'"
// Solution: Fixed in v1.0.10 (added missing enum cases)

// Error: "Type 'OnairosError' has no member 'validationFailed'"
// Solution: Fixed in v1.0.10 (added missing enum cases)

// Error: "Type 'OnairosError' has no member 'serverError'"
// Solution: Fixed in v1.0.10 (added missing enum cases)

// Error: "Call to main actor-isolated instance method 'stopTrainingAnimation()' in a synchronous nonisolated context"
// Solution: Fixed in v1.0.11 (proper MainActor isolation with Task blocks)

// CRITICAL: Update to v1.0.11 for complete Swift 6.1 compatibility
```

## 🧪 Testing Your Integration

### Running the Test Suite

The SDK includes a comprehensive test suite to validate your integration:

```bash
# Run the test suite
cd TestApp
swift run TestApp
```

### Expected Test Output

When all tests pass, you should see:

```
🚀 Starting Comprehensive Onairos Swift SDK Test Suite...
============================================================

🧪 Testing: OnairosConfig Creation
✅ PASSED: OnairosConfig Creation

🧪 Testing: OnairosConfig Test Mode
✅ PASSED: OnairosConfig Test Mode

... (additional tests)

============================================================
📊 TEST RESULTS SUMMARY
============================================================
✅ Tests Passed: 20
❌ Tests Failed: 0
📈 Success Rate: 100%

🎉 ALL TESTS PASSED! 🎉
✨ Your Onairos Swift SDK is fully functional and ready for integration!
```

### Manual Testing with Demo App

1. **Build and run the demo app:**
   ```bash
   cd Demo/OnairosSDKDemo
   swift run OnairosSDKDemo
   ```

2. **Test the onboarding flow:**
   - Click "Connect Data" button
   - Enter any email address (test mode accepts all)
   - Enter any 6-digit code (test mode accepts all)
   - Skip or connect platforms
   - Create a PIN (minimum 8 chars, numbers, special chars)
   - Watch training simulation complete

3. **Verify test mode features:**
   - Look for "🧪 TEST MODE" indicators
   - Check console logs for detailed flow tracking
   - Confirm no real API calls are made

### Integration Validation Checklist

#### ✅ **Basic Setup**
- [ ] SDK imports without errors
- [ ] Configuration creates successfully
- [ ] SDK initializes without crashes
- [ ] Connect button appears and responds to taps

#### ✅ **Test Mode Validation**
- [ ] Test mode accepts any email
- [ ] Test mode accepts any verification code
- [ ] Full onboarding flow displays (Email → Verify → Connect → PIN → Training)
- [ ] Training simulation completes successfully
- [ ] No network requests made in test mode

#### ✅ **Error Handling**
- [ ] Invalid configurations handled gracefully
- [ ] Network errors don't crash the app
- [ ] User cancellation handled properly
- [ ] UI remains responsive during operations

#### ✅ **Memory Safety**
- [ ] No force unwraps causing crashes
- [ ] NaN values protected in progress calculations
- [ ] State resets properly between sessions
- [ ] No memory leaks in onboarding flow

### Common Integration Issues

#### **Issue: SDK doesn't initialize**
```swift
// ❌ Wrong - missing configuration
OnairosSDK.shared.createConnectButton { _ in }

// ✅ Correct - initialize first
let config = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: config)
let button = OnairosSDK.shared.createConnectButton { _ in }
```

#### **Issue: App crashes with CoreGraphics errors**
This was fixed in v1.0.19 with comprehensive NaN protection. Update to latest version.

#### **Issue: Onboarding flow doesn't appear**
```swift
// ✅ Ensure view controller is presented
present(onboardingViewController, animated: true)

// ✅ Check configuration
let config = OnairosConfig.testMode() // Use test mode for development
```

#### **Issue: Training gets stuck**
```swift
// ✅ Use test mode for development
let config = OnairosConfig.testMode()
config.simulateTraining = true // Ensures training simulation runs
```

### Production Deployment

When ready for production:

1. **Switch to production configuration:**
   ```swift
   let config = OnairosConfig(
       isDebugMode: false,
       platforms: [.instagram, .youtube], // Your supported platforms
       urlScheme: "your-app-scheme",
       appName: "Your App Name"
   )
   ```

2. **Configure URL schemes in Info.plist:**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>your-app-scheme</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>your-app-scheme</string>
           </array>
       </dict>
   </array>
   ```

3. **Add platform-specific configurations:**
   - Google Sign-In: Add GoogleService-Info.plist
   - Instagram: Configure OAuth redirect URLs
   - Other platforms: Follow platform-specific setup guides

## 🚨 Critical Troubleshooting

### **Issue: Modal Closes Immediately After Email Entry**

**This is the most common issue. Here's the fix:**

```swift
// ❌ WRONG - Causes premature modal dismissal
let config = OnairosConfig(
    isDebugMode: true,
    urlScheme: "your-scheme",
    appName: "Your App"
)

// ✅ CORRECT - Use testMode() for development
let config = OnairosConfig.testMode(
    urlScheme: "your-scheme", 
    appName: "Your App"
)
```

**Root Cause:** The regular config tries to make API calls that fail during development, triggering error handlers that dismiss the modal.

**Solution:** `testMode()` bypasses all API calls and accepts any input, ensuring the full flow works.

### **Issue: Flow Doesn't Follow Expected Sequence**

**Expected Flow:**
1. Email Input
2. Email Verification (6-digit code)
3. Platform Connection (Instagram, YouTube, etc.)
4. PIN Creation
5. AI Training

**If flow skips steps or behaves unexpectedly:**

```swift
// ✅ Ensure you're using testMode() for development
let config = OnairosConfig.testMode()

// ✅ Check that you're not mixing test and production configs
// Don't use isTestMode: false with isDebugMode: true
```

### **Issue: "Invalid redeclaration" Compile Errors**

**Fixed in v1.0.23**. Update to latest version:

```swift
.package(url: "https://github.com/zd819/Onairos-Swift.git", from: "1.0.23")
```

### **Issue: App Crashes During Training**

**Fixed in v1.0.19 with NaN protection**. Update to latest version.

### **Issue: SDK Not Initializing**

```swift
// ❌ Wrong - calling methods before initialization
OnairosSDK.shared.presentOnboarding(from: self) { _ in }

// ✅ Correct - initialize first
let config = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: config)
OnairosSDK.shared.presentOnboarding(from: self) { _ in }
```

### **Issue: Missing GoogleService-Info.plist**

Only required for production YouTube integration. For development with `testMode()`, this file is not needed.

### Support

- **Documentation**: See `DESIGN_OVERVIEW.md` for architecture details
- **Examples**: Check `Demo/OnairosSDKDemo/` for complete implementation
- **Testing**: Run `TestApp` for comprehensive validation
- **Issues**: Report bugs via GitHub issues

## Advanced Configuration