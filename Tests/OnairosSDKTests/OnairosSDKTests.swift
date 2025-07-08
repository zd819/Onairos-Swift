import XCTest
@testable import OnairosSDK

final class OnairosSDKTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Configuration Tests
    
    func testSDKInitialization() throws {
        let config = OnairosConfig(
            apiKey: "test-api-key",
            environment: .production,
            enableLogging: false,
            timeout: 30.0,
            isTestMode: false,
            isDebugMode: true,
            allowEmptyConnections: false,
            simulateTraining: false,
            platforms: [.linkedin, .youtube, .reddit, .pinterest, .gmail],
            linkedInClientID: nil,
            googleClientID: nil,
            urlScheme: "test-scheme",
            appName: "Test App"
        )
        
        XCTAssertTrue(config.isDebugMode)
        XCTAssertEqual(config.urlScheme, "test-scheme")
        XCTAssertEqual(config.appName, "Test App")
        XCTAssertEqual(config.apiBaseURL, "https://api2.onairos.uk")
    }
    
    // MARK: - Model Tests
    
    func testOnboardingStateInitialization() throws {
        let state = OnboardingState()
        
        XCTAssertEqual(state.currentStep, .email)
        XCTAssertTrue(state.email.isEmpty)
        XCTAssertTrue(state.verificationCode.isEmpty)
        XCTAssertTrue(state.pin.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.trainingProgress, 0.0)
    }
    
    func testEmailValidation() throws {
        let state = OnboardingState()
        
        // Test invalid emails
        state.email = ""
        state.currentStep = .email
        XCTAssertFalse(state.validateCurrentStep())
        
        state.email = "invalid-email"
        XCTAssertFalse(state.validateCurrentStep())
        
        state.email = "test@"
        XCTAssertFalse(state.validateCurrentStep())
        
        // Test valid email
        state.email = "test@example.com"
        XCTAssertTrue(state.validateCurrentStep())
    }
    
    func testVerificationCodeValidation() throws {
        let state = OnboardingState()
        state.currentStep = .verify
        
        // Test invalid codes
        state.verificationCode = ""
        XCTAssertFalse(state.validateCurrentStep())
        
        state.verificationCode = "123"
        XCTAssertFalse(state.validateCurrentStep())
        
        state.verificationCode = "1234567"
        XCTAssertFalse(state.validateCurrentStep())
        
        // Test valid code
        state.verificationCode = "123456"
        XCTAssertTrue(state.validateCurrentStep())
    }
    
    func testPINValidation() throws {
        let state = OnboardingState()
        state.currentStep = .pin
        
        // Test invalid PINs
        state.pin = ""
        XCTAssertFalse(state.validateCurrentStep())
        
        state.pin = "123" // Too short
        XCTAssertFalse(state.validateCurrentStep())
        
        state.pin = "abcdefgh" // No numbers or special chars
        XCTAssertFalse(state.validateCurrentStep())
        
        state.pin = "12345678" // No special chars
        XCTAssertFalse(state.validateCurrentStep())
        
        // Test valid PIN
        state.pin = "password123!"
        XCTAssertTrue(state.validateCurrentStep())
    }
    
    // MARK: - PIN Requirements Tests
    
    func testPINRequirements() throws {
        let requirements = PINRequirements()
        
        // Test empty PIN
        let emptyResults = requirements.validate("")
        XCTAssertEqual(emptyResults.count, 3)
        XCTAssertFalse(emptyResults.allSatisfy { $0.isValid })
        
        // Test short PIN
        let shortResults = requirements.validate("123")
        XCTAssertFalse(shortResults[0].isValid) // Length requirement
        
        // Test PIN without numbers
        let noNumbersResults = requirements.validate("abcdefgh!")
        XCTAssertTrue(noNumbersResults[0].isValid) // Length OK
        XCTAssertFalse(noNumbersResults[1].isValid) // No numbers
        XCTAssertTrue(noNumbersResults[2].isValid) // Has special chars
        
        // Test valid PIN
        let validResults = requirements.validate("password123!")
        XCTAssertTrue(validResults.allSatisfy { $0.isValid })
    }
    
    // MARK: - Error Tests
    
    func testOnairosErrorLocalizedDescription() throws {
        let networkError = OnairosError.networkUnavailable
        XCTAssertFalse(networkError.localizedDescription.isEmpty)
        
        let platformError = OnairosError.platformUnavailable("LinkedIn")
        XCTAssertTrue(platformError.localizedDescription.contains("LinkedIn"))
        
        let validationError = OnairosError.validationFailed("Invalid email")
        XCTAssertTrue(validationError.localizedDescription.contains("Invalid email"))
    }
    
    func testErrorRecoverySuggestions() throws {
        let networkError = OnairosError.networkUnavailable
        XCTAssertFalse(networkError.recoverySuggestion.isEmpty)
        
        let serverError = OnairosError.serverError(500, "Internal Server Error")
        XCTAssertFalse(serverError.recoverySuggestion.isEmpty)
    }
    
    // MARK: - Platform Tests
    
    func testPlatformDisplayNames() throws {
        XCTAssertEqual(Platform.linkedin.displayName, "LinkedIn")
        XCTAssertEqual(Platform.youtube.displayName, "YouTube")
        XCTAssertEqual(Platform.reddit.displayName, "Reddit")
        XCTAssertEqual(Platform.pinterest.displayName, "Pinterest")
        XCTAssertEqual(Platform.gmail.displayName, "Gmail")
    }
    
    // MARK: - Performance Tests
    
    func testEmailValidationPerformance() throws {
        let state = OnboardingState()
        state.currentStep = .email
        state.email = "test@example.com"
        
        measure {
            for _ in 0..<1000 {
                _ = state.validateCurrentStep()
            }
        }
    }
    
    func testPINValidationPerformance() throws {
        let requirements = PINRequirements()
        let pin = "password123!"
        
        measure {
            for _ in 0..<1000 {
                _ = requirements.validate(pin)
            }
        }
    }
    
    // MARK: - Email Verification Tests
    
    func testEmailVerificationRequest() throws {
        let request = EmailVerificationRequest(email: "test@example.com")
        
        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertNil(request.code)
    }
    
    func testEmailVerificationRequestWithCode() throws {
        let request = EmailVerificationRequest(email: "test@example.com", code: "123456")
        
        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertEqual(request.code, "123456")
    }
    
    func testEmailVerificationResponse() throws {
        // Test basic response
        let response = EmailVerificationResponse(
            success: true,
            message: "Code sent",
            verified: nil,
            testingMode: true,
            accountInfo: nil,
            note: "Testing mode enabled"
        )
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Code sent")
        XCTAssertNil(response.verified)
        XCTAssertEqual(response.testingMode, true)
        XCTAssertNil(response.accountInfo)
        XCTAssertEqual(response.note, "Testing mode enabled")
    }
    
    func testEmailVerificationResponseWithAccountInfo() throws {
        let accountInfo = [
            "userId": AnyCodable("12345"),
            "name": AnyCodable("John Doe"),
            "verified": AnyCodable(true)
        ]
        
        let response = EmailVerificationResponse(
            success: true,
            message: "Existing account found",
            verified: true,
            testingMode: false,
            accountInfo: accountInfo,
            note: nil
        )
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Existing account found")
        XCTAssertEqual(response.verified, true)
        XCTAssertEqual(response.testingMode, false)
        XCTAssertNotNil(response.accountInfo)
        XCTAssertEqual(response.accountInfo?["userId"]?.value as? String, "12345")
        XCTAssertEqual(response.accountInfo?["name"]?.value as? String, "John Doe")
        XCTAssertEqual(response.accountInfo?["verified"]?.value as? Bool, true)
        XCTAssertNil(response.note)
    }
    
    func testEmailVerificationStatusResponse() throws {
        let statusResponse = EmailVerificationStatusResponse(
            success: true,
            hasCode: true,
            expiresAt: "2024-01-01T12:00:00Z"
        )
        
        XCTAssertTrue(statusResponse.success)
        XCTAssertEqual(statusResponse.hasCode, true)
        XCTAssertEqual(statusResponse.expiresAt, "2024-01-01T12:00:00Z")
    }
    
    func testOnboardingStateAccountInfo() throws {
        let state = OnboardingState()
        
        // Test initial state
        XCTAssertNil(state.accountInfo)
        
        // Test setting account info
        let accountInfo = [
            "userId": AnyCodable("12345"),
            "name": AnyCodable("John Doe")
        ]
        state.accountInfo = accountInfo
        
        XCTAssertNotNil(state.accountInfo)
        XCTAssertEqual(state.accountInfo?["userId"]?.value as? String, "12345")
        XCTAssertEqual(state.accountInfo?["name"]?.value as? String, "John Doe")
        
        // Test reset clears account info
        state.reset()
        XCTAssertNil(state.accountInfo)
    }
    
    // MARK: - Flow Tests
    
    func testOnboardingFlowProgression() throws {
        let config = OnairosConfig.testMode(urlScheme: "test", appName: "Test")
        let state = OnboardingState()
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        // Test Connect -> PIN transition (skip success step)
        state.currentStep = .connect
        coordinator.proceedToNextStep()
        XCTAssertEqual(state.currentStep, .pin, "Connect step should proceed directly to PIN step")
        
        // Test PIN -> Training transition
        state.currentStep = .pin
        state.pin = "testpin123!"
        coordinator.proceedToNextStep()
        
        // In test mode, this should transition to training
        let expectation = self.expectation(description: "PIN step should proceed to Training step")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(state.currentStep, .training, "PIN step should proceed to Training step")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testConnectStepSkipForNow() throws {
        let config = OnairosConfig.testMode(urlScheme: "test", appName: "Test")
        let state = OnboardingState()
        let coordinator = OnboardingCoordinator(
            state: state,
            config: config,
            apiClient: OnairosAPIClient.shared
        )
        
        // Test that Connect step allows proceeding without connections in test mode
        state.currentStep = .connect
        // Don't connect any platforms
        XCTAssertTrue(state.connectedPlatforms.isEmpty, "Should have no connected platforms")
        
        // Should still be able to proceed in test mode
        coordinator.proceedToNextStep()
        XCTAssertEqual(state.currentStep, .pin, "Connect step should proceed directly to PIN even without connections in test mode")
    }
} 