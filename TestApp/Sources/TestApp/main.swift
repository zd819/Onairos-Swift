import Foundation
import OnairosSDK

// Simple test to verify SDK can be imported and initialized
print("🚀 Testing Onairos Swift SDK...")

// Test configuration
let config = OnairosConfig(
    isDebugMode: true,
    urlScheme: "test-app",
    appName: "Test App"
)

print("✅ Configuration created successfully")
print("   - Debug mode: \(config.isDebugMode)")
print("   - URL scheme: \(config.urlScheme)")
print("   - App name: \(config.appName)")
print("   - API base URL: \(config.apiBaseURL)")

// Test models
let state = OnboardingState()
print("✅ Onboarding state initialized")
print("   - Current step: \(state.currentStep)")
print("   - Is loading: \(state.isLoading)")

// Test validation
state.email = "test@example.com"
state.currentStep = .email
let isValidEmail = state.validateCurrentStep()
print("✅ Email validation test: \(isValidEmail ? "PASSED" : "FAILED")")

// Test PIN requirements
let pinRequirements = PINRequirements()
let validationResults = pinRequirements.validate("password123!")
let allValid = validationResults.allSatisfy { $0.isValid }
print("✅ PIN validation test: \(allValid ? "PASSED" : "FAILED")")

// Test error handling
let error = OnairosError.networkUnavailable
print("✅ Error handling test: \(error.localizedDescription)")

print("\n🎉 All SDK components loaded successfully!")
print("📦 Your Onairos Swift SDK is ready for integration!") 