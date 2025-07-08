import Foundation
import OnairosSDK

// MARK: - Comprehensive Onairos SDK Test Suite
print("🚀 Starting Comprehensive Onairos Swift SDK Test Suite...")
print("=" * 60)

var testsPassed = 0
var testsFailed = 0

func runTest(_ testName: String, test: () throws -> Bool) {
    print("\n🧪 Testing: \(testName)")
    do {
        let result = try test()
        if result {
            print("✅ PASSED: \(testName)")
            testsPassed += 1
        } else {
            print("❌ FAILED: \(testName)")
            testsFailed += 1
        }
    } catch {
        print("❌ ERROR: \(testName) - \(error)")
        testsFailed += 1
    }
}

// MARK: - Configuration Tests
runTest("OnairosConfig Creation") {
    let config = OnairosConfig(
        apiKey: "test-api-key",
        environment: .development,
        enableLogging: true,
        isTestMode: false,
        isDebugMode: true,
        urlScheme: "test-app",
        appName: "Test App"
    )
    return config.isDebugMode == true && 
           config.urlScheme == "test-app" && 
           config.appName == "Test App"
}

runTest("OnairosConfig Test Mode") {
    let testConfig = OnairosConfig.testMode()
    return testConfig.isTestMode == true && 
           testConfig.allowEmptyConnections == true && 
           testConfig.simulateTraining == true
}

runTest("OnairosConfig Debug Mode") {
    let debugConfig = OnairosConfig.debugMode()
    return debugConfig.isDebugMode == true && 
           debugConfig.logLevel == .debug
}

// MARK: - Model Tests
runTest("OnboardingState Initialization") {
    let state = OnboardingState()
    return state.currentStep == .email && 
           state.email.isEmpty && 
           state.isLoading == false &&
           state.trainingProgress == 0.0
}

runTest("OnboardingState Email Validation") {
    let state = OnboardingState()
    state.email = "test@example.com"
    state.currentStep = .email
    return state.validateCurrentStep() == true
}

runTest("OnboardingState Invalid Email") {
    let state = OnboardingState()
    state.email = "invalid-email"
    state.currentStep = .email
    return state.validateCurrentStep() == false
}

runTest("OnboardingState PIN Validation") {
    let state = OnboardingState()
    state.pin = "password123!"
    state.currentStep = .pin
    return state.validateCurrentStep() == true
}

runTest("OnboardingState Training Progress NaN Protection") {
    let state = OnboardingState()
            state.setTrainingProgress(Double.nan)
    return !state.trainingProgress.isNaN && state.trainingProgress >= 0.0 && state.trainingProgress <= 1.0
}

// MARK: - PIN Requirements Tests
runTest("PIN Requirements Validation") {
    let requirements = PINRequirements()
    let validResults = requirements.validate("password123!")
    return validResults.allSatisfy { $0.isValid }
}

runTest("PIN Requirements - Too Short") {
    let requirements = PINRequirements()
    let results = requirements.validate("short")
    return !results.allSatisfy { $0.isValid }
}

runTest("PIN Requirements - No Numbers") {
    let requirements = PINRequirements()
    let results = requirements.validate("abcdefgh!")
    return !results.allSatisfy { $0.isValid }
}

runTest("PIN Requirements - No Special Characters") {
    let requirements = PINRequirements()
    let results = requirements.validate("password123")
    return !results.allSatisfy { $0.isValid }
}

// MARK: - TrainingProgress Tests
runTest("TrainingProgress NaN Protection") {
    let progress = TrainingProgress(percentage: Double.nan, status: "Test")
    return !progress.percentage.isNaN && progress.percentage >= 0.0 && progress.percentage <= 1.0
}

runTest("TrainingProgress Infinite Protection") {
    let progress = TrainingProgress(percentage: Double.infinity, status: "Test")
    return !progress.percentage.isInfinite && progress.percentage >= 0.0 && progress.percentage <= 1.0
}

runTest("TrainingProgress Valid Range") {
    let progress1 = TrainingProgress(percentage: -0.5, status: "Test")
    let progress2 = TrainingProgress(percentage: 1.5, status: "Test")
    return progress1.percentage == 0.0 && progress2.percentage == 1.0
}

// MARK: - Error Handling Tests
runTest("OnairosError Localization") {
    let errors: [OnairosError] = [
        .networkUnavailable,
        .invalidConfiguration("test"),
        .userCancelled,
        .authenticationFailed("test"),
        .trainingFailed("test")
    ]
    
    return errors.allSatisfy { !$0.localizedDescription.isEmpty }
}

runTest("OnairosError Categories") {
    let networkError = OnairosError.networkUnavailable
    let configError = OnairosError.invalidConfiguration("test")
    let userError = OnairosError.userCancelled
    
    return networkError.category == .network &&
           configError.category == .configuration &&
           userError.category == .user
}

// MARK: - SDK Initialization Tests
runTest("SDK Initialization") {
    let config = OnairosConfig.testMode()
    OnairosSDK.shared.initialize(config: config)
    return true // If no crash occurs, test passes
}

runTest("SDK Connect Button Creation") {
    let button = OnairosSDK.shared.createConnectButton { _ in }
    return button.titleLabel?.text?.contains("Connect") == true
}

runTest("SDK Custom Button Creation") {
    let button = OnairosSDK.shared.createConnectButton(text: "Custom Text") { _ in }
    return button.titleLabel?.text == "Custom Text"
}

// MARK: - API Client Tests
runTest("API Client Singleton") {
    let client1 = OnairosAPIClient.shared
    let client2 = OnairosAPIClient.shared
    return client1 === client2
}

// MARK: - Platform Tests
runTest("Platform Display Names") {
            let platforms: [Platform] = [.linkedin, .youtube, .reddit, .pinterest, .gmail]
    return platforms.allSatisfy { !$0.displayName.isEmpty }
}

runTest("Platform OAuth Scopes") {
    let reddit = Platform.reddit
    let pinterest = Platform.pinterest
    let gmail = Platform.gmail
    
    return !reddit.oauthScopes.isEmpty &&
           !pinterest.oauthScopes.isEmpty &&
           !gmail.oauthScopes.isEmpty
}

// MARK: - Device Info Tests
runTest("Device Info Creation") {
    let deviceInfo = DeviceInfo()
    return deviceInfo.platform == "iOS" &&
           !deviceInfo.version.isEmpty &&
           !deviceInfo.model.isEmpty &&
           !deviceInfo.appVersion.isEmpty
}

// MARK: - Memory Safety Tests
runTest("State Reset Functionality") {
    let state = OnboardingState()
    state.email = "test@example.com"
    state.pin = "password123!"
            state.setTrainingProgress(0.5)
            state.connectedPlatforms.insert("linkedin")
    
    state.reset()
    
    return state.email.isEmpty &&
           state.pin.isEmpty &&
           state.trainingProgress == 0.0 &&
           state.connectedPlatforms.isEmpty &&
           state.currentStep == .email
}

// MARK: - Test Results Summary
print("\n" + "=" * 60)
print("📊 TEST RESULTS SUMMARY")
print("=" * 60)
print("✅ Tests Passed: \(testsPassed)")
print("❌ Tests Failed: \(testsFailed)")
print("📈 Success Rate: \(Int((Double(testsPassed) / Double(testsPassed + testsFailed)) * 100))%")

if testsFailed == 0 {
    print("\n🎉 ALL TESTS PASSED! 🎉")
    print("✨ Your Onairos Swift SDK is fully functional and ready for integration!")
    print("\n🚀 Next Steps:")
    print("   1. Import OnairosSDK in your iOS project")
    print("   2. Configure with OnairosConfig.testMode() for testing")
    print("   3. Use OnairosSDK.shared.initialize(config: config)")
    print("   4. Create connect buttons with createConnectButton()")
    print("   5. Handle results in completion callbacks")
    
    print("\n💡 Test Mode Features:")
    print("   • Accepts any email address")
    print("   • Accepts any verification code")
    print("   • Shows full onboarding flow")
    print("   • No real API calls made")
    print("   • Comprehensive logging enabled")
} else {
    print("\n⚠️  SOME TESTS FAILED")
    print("Please review the failed tests above and fix any issues before integration.")
}

print("\n📚 For integration help, see:")
print("   • INTEGRATION_GUIDE.md")
print("   • Demo/OnairosSDKDemo/ for example usage")
print("   • DESIGN_OVERVIEW.md for architecture details")

extension String {
    static func *(left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
} 