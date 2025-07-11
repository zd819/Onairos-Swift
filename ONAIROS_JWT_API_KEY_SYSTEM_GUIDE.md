# Onairos JWT API Key System - Complete Guide

## Overview

The Onairos platform uses a **dual authentication system** that combines **Developer API Keys** and **User JWT Tokens** for secure, scalable access control.

## 🔑 Authentication Types

### 1. Developer API Keys
**Purpose**: SDK authentication, rate limiting, developer identification  
**Format**: `ona_` + 32+ character string  
**Usage**: Required for all SDK operations  
**Example**: `ona_1234567890abcdef1234567890abcdef`

### 2. User JWT Tokens
**Purpose**: User authentication, personal data access  
**Format**: Standard JWT with 7-day expiration  
**Usage**: Required for user-specific operations  
**Example**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Admin API Key (Testing Only)
**Purpose**: Testing, debugging, admin operations  
**Format**: `OnairosIsAUnicorn2025`  
**Usage**: Bypasses most restrictions  
**⚠️ Never use in production**

---

## 📱 SDK Initialization

### React Native / Mobile
```javascript
import { OnairosSDK } from '@onairos/react-native';

const sdk = new OnairosSDK({
  baseURL: 'https://api2.onairos.uk',
  apiKey: 'ona_your_developer_api_key', // Required: Developer API key
  environment: 'production' // or 'staging', 'development'
});

// Initialize with stored user token (if available)
await sdk.initializeWithStoredToken();
```

### Web / JavaScript
```javascript
import { OnairosSDK } from '@onairos/web-sdk';

const sdk = new OnairosSDK({
  baseURL: 'https://api2.onairos.uk',
  apiKey: 'ona_your_developer_api_key',
  environment: 'production'
});
```

### iOS Swift
```swift
import OnairosSDK

let config = OnairosConfig(
    baseURL: "https://api2.onairos.uk",
    apiKey: "ona_your_developer_api_key",
    environment: .production
)

let sdk = OnairosSDK(config: config)
```

---

## 🔐 Authentication Flow

### Step 1: Email Verification (Gets JWT)
```javascript
// 1. Request verification code
const requestResponse = await sdk.requestEmailVerification('user@example.com');

// 2. Verify code and receive JWT token
const verifyResponse = await sdk.verifyEmail('user@example.com', '123456');

// SUCCESS: JWT token is automatically stored
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",  // ✅ JWT Token
  "jwtToken": "eyJhbGciOiJIUzI1NiIs...", // ✅ Same JWT Token
  "userName": "user123"
}
```

### Step 2: Using Both Tokens
```javascript
// For SDK operations: API key is automatically included
await sdk.connectYoutube(); // Uses: Bearer ona_your_api_key

// For user operations: JWT token is automatically included
await sdk.storePIN('username', '1234'); // Uses: Bearer eyJhbGciOiJIUzI1NiIs...
```

---

## 📋 Expected Formats

### Developer API Key Format
```
Prefix: ona_, dev_, or pk_
Length: Minimum 32 characters
Example: ona_1234567890abcdef1234567890abcdef
```

### JWT Token Format
```javascript
// Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// Payload
{
  "id": "507f1f77bcf86cd799439011",  // MongoDB ObjectId
  "email": "user@example.com",       // User email
  "userId": "123",                   // User ID number
  "userName": "user123",             // Username
  "verified": true,                  // Email verified status
  "iat": 1640995200,                 // Issued at timestamp
  "exp": 1641081600                  // Expires at (7 days)
}
```

### Request Headers
```javascript
// For developer operations (OAuth, etc.)
{
  "Authorization": "Bearer ona_your_api_key",
  "Content-Type": "application/json",
  "X-SDK-Version": "1.0.0",
  "X-SDK-Environment": "production"
}

// For user operations (PIN storage, etc.)
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIs...",
  "Content-Type": "application/json",
  "X-SDK-Version": "1.0.0"
}
```

---

## 🛠 SDK Implementation

### Complete SDK Class Structure
```javascript
class OnairosSDK {
  constructor(config) {
    this.baseURL = config.baseURL;
    this.apiKey = config.apiKey;     // Developer API key
    this.userToken = null;           // User JWT token
    this.environment = config.environment;
  }
  
  // Email verification flow
  async requestEmailVerification(email) {
    return await fetch(`${this.baseURL}/email/verification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}` // Developer API key
      },
      body: JSON.stringify({
        email,
        action: 'request'
      })
    });
  }
  
  async verifyEmail(email, code) {
    const response = await fetch(`${this.baseURL}/email/verification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}` // Developer API key
      },
      body: JSON.stringify({
        email,
        action: 'verify',
        code
      })
    });
    
    const result = await response.json();
    
    if (result.success && result.token) {
      this.userToken = result.token; // Store JWT token
      await this.storeUserToken(result.token); // Persist locally
    }
    
    return result;
  }
  
  // Developer operations (use API key)
  async connectYoutube() {
    return await this.makeDeveloperRequest('/youtube/native-auth', 'POST');
  }
  
  // User operations (use JWT token)
  async storePIN(username, pin) {
    return await this.makeUserRequest('/store-pin/mobile', 'POST', {
      username,
      pin
    });
  }
  
  // Helper methods
  async makeDeveloperRequest(endpoint, method = 'GET', body = null) {
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.apiKey}`, // Developer API key
      'X-SDK-Version': '1.0.0',
      'X-SDK-Environment': this.environment
    };
    
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : null
    });
    
    return response.json();
  }
  
  async makeUserRequest(endpoint, method = 'GET', body = null) {
    if (!this.userToken) {
      await this.loadUserToken(); // Try to load from storage
    }
    
    if (!this.userToken) {
      throw new Error('User not authenticated. Please verify email first.');
    }
    
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.userToken}`, // User JWT token
      'X-SDK-Version': '1.0.0'
    };
    
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : null
    });
    
    return response.json();
  }
  
  // Token storage (platform-specific)
  async storeUserToken(token) {
    // React Native
    if (typeof require !== 'undefined' && require('@react-native-async-storage/async-storage')) {
      const AsyncStorage = require('@react-native-async-storage/async-storage');
      await AsyncStorage.setItem('onairos_jwt_token', token);
    }
    // Web
    else if (typeof localStorage !== 'undefined') {
      localStorage.setItem('onairos_jwt_token', token);
    }
  }
  
  async loadUserToken() {
    // React Native
    if (typeof require !== 'undefined' && require('@react-native-async-storage/async-storage')) {
      const AsyncStorage = require('@react-native-async-storage/async-storage');
      this.userToken = await AsyncStorage.getItem('onairos_jwt_token');
    }
    // Web
    else if (typeof localStorage !== 'undefined') {
      this.userToken = localStorage.getItem('onairos_jwt_token');
    }
  }
}
```

---

## 🎯 Operation Types

### Developer Operations (API Key Required)
- OAuth connections (YouTube, LinkedIn, etc.)
- Rate limiting and analytics
- App registration and management
- Development tools and debugging

### User Operations (JWT Token Required)
- PIN storage and management
- Personal data access
- Profile updates
- AI model training and inference

### Mixed Operations (Both Tokens)
- Some routes accept both for different contexts
- Fallback authentication patterns
- Admin operations with user context

---

## 🔧 Environment Configuration

### Production
```javascript
{
  baseURL: 'https://api2.onairos.uk',
  apiKey: 'ona_your_production_api_key',
  environment: 'production'
}
```

### Staging
```javascript
{
  baseURL: 'https://staging.onairos.uk',
  apiKey: 'ona_your_staging_api_key',
  environment: 'staging'
}
```

### Development
```javascript
{
  baseURL: 'http://localhost:8080',
  apiKey: 'OnairosIsAUnicorn2025', // Admin key for testing
  environment: 'development'
}
```

---

## ⚠️ Error Handling

### Common Error Responses
```javascript
// Missing API key
{
  "success": false,
  "error": "API key required",
  "code": "MISSING_API_KEY"
}

// Invalid API key
{
  "success": false,
  "error": "Invalid API key",
  "code": "INVALID_API_KEY"
}

// JWT token expired
{
  "success": false,
  "error": "Token expired",
  "code": "TOKEN_EXPIRED"
}

// Insufficient permissions
{
  "success": false,
  "error": "Insufficient permissions",
  "code": "INSUFFICIENT_PERMISSIONS"
}
```

### Error Handling in SDK
```javascript
class OnairosSDK {
  async makeRequest(endpoint, method, body, useUserToken = false) {
    try {
      const response = await this.makeAuthenticatedRequest(endpoint, method, body, useUserToken);
      return response;
    } catch (error) {
      if (error.code === 'TOKEN_EXPIRED') {
        // Clear expired token
        this.userToken = null;
        await this.clearStoredToken();
        throw new Error('Authentication expired. Please verify email again.');
      }
      throw error;
    }
  }
}
```

---

## 📊 Rate Limits

### Developer API Keys
- **Free Tier**: 5,000 requests/hour
- **Pro Tier**: 50,000 requests/hour
- **Enterprise**: Custom limits

### User JWT Tokens
- **Standard**: 1,000 requests/hour per user
- **No throttling**: On personal data operations

### Admin API Key
- **Testing**: 999,999 requests/day
- **No production limits**

---

## 🔒 Security Best Practices

### For Developers
1. **Never expose API keys** in client-side code
2. **Use environment variables** for API key storage
3. **Rotate API keys** regularly
4. **Monitor usage** via developer dashboard
5. **Use HTTPS** for all API calls

### For Users
1. **Store JWT tokens securely** (Keychain, AsyncStorage)
2. **Handle token expiration** gracefully
3. **Clear tokens on logout**
4. **Validate token format** before storage
5. **Never log tokens** in production

---

## 📋 Quick Reference

### Email Verification (Get JWT)
```bash
# Step 1: Request code
curl -X POST https://api2.onairos.uk/email/verification \
  -H "Authorization: Bearer ona_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "action": "request"}'

# Step 2: Verify code
curl -X POST https://api2.onairos.uk/email/verification \
  -H "Authorization: Bearer ona_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "action": "verify", "code": "123456"}'
```

### Developer Operations
```bash
# YouTube OAuth
curl -X POST https://api2.onairos.uk/youtube/native-auth \
  -H "Authorization: Bearer ona_your_api_key" \
  -H "Content-Type: application/json"
```

### User Operations
```bash
# Store PIN
curl -X POST https://api2.onairos.uk/store-pin/mobile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{"username": "user123", "pin": "1234"}'
```

---

## 🎯 Getting Started Checklist

### For SDK Developers
1. ✅ **Get Developer API Key** from Onairos developer portal
2. ✅ **Initialize SDK** with base URL and API key
3. ✅ **Implement email verification** flow for user authentication
4. ✅ **Store JWT tokens** securely on the device
5. ✅ **Handle token expiration** and re-authentication
6. ✅ **Test with admin key** in development environment
7. ✅ **Switch to production key** for release

### For Backend Developers
1. ✅ **Import authentication middleware** (`unifiedApiKeyAuth.js`)
2. ✅ **Apply middleware** to SDK routes
3. ✅ **Set up permissions** for different operations
4. ✅ **Handle error responses** appropriately
5. ✅ **Test with both API keys and JWT tokens**
6. ✅ **Monitor rate limits** and usage

---

## 📞 Support

### Developer Portal
- **Dashboard**: `https://api2.onairos.uk/developer/dashboard`
- **API Keys**: `https://api2.onairos.uk/developer/keys`
- **Documentation**: `https://docs.onairos.uk`

### Support Channels
- **Email**: `developers@onairos.com`
- **Discord**: `https://discord.gg/onairos`
- **GitHub**: `https://github.com/onairos/sdk-issues`

---

**This guide covers the complete Onairos JWT API key system. For specific implementation details, refer to the individual SDK documentation for your platform.** 