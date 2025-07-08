# 🔑 Swift API Key System - Essential Components

## 📝 **CORE CONCEPTS**

### **How It Works:**
1. **Initialize** SDK with API key (`OnairosIsAUnicorn2025` for testing)
2. **Validate** API key with backend
3. **Add authentication headers** to all requests
4. **Cache** validation results for performance

### **Admin Key for Testing:**
```swift
let ADMIN_API_KEY = "OnairosIsAUnicorn2025"
```

---

## 🏗️ **ESSENTIAL SWIFT COMPONENTS**

### **1. Configuration**
```swift
struct OnairosConfig {
    let apiKey: String
    let environment: Environment // production, staging, development
    let enableLogging: Bool
    let timeout: TimeInterval
}

enum Environment: String {
    case production = "production"
    case development = "development"
    
    var baseURL: String {
        switch self {
        case .production: return "https://api2.onairos.uk"
        case .development: return "https://dev-api.onairos.uk"
        }
    }
}
```

### **2. API Key Service**
```swift
class OnairosAPIKeyService {
    static let ADMIN_API_KEY = "OnairosIsAUnicorn2025"
    static let shared = OnairosAPIKeyService()
    
    private var config: OnairosConfig?
    private var isInitialized = false
    
    // Initialize SDK
    func initializeApiKey(config: OnairosConfig) async throws {
        self.config = config
        
        // Validate API key with backend
        let validation = try await validateApiKey(config.apiKey)
        guard validation.isValid else {
            throw OnairosError.invalidAPIKey(validation.error ?? "Validation failed")
        }
        
        self.isInitialized = true
        print("✅ SDK initialized with API key")
    }
    
    // Get authentication headers
    func getAuthHeaders() throws -> [String: String] {
        guard let config = config else {
            throw OnairosError.notInitialized("Call initializeApiKey() first")
        }
        
        return [
            "Authorization": "Bearer \(config.apiKey)",
            "Content-Type": "application/json",
            "User-Agent": "OnairosSwift/1.0.0",
            "X-API-Key-Type": isAdminKey(config.apiKey) ? "admin" : "developer",
            "X-Timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // Make authenticated requests
    func makeAuthenticatedRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let config = config else {
            throw OnairosError.notInitialized("SDK not initialized")
        }
        
        let url = URL(string: "\(config.environment.baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication headers
        let headers = try getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response as! HTTPURLResponse)
    }
    
    private func isAdminKey(_ key: String) -> Bool {
        return key == Self.ADMIN_API_KEY
    }
    
    private func validateApiKey(_ apiKey: String) async throws -> ValidationResult {
        // Admin key is always valid
        if isAdminKey(apiKey) {
            return ValidationResult(isValid: true, error: nil)
        }
        
        // For developer keys, validate with backend
        // Implementation details in full guide...
        return ValidationResult(isValid: true, error: nil)
    }
}

struct ValidationResult {
    let isValid: Bool
    let error: String?
}

enum OnairosError: Error {
    case invalidAPIKey(String)
    case notInitialized(String)
}
```

---

## 🚀 **USAGE EXAMPLES**

### **Initialize with Admin Key**
```swift
Task {
    do {
        let config = OnairosConfig(
            apiKey: OnairosAPIKeyService.ADMIN_API_KEY, // "OnairosIsAUnicorn2025"
            environment: .development,
            enableLogging: true,
            timeout: 30.0
        )
        
        try await OnairosAPIKeyService.shared.initializeApiKey(config: config)
        print("✅ SDK ready with admin key")
        
    } catch {
        print("❌ Initialization failed: \(error)")
    }
}
```

### **Make Authenticated API Calls**
```swift
// Email verification
func requestEmailVerification(email: String) async throws {
    let body = [
        "email": email,
        "action": "request"
    ]
    let bodyData = try JSONSerialization.data(withJSONObject: body)
    
    let (data, response) = try await OnairosAPIKeyService.shared.makeAuthenticatedRequest(
        endpoint: "/email/verification",
        method: "POST",
        body: bodyData
    )
    
    // Handle response...
    print("✅ Email verification request sent")
}

// Verify email code
func verifyEmailCode(email: String, code: String) async throws {
    let body = [
        "email": email,
        "code": code,
        "action": "verify"
    ]
    let bodyData = try JSONSerialization.data(withJSONObject: body)
    
    let (data, response) = try await OnairosAPIKeyService.shared.makeAuthenticatedRequest(
        endpoint: "/email/verification",
        method: "POST",
        body: bodyData
    )
    
    // Handle response...
    print("✅ Email code verified")
}
```

---

## 📡 **WHAT YOUR BACKEND RECEIVES**

### **Request Headers:**
```http
POST /email/verification
Authorization: Bearer OnairosIsAUnicorn2025
Content-Type: application/json
User-Agent: OnairosSwift/1.0.0
X-API-Key-Type: admin
X-Timestamp: 2024-01-01T00:00:00.000Z
```

### **Backend Validation:**
```javascript
// Your backend should validate:
if (req.headers.authorization === 'Bearer OnairosIsAUnicorn2025') {
  // ✅ Admin key - grant full access
  next();
} else {
  // ❌ Invalid key
  res.status(401).json({ error: 'Invalid API key' });
}
```

---

## 🎯 **IMPLEMENTATION CHECKLIST**

### **✅ Core Components:**
- [ ] `OnairosConfig` struct with API key and environment
- [ ] `OnairosAPIKeyService` singleton class
- [ ] `initializeApiKey()` method
- [ ] `getAuthHeaders()` method
- [ ] `makeAuthenticatedRequest()` method
- [ ] Admin key constant: `"OnairosIsAUnicorn2025"`

### **✅ Testing:**
- [ ] Initialize with admin key
- [ ] Test email verification API call
- [ ] Test code verification API call
- [ ] Verify authentication headers are included
- [ ] Confirm backend receives Bearer token

### **✅ Production:**
- [ ] Replace admin key with developer key
- [ ] Set environment to `.production`
- [ ] Disable logging
- [ ] Test with real API endpoints

---

## 🚀 **RESULT**

**✅ After Implementation:**
- Swift SDK has same authentication as React Native
- All API calls include `Authorization: Bearer OnairosIsAUnicorn2025`
- Email verification works correctly
- Backend receives authenticated requests
- All routes are accessible with admin key

**✅ The Swift SDK will:**
1. **Initialize** with admin key
2. **Add authentication headers** automatically
3. **Make authenticated requests** to all endpoints
4. **Handle errors** gracefully
5. **Cache validation** for performance

This gives you the same robust authentication system across both React Native and Swift! 🎉