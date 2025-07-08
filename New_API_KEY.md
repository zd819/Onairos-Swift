# OnairosSDK - Updated YouTube Authentication

## Overview

The OnairosSDK has been updated to use the native Google Sign-In SDK with enhanced configuration for YouTube authentication. This update provides better security, offline access support, and improved token management.

## What's New

### Enhanced Configuration

The YouTube authentication now uses pre-configured settings that match your React Native configuration:

```swift
// Automatically configured in YouTubeAuthManager
private struct Config {
    static let webClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
    static let iosClientId = "1030678346906-lovkuds2ouqmoc8eu5qpo98spa6edv4o.apps.googleusercontent.com"
    static let scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
    static let offlineAccess = true
    static let forceCodeForRefreshToken = true
}
```

### Migration from Old Configuration

#### Before (Old Way)
```swift
// Old initialization
YouTubeAuthManager.shared.initialize(clientID: "your-client-id")
```

#### After (New Way)
```swift
// New initialization - uses pre-configured settings
YouTubeAuthManager.shared.initialize()

// Or with custom client ID if needed
YouTubeAuthManager.shared.initialize(clientID: "custom-client-id")
```

## Key Features

### 1. Offline Access Support
```swift
let credentials = try await YouTubeAuthManager.shared.authenticate()
if credentials.hasOfflineAccess {
    print("Offline access available with server auth code")
}
```

### 2. Enhanced Token Management
```swift
// Check token status
if credentials.isExpired {
    let refreshed = try await YouTubeAuthManager.shared.refreshTokenIfNeeded()
}

if credentials.expiresSoon {
    // Proactively refresh token
    let refreshed = try await YouTubeAuthManager.shared.refreshTokenIfNeeded()
}
```

### 3. Session Restoration
```swift
// Restore previous session on app launch
let restored = await YouTubeAuthManager.shared.restorePreviousSignIn()
if restored {
    print("Previous YouTube session restored")
}
```

### 4. Enhanced User Information
```swift
let credentials = try await YouTubeAuthManager.shared.authenticate()
print("User ID: \(credentials.userInfo["user_id"] ?? "N/A")")
print("Email: \(credentials.userInfo["email"] ?? "N/A")")
print("Name: \(credentials.userInfo["name"] ?? "N/A")")
print("Picture: \(credentials.userInfo["picture"] ?? "N/A")")
```

## Implementation Guide

### Step 1: Initialize the Manager
```swift
import OnairosSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize YouTube authentication
        YouTubeAuthManager.shared.initialize()
        
        return true
    }
}
```

### Step 2: Handle URL Callbacks
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if YouTubeAuthManager.shared.handleURL(url) {
        return true
    }
    return false
}
```

### Step 3: Implement Authentication
```swift
class YourViewController: UIViewController {
    
    @IBAction func authenticateYouTube(_ sender: UIButton) {
        Task {
            do {
                let credentials = try await YouTubeAuthManager.shared.authenticate()
                
                // Success! Use the credentials
                await handleSuccessfulAuth(credentials)
                
            } catch {
                // Handle error
                await handleAuthError(error)
            }
        }
    }
    
    private func handleSuccessfulAuth(_ credentials: YouTubeCredentials) async {
        print("YouTube authentication successful!")
        print("Access Token: \(credentials.accessToken)")
        print("Has Offline Access: \(credentials.hasOfflineAccess)")
        
        // Make YouTube API calls
        await makeYouTubeAPICall(with: credentials)
    }
    
    private func handleAuthError(_ error: Error) async {
        if let youtubeError = error as? YouTubeAuthError {
            switch youtubeError {
            case .userCancelled:
                print("User cancelled authentication")
            case .networkError(let reason):
                print("Network error: \(reason)")
            case .tokenRefreshFailed(let reason):
                print("Token refresh failed: \(reason)")
            default:
                print("YouTube auth error: \(youtubeError.localizedDescription)")
            }
        } else {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }
}
```

### Step 4: Make YouTube API Calls
```swift
private func makeYouTubeAPICall(with credentials: YouTubeCredentials) async {
    // Ensure token is valid
    let validCredentials: YouTubeCredentials
    if credentials.isExpired || credentials.expiresSoon {
        do {
            validCredentials = try await YouTubeAuthManager.shared.refreshTokenIfNeeded()
        } catch {
            print("Failed to refresh token: \(error.localizedDescription)")
            return
        }
    } else {
        validCredentials = credentials
    }
    
    // Make API call
    let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(validCredentials.accessToken)", forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            // Process successful response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("YouTube API Response: \(jsonString)")
            }
        } else {
            print("YouTube API error: \(response)")
        }
    } catch {
        print("YouTube API call failed: \(error.localizedDescription)")
    }
}
```

## Error Handling

The updated YouTube authentication includes comprehensive error handling:

```swift
enum YouTubeAuthError: Error, LocalizedError {
    case googleSignInNotConfigured
    case noAccessToken
    case tokenRefreshFailed(String)
    case userCancelled
    case networkError(String)
    case offlineAccessNotAvailable
}
```

## Best Practices

1. **Initialize Early**: Initialize the YouTube authentication manager in your app delegate
2. **Handle URL Callbacks**: Ensure URL callbacks are properly handled for OAuth flow
3. **Token Management**: Always check token expiration before making API calls
4. **Error Handling**: Implement comprehensive error handling for all auth scenarios
5. **Session Restoration**: Use session restoration to improve user experience

## Troubleshooting

### Common Issues

1. **"Google Sign-In not configured"**
   - Ensure GoogleService-Info.plist is added to your project
   - Verify the client IDs match your Google Cloud Console configuration

2. **"No access token received"**
   - Check network connectivity
   - Verify the OAuth scopes are correctly configured

3. **"Token refresh failed"**
   - The user may need to re-authenticate
   - Check if the refresh token is still valid

### Debug Information

Enable debug logging to troubleshoot issues:

```swift
// Add this to see detailed authentication flow
print("Is signed in: \(YouTubeAuthManager.shared.isSignedIn())")
print("Is available: \(YouTubeAuthManager.shared.isAvailable())")

if let currentUser = YouTubeAuthManager.shared.getCurrentUser() {
    print("Current user: \(currentUser.userInfo)")
    print("Token expires at: \(currentUser.expiresAt ?? Date())")
    print("Has offline access: \(currentUser.hasOfflineAccess)")
}
```

## Support

For additional support or questions about the YouTube authentication implementation, please refer to the main documentation or contact support.