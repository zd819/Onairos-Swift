# SDK JWT Integration Guide

## When You Get JWT Tokens from Backend

### 1. **Email Verification Flow** (Primary JWT Source)
**Endpoint:** `POST /email/verification`

```javascript
// Step 1: Request verification code
const requestResponse = await fetch('/email/verification', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_KEY}` // Developer API key
  },
  body: JSON.stringify({
    email: 'user@example.com',
    action: 'request'
  })
});

// Step 2: Verify code and GET JWT TOKEN
const verifyResponse = await fetch('/email/verification', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_KEY}` // Developer API key
  },
  body: JSON.stringify({
    email: 'user@example.com',
    action: 'verify',
    code: '123456'
  })
});

// SUCCESS RESPONSE CONTAINS JWT:
{
  "success": true,
  "message": "Email verification successful",
  "existingUser": false,
  "token": "eyJhbGciOiJIUzI1NiIs...",    // ✅ THIS IS YOUR JWT
  "jwtToken": "eyJhbGciOiJIUzI1NiIs..." // ✅ SAME JWT (both fields)
}
```

### 2. **JWT Token Format** (What you receive)
```javascript
// JWT Payload Structure
{
  id: "507f1f77bcf86cd799439011",  // MongoDB ObjectId
  email: "user@example.com",        // User email
  userId: "123",                    // User ID number
  verified: true,                   // Email verified status
  iat: 1640995200,                  // Issued at timestamp
  exp: 1641081600                   // Expires at timestamp (7 days)
}
```

## How to Store and Use JWT in SDKs

### 1. **Store JWT Securely**

#### React Native / Mobile Apps
```javascript
import AsyncStorage from '@react-native-async-storage/async-storage';

// Store JWT after email verification
const storeJWT = async (token) => {
  try {
    await AsyncStorage.setItem('onairos_jwt_token', token);
    console.log('JWT token stored successfully');
  } catch (error) {
    console.error('Failed to store JWT token:', error);
  }
};

// Retrieve JWT for requests
const getJWT = async () => {
  try {
    const token = await AsyncStorage.getItem('onairos_jwt_token');
    return token;
  } catch (error) {
    console.error('Failed to retrieve JWT token:', error);
    return null;
  }
};
```

#### Web Apps
```javascript
// Store JWT in localStorage
const storeJWT = (token) => {
  localStorage.setItem('onairos_jwt_token', token);
};

// Retrieve JWT for requests
const getJWT = () => {
  return localStorage.getItem('onairos_jwt_token');
};
```

#### iOS Swift
```swift
// Store JWT in Keychain
func storeJWT(_ token: String) {
    let data = token.data(using: .utf8)!
    let query = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "onairos_jwt_token",
        kSecValueData: data
    ] as CFDictionary
    
    SecItemDelete(query) // Remove existing
    SecItemAdd(query, nil) // Add new
}

// Retrieve JWT
func getJWT() -> String? {
    let query = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "onairos_jwt_token",
        kSecReturnData: true
    ] as CFDictionary
    
    var result: AnyObject?
    SecItemCopyMatching(query, &result)
    
    if let data = result as? Data {
        return String(data: data, encoding: .utf8)
    }
    return nil
}
```

### 2. **Use JWT in API Requests**

#### Standard Request Format
```javascript
const makeAuthenticatedRequest = async (endpoint, method = 'GET', body = null) => {
  const token = await getJWT(); // Get stored JWT
  
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`, // ✅ ALWAYS include "Bearer " prefix
    'User-Agent': 'OnairosSDK/1.0.0',
    'X-SDK-Version': '1.0.0'
  };
  
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null
  });
  
  return response.json();
};
```

#### Example: Store PIN (requires JWT)
```javascript
const storePIN = async (username, pin) => {
  return await makeAuthenticatedRequest('/store-pin/mobile', 'POST', {
    username,
    pin
  });
};
```

### 3. **SDK Class Structure**

```javascript
class OnairosSDK {
  constructor(config) {
    this.baseURL = config.baseURL;
    this.apiKey = config.apiKey;     // For developer authentication
    this.userToken = null;           // For user JWT token
  }
  
  // Email verification and JWT retrieval
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
      this.userToken = result.token; // Store JWT in SDK instance
      await this.storeJWT(result.token); // Store persistently
    }
    
    return result;
  }
  
  // Store JWT persistently
  async storeJWT(token) {
    // Platform-specific storage (AsyncStorage, localStorage, etc.)
    await AsyncStorage.setItem('onairos_jwt_token', token);
  }
  
  // Load JWT from storage
  async loadJWT() {
    const token = await AsyncStorage.getItem('onairos_jwt_token');
    this.userToken = token;
    return token;
  }
  
  // Make authenticated user requests
  async makeUserRequest(endpoint, method = 'GET', body = null) {
    if (!this.userToken) {
      await this.loadJWT(); // Try to load from storage
    }
    
    if (!this.userToken) {
      throw new Error('User not authenticated. Please verify email first.');
    }
    
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.userToken}`, // User JWT
      'User-Agent': 'OnairosSDK/1.0.0'
    };
    
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : null
    });
    
    return response.json();
  }
  
  // Example user operations
  async storePIN(username, pin) {
    return await this.makeUserRequest('/store-pin/mobile', 'POST', {
      username,
      pin
    });
  }
  
  async getUserProfile() {
    return await this.makeUserRequest('/user/profile', 'GET');
  }
}
```

## Usage Examples

### 1. **Complete Flow Example**
```javascript
// Initialize SDK
const sdk = new OnairosSDK({
  baseURL: 'https://api2.onairos.uk',
  apiKey: 'ona_your_developer_api_key'
});

// Email verification flow
try {
  // Step 1: Request verification code
  await sdk.requestEmailVerification('user@example.com');
  
  // Step 2: User enters code, verify and get JWT
  const result = await sdk.verifyEmail('user@example.com', '123456');
  
  if (result.success) {
    console.log('✅ Email verified, JWT stored');
    
    // Step 3: Now you can make authenticated requests
    const pinResult = await sdk.storePIN('username', '1234');
    console.log('PIN stored:', pinResult);
  }
} catch (error) {
  console.error('Authentication failed:', error);
}
```

### 2. **Handling JWT Expiration**
```javascript
async makeUserRequest(endpoint, method = 'GET', body = null) {
  try {
    const response = await this.makeAuthenticatedRequest(endpoint, method, body);
    return response;
  } catch (error) {
    if (error.status === 401) {
      // JWT expired or invalid
      this.userToken = null;
      await AsyncStorage.removeItem('onairos_jwt_token');
      throw new Error('Authentication expired. Please verify email again.');
    }
    throw error;
  }
}
```

## Two-Tier Authentication System

### For Developer Routes (API Key)
```javascript
// Developer authentication for app registration, analytics, etc.
const headers = {
  'Authorization': `Bearer ${API_KEY}`,
  'Content-Type': 'application/json'
};
```

### For User Routes (JWT Token)
```javascript
// User authentication for personal data, PIN storage, etc.
const headers = {
  'Authorization': `Bearer ${JWT_TOKEN}`,
  'Content-Type': 'application/json'
};
```

## Best Practices

1. **Always use `Bearer ` prefix** in Authorization header
2. **Store JWT securely** (AsyncStorage, Keychain, not plain localStorage for sensitive data)
3. **Handle token expiration** gracefully
4. **Validate token format** before storage
5. **Clear tokens on logout** or authentication errors
6. **Use HTTPS** for all API calls
7. **Don't log tokens** in production

## Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `jwt malformed` | Invalid token format | Check token structure and encoding |
| `Access token is required` | Missing Authorization header | Add `Authorization: Bearer <token>` |
| `Invalid token format` | Wrong token structure | Use JWT from email verification |
| `Token expired` | JWT expired (7 days) | Re-authenticate user |
| `Unauthorized` | Invalid JWT signature | Check `ONAIROS_JWT_SECRET_KEY` consistency |

## Testing

```javascript
// Test JWT token validity
const testToken = async (token) => {
  try {
    const response = await fetch('/auth/verify', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    const result = await response.json();
    console.log('Token valid:', result.valid);
  } catch (error) {
    console.error('Token test failed:', error);
  }
};
```

This guide ensures you properly handle JWT tokens in your SDKs for seamless user authentication after email verification. 