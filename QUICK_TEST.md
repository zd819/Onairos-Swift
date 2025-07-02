# 🚀 Quick Test Guide - Onairos Swift SDK

## ⚡ 30-Second Validation

### 1. Run Automated Tests
```bash
cd TestApp
swift run TestApp
```

**Expected:** All tests pass with 100% success rate

### 2. Test Integration Flow
```swift
import OnairosSDK

let config = OnairosConfig.testMode()
OnairosSDK.shared.initialize(config: config)

let button = OnairosSDK.shared.createConnectButton { result in
    switch result {
    case .success(let data):
        print("✅ Success: \(data.email ?? "N/A")")
    case .failure(let error):
        print("❌ Error: \(error.localizedDescription)")
    }
}
```

### 3. Manual Flow Test (Test Mode)
1. **Email Step**: Enter any email → Continue
2. **Verify Step**: Enter any 6-digit code → Continue  
3. **Connect Step**: Skip or connect platforms → Continue
4. **PIN Step**: Enter `password123!` → Continue
5. **Training Step**: Watch simulation complete → Done

**Expected:** Full flow completes without crashes

## 🔍 Issue Checklist

### ❌ **If Tests Fail:**
- Check Swift version compatibility
- Verify all dependencies are available
- Update to latest SDK version (v1.0.20+)

### ❌ **If App Crashes:**
- Ensure SDK is initialized before use
- Check for force unwraps in your integration
- Verify configuration is valid

### ❌ **If Flow Gets Stuck:**
- Use `OnairosConfig.testMode()` for development
- Check console logs for error messages
- Ensure UI thread is not blocked

## ✅ **Success Indicators:**
- All automated tests pass
- No crashes during onboarding flow
- Test mode accepts any input
- Training simulation completes
- Console shows "🧪 TEST MODE" messages

## 📞 **Need Help?**
- See `INTEGRATION_GUIDE.md` for detailed setup
- Check `Demo/OnairosSDKDemo/` for example code
- Review `CHANGELOG.md` for recent fixes 