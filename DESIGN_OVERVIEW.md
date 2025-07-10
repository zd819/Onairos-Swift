# Onairos React Native SDK - Design Overview for Swift Implementation

## Architecture Overview

The Onairos React Native SDK provides a universal onboarding system for social media authentication and AI model training. The SDK follows a modal-based flow with multiple steps and platform-specific authentication methods.

## Core Flow Design

### 1. Modal Structure
- **Height**: 80% of screen height
- **Style**: Bottom sheet with rounded top corners (24px radius)
- **Background**: Semi-transparent overlay (rgba(0,0,0,0.5))
- **Animation**: Slide up from bottom with spring animation

### 2. Step-by-Step Flow

```
Email Input → Email Verification → Platform Connection → PIN Creation → AI Training → Completion
```

#### Step 1: Email Input (`email`)
- **Purpose**: Collect user email for account creation/verification
- **UI Elements**:
  - Onairos logo (centered)
  - "Welcome to Onairos" title
  - Email input field (positioned higher to avoid keyboard blocking)
  - Continue button (disabled until valid email entered)
- **Validation**: Basic email regex validation
- **API Call**: `POST https://api2.onairos.uk/email/verification`

#### Step 2: Email Verification (`verify`)
- **Purpose**: Verify email with 6-digit code
- **UI Elements**:
  - 6 individual input squares for digits
  - Development mode indicator (accepts any code)
  - Back to email button
- **API Call**: `POST https://api2.onairos.uk/email/verification` (with action: 'verify')
- **Development Mode**: All codes pass through for testing

#### Step 3: Platform Connection (`connect`)
- **Purpose**: Connect social media platforms
- **UI Elements**:
  - App icon → Arrow → Onairos icon header
  - Platform list with toggle switches
  - Privacy message: "None of your app data is shared with ANYONE"
  - Cancel/Connect buttons
- **Platforms**: Instagram, YouTube, Reddit, Pinterest, Gmail
- **Testing Mode**: Can proceed without connecting any platforms

#### Step 4: Success Screen (`success`)
- **Purpose**: Show "Never Connect Again" message
- **UI Elements**:
  - Green checkmark icon
  - "Never Connect Again!" title
  - Session saving explanation
  - Auto-progress indicator
- **Duration**: 3 seconds auto-advance

#### Step 5: PIN Creation (`pin`)
- **Purpose**: Create secure PIN for account
- **Requirements**:
  - Minimum 8 characters
  - Must include numbers
  - Must include special characters
- **UI Elements**:
  - PIN input with validation
  - Requirements checklist
  - Back button

#### Step 6: AI Training (`training`)
- **Purpose**: Train personalized AI model
- **UI Elements**:
  - Onairos logo
  - "Training Your AI" title
  - Progress bar with percentage
  - Status text
  - Cancel button (initially), Complete button (when done)
- **API Integration**: Socket.IO connection to `https://api2.onairos.uk`
- **Auto-completion**: Automatically completes after 1.5 seconds when done

### 3. Data Request Modal (for existing users)
- **Trigger**: When existing user detected (currently disabled for testing)
- **Purpose**: Request permission for data access
- **UI Elements**:
  - App name in header
  - Platform permissions list
  - Accept/Cancel buttons

## Platform Authentication Methods

### Instagram (Opacity SDK)
- **Method**: Exclusive use of Opacity SDK
- **API Key**: `OsamaTest-7bde2407-7360-462a-86b4-b26d7f890cbb`
- **Environment**: Production
- **Flow**: `opacityInit()` → `opacityGet('flow:instagram:profile')`
- **No OAuth Fallback**: Instagram requires Opacity SDK

### YouTube (Native SDK)
- **Method**: Google Sign-In SDK with YouTube scope
- **Requirements**: 
  - Each app must create own Google Cloud Project
  - Own OAuth credentials (cannot share)
  - YouTube Data API v3 enabled
- **Scopes**: `https://www.googleapis.com/auth/youtube.readonly`
- **API Endpoint**: `POST https://api2.onairos.uk/youtube/native-auth`
- **Token Refresh**: `POST https://api2.onairos.uk/youtube/refresh-token`

### Other Platforms (OAuth WebView)
- **Reddit**: `https://api2.onairos.uk/reddit/authorize`
- **Pinterest**: `https://api2.onairos.uk/pinterest/authorize`
- **Gmail**: `https://api2.onairos.uk/gmail/authorize`
- **Method**: WebView-based OAuth flow
- **Deep Link Handling**: Custom URL scheme for callback

## API Endpoints Overview

### Live APIs (Production Ready)
1. **Platform OAuth**:
   - Instagram: `POST https://api2.onairos.uk/instagram/authorize`
   - YouTube: `POST https://api2.onairos.uk/youtube/native-auth`
   - Reddit: `POST https://api2.onairos.uk/reddit/authorize`
   - Pinterest: `POST https://api2.onairos.uk/pinterest/authorize`
   - Gmail: `POST https://api2.onairos.uk/gmail/authorize`



2. **Token Management**: `POST https://api2.onairos.uk/youtube/refresh-token`

3. **Platform Disconnection**: `POST https://api2.onairos.uk/revoke`

4. **Health Check**: `GET https://api2.onairos.uk/health`

### Simulated APIs (Development/Testing)
1. **Email Verification**: 
   - Request: `POST https://api2.onairos.uk/email/verification`
   - Verify: `POST https://api2.onairos.uk/email/verification` (action: 'verify')
   - Status: `GET https://api2.onairos.uk/email/verification/status/{email}`
   - **Behavior**: All codes accepted in development mode

2. **AI Training**: 
   - **Behavior**: Socket.IO connection with fallback simulation

## Key Components for Swift Implementation

### 1. Modal Manager
```swift
class OnairosModal: UIViewController {
    var currentStep: OnboardingStep
    var slideAnimation: UIViewPropertyAnimator
    var bottomSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.8
}
```

### 2. Step Enum
```swift
enum OnboardingStep {
    case email
    case verify
    case connect
    case success
    case pin
    case training
}
```

### 3. Platform Configuration
```swift
struct Platform {
    let id: String
    let name: String
    let icon: UIImage
    let authMethod: AuthMethod
}

enum AuthMethod {
    case opacitySDK
    case nativeSDK
    case oauth
}
```

### 4. Network Layer
```swift
class OnairosAPIClient {
    static let baseURL = "https://api2.onairos.uk"
    
    func requestEmailVerification(email: String) async -> Result<Bool, Error>
    func verifyEmailCode(email: String, code: String) async -> Result<Bool, Error>
    func authenticatePlatform(platform: String, credentials: [String: Any]) async -> Result<AuthResult, Error>
}
```

### 5. Socket.IO Integration
```swift
import SocketIO

class TrainingManager {
    private var socket: SocketIOClient
    private let serverURL = "https://api2.onairos.uk"
    
    func startTraining(socketId: String, userData: [String: Any])
    func handleTrainingProgress(data: [String: Any])
}
```

## OAuth Deep Link Handling

### URL Scheme Configuration
```swift
// In Info.plist
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

### Deep Link Processing
```swift
func handleOAuthCallback(url: URL) -> (platform: String?, code: String?, success: Bool) {
    // Parse URL for platform and authorization code
    // Return structured result for platform connection
}
```

## Google Sign-In Configuration (YouTube)

### iOS Setup Requirements
```swift
// AppDelegate.swift
import GoogleSignIn

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
        fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
    }
    
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    return true
}

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
```

### YouTube Authentication Flow
```swift
func authenticateYouTube() async throws -> YouTubeCredentials {
    guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
        throw AuthError.noPresentingViewController
    }
    
    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
    
    // Extract tokens and send to backend
    let credentials = YouTubeCredentials(
        accessToken: result.user.accessToken.tokenString,
        refreshToken: result.user.refreshToken.tokenString,
        idToken: result.user.idToken?.tokenString
    )
    
    return credentials
}
```

## Opacity SDK Integration (Instagram)

### Configuration
```swift
import OpacitySDK

class InstagramAuthManager {
    private let apiKey = "OsamaTest-7bde2407-7360-462a-86b4-b26d7f890cbb"
    
    func initializeOpacity() async throws {
        try await OpacitySDK.initialize(
            apiKey: apiKey,
            environment: .production,
            shouldShowErrorsInWebView: true
        )
    }
    
    func getInstagramProfile() async throws -> InstagramProfile {
        let profile = try await OpacitySDK.get("flow:instagram:profile")
        return InstagramProfile(from: profile)
    }
}
```

## Error Handling Strategy

### Network Errors
```swift
enum OnairosError: Error {
    case networkUnavailable
    case invalidCredentials
    case platformUnavailable(String)
    case opacitySDKRequired
    case googleSignInFailed(String)
}
```

### User-Friendly Messages
```swift
extension OnairosError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .invalidCredentials:
            return "Invalid verification code. Please try again."
        case .platformUnavailable(let platform):
            return "\(platform) connection is currently unavailable."
        case .opacitySDKRequired:
            return "Instagram connection requires the Opacity SDK."
        case .googleSignInFailed(let reason):
            return "YouTube connection failed: \(reason)"
        }
    }
}
```

## State Management

### Onboarding State
```swift
class OnboardingState: ObservableObject {
    @Published var currentStep: OnboardingStep = .email
    @Published var email: String = ""
    @Published var verificationCode: String = ""
    @Published var connectedPlatforms: Set<String> = []
    @Published var pin: String = ""
    @Published var trainingProgress: Double = 0.0
    @Published var isLoading: Bool = false
}
```

## Testing Configuration

### Debug Mode Features
- Allow proceeding without platform connections
- All email verification codes accepted
- Simulated training progress
- Enhanced logging

### Environment Configuration
```swift
struct OnairosConfig {
    let isDebugMode: Bool
    let allowEmptyConnections: Bool
    let simulateTraining: Bool
    let apiBaseURL: String = "https://api2.onairos.uk"
}
```

## Completion Callback Structure

```swift
struct OnboardingResult {
    let apiURL: String
    let token: String
    let userData: [String: Any]
    let connectedPlatforms: [String: PlatformData]
    let sessionSaved: Bool
    let inferenceData: [String: Any]?
    let partner: String?
}

typealias OnboardingCompletion = (OnboardingResult) -> Void
```

## Key Implementation Notes

1. **Modal Height**: Always 80% of screen height
2. **Email Input**: Position higher to avoid keyboard blocking
3. **Platform Authentication**: Each platform has different auth method
4. **Error Handling**: Graceful degradation with user-friendly messages
5. **Testing Support**: Debug mode allows bypassing requirements
6. **Socket.IO**: Real-time training progress with fallback simulation
7. **Deep Links**: Handle OAuth callbacks for platform authentication
8. **Session Management**: Save authentication state for "Never Connect Again"

This design provides a complete foundation for implementing the Onairos onboarding flow in Swift while maintaining feature parity with the React Native version. 