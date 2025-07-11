# Onairos API Key Backend Integration Guide

## Overview

This guide explains how to integrate Onairos API keys with your backend system for authentication and authorization.

## API Key Types

### 1. Developer Keys
- **Format**: Must be at least 32 characters and start with `dev_` or `pk_`
- **Example**: `dev_1234567890abcdef1234567890abcdef`
- **Permissions**: Limited based on validation response from Onairos backend
- **Rate Limits**: Applied based on developer's plan

### 2. Admin Key
- **Value**: `OnairosIsAUnicorn2025`
- **Permissions**: Full access to all endpoints
- **Rate Limits**: 999,999 requests per day
- **Use Case**: Internal testing and administrative operations

## How API Keys Are Passed

All API requests from the Onairos React Native SDK include the following headers:

```http
Authorization: Bearer {apiKey}
Content-Type: application/json
User-Agent: OnairosReactNative/3.0.72
X-SDK-Version: 3.0.72
X-SDK-Environment: production|staging|development
X-API-Key-Type: developer|admin|invalid
X-Timestamp: 2024-01-01T00:00:00.000Z
```

## Backend Implementation

### 1. API Key Validation Endpoint

Your backend should implement the following endpoint for API key validation:

```http
POST /auth/validate-key
Authorization: Bearer {apiKey}
Content-Type: application/json
```

**Request Body:**
```json
{
  "environment": "production|staging|development",
  "sdk_version": "3.0.72",
  "platform": "react-native",
  "keyType": "developer|admin|invalid",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

**Response (Success):**
```json
{
  "success": true,
  "permissions": ["read:user", "write:data", "oauth:*"],
  "rateLimits": {
    "remaining": 4999,
    "resetTime": 1704067200000
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Invalid API key or insufficient permissions"
}
```

### 2. Request Validation Middleware

Here's how your backend should validate API keys on each request:

```javascript
// Example Express.js middleware
const validateApiKey = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const apiKey = authHeader?.replace('Bearer ', '');
    
    if (!apiKey) {
      return res.status(401).json({
        success: false,
        error: 'Missing API key'
      });
    }

    // Check if it's the admin key
    if (apiKey === 'OnairosIsAUnicorn2025') {
      req.user = {
        type: 'admin',
        permissions: ['*'],
        rateLimits: { remaining: 999999, resetTime: Date.now() + 24*60*60*1000 }
      };
      return next();
    }

    // Validate developer key
    const keyType = getApiKeyType(apiKey);
    if (keyType === 'invalid') {
      return res.status(401).json({
        success: false,
        error: 'Invalid API key format'
      });
    }

    // Check with your database/cache for developer keys
    const keyData = await validateDeveloperKey(apiKey);
    if (!keyData.isValid) {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired API key'
      });
    }

    // Check rate limits
    const rateLimitCheck = await checkRateLimit(apiKey);
    if (!rateLimitCheck.allowed) {
      return res.status(429).json({
        success: false,
        error: 'Rate limit exceeded',
        rateLimits: rateLimitCheck
      });
    }

    // Attach user info to request
    req.user = {
      type: 'developer',
      permissions: keyData.permissions,
      rateLimits: rateLimitCheck
    };

    next();
  } catch (error) {
    console.error('API key validation error:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

// Helper functions
const getApiKeyType = (apiKey) => {
  if (apiKey === 'OnairosIsAUnicorn2025') return 'admin';
  if (apiKey.length >= 32 && (apiKey.startsWith('dev_') || apiKey.startsWith('pk_'))) {
    return 'developer';
  }
  return 'invalid';
};

const validateDeveloperKey = async (apiKey) => {
  // Check your database for the API key
  // Return validation result with permissions
  return {
    isValid: true,
    permissions: ['read:user', 'write:data'],
    userId: 'developer-123'
  };
};

const checkRateLimit = async (apiKey) => {
  // Implement rate limiting logic
  // Return current rate limit status
  return {
    allowed: true,
    remaining: 4999,
    resetTime: Date.now() + 3600000 // 1 hour
  };
};
```

### 3. Permission-Based Access Control

Implement permission checks for specific operations:

```javascript
const requirePermission = (permission) => {
  return (req, res, next) => {
    const userPermissions = req.user?.permissions || [];
    
    // Admin has all permissions
    if (userPermissions.includes('*')) {
      return next();
    }
    
    // Check specific permission
    if (userPermissions.includes(permission)) {
      return next();
    }
    
    // Check wildcard permissions
    const wildcardPermission = permission.split(':')[0] + ':*';
    if (userPermissions.includes(wildcardPermission)) {
      return next();
    }
    
    return res.status(403).json({
      success: false,
      error: 'Insufficient permissions'
    });
  };
};

// Usage in routes
app.get('/api/user/:id', validateApiKey, requirePermission('read:user'), getUserHandler);
app.post('/api/data', validateApiKey, requirePermission('write:data'), createDataHandler);
```

## Common API Endpoints

### 1. OAuth Endpoints

```javascript
// YouTube OAuth
app.post('/youtube/native-auth', validateApiKey, requirePermission('oauth:youtube'), youtubeAuthHandler);

// Instagram OAuth
app.post('/instagram/auth', validateApiKey, requirePermission('oauth:instagram'), instagramAuthHandler);

// Generic OAuth
app.post('/oauth/:platform', validateApiKey, requirePermission('oauth:*'), oauthHandler);
```

### 2. Data Processing Endpoints

```javascript
// Get API URL for data processing
app.post('/getAPIurl', validateApiKey, requirePermission('read:data'), getApiUrlHandler);

// AI Inference
app.post('/inference', validateApiKey, requirePermission('ai:inference'), inferenceHandler);
```

## Error Handling

Your backend should return consistent error responses:

```javascript
// 401 Unauthorized
{
  "success": false,
  "error": "Invalid or missing API key"
}

// 403 Forbidden
{
  "success": false,
  "error": "Insufficient permissions for this operation"
}

// 429 Too Many Requests
{
  "success": false,
  "error": "Rate limit exceeded",
  "rateLimits": {
    "remaining": 0,
    "resetTime": 1704067200000
  }
}

// 500 Internal Server Error
{
  "success": false,
  "error": "Internal server error"
}
```

## Testing

Use the admin key for testing:

```javascript
// Test request with admin key
const testRequest = {
  headers: {
    'Authorization': 'Bearer OnairosIsAUnicorn2025',
    'Content-Type': 'application/json',
    'X-API-Key-Type': 'admin'
  }
};

// Should have full permissions and high rate limits
```

## Security Considerations

1. **Never log API keys** - Always redact them in logs
2. **Use HTTPS** - Never transmit API keys over HTTP
3. **Validate headers** - Check X-API-Key-Type header consistency
4. **Rate limiting** - Implement proper rate limiting for developer keys
5. **Key rotation** - Support key rotation for developer keys
6. **Audit logging** - Log API key usage for security monitoring

## Frontend Integration

The SDK automatically handles API key authentication:

```javascript
import { initializeApiKey } from '@onairos/react-native';

// Initialize with developer key
await initializeApiKey({
  apiKey: 'dev_your_32_char_key_here',
  environment: 'production',
  enableLogging: true
});

// Initialize with admin key (for testing)
await initializeApiKey({
  apiKey: 'OnairosIsAUnicorn2025',
  environment: 'development',
  enableLogging: true
});
```

## Rate Limiting Recommendations

### Developer Keys
- **Default**: 5,000 requests per hour
- **Premium**: 20,000 requests per hour
- **Enterprise**: 100,000 requests per hour

### Admin Key
- **Limit**: 999,999 requests per day
- **Use**: Internal testing and administrative operations only

## Monitoring and Analytics

Track API key usage:

```javascript
// Log API key usage
const logApiKeyUsage = (apiKey, endpoint, responseTime) => {
  const keyType = getApiKeyType(apiKey);
  const logData = {
    keyType,
    keyPrefix: apiKey.substring(0, 8),
    endpoint,
    responseTime,
    timestamp: new Date().toISOString()
  };
  
  // Send to your analytics service
  analytics.track('api_key_usage', logData);
};
```

This comprehensive integration ensures secure, scalable, and well-monitored API key authentication for your Onairos backend system. 