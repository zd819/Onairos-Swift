import UIKit
import Foundation

/// Timeout error for async operations
struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

/// Coordinates the onboarding flow through all steps
@MainActor
public class OnboardingCoordinator {
    
    /// Configuration for the onboarding flow
    private let config: OnairosConfig
    
    /// Current onboarding state
    private let state: OnboardingState
    
    /// Modal presentation controller
    private var modalController: OnairosModalController?
    
    /// Completion handler
    private var completion: OnboardingCompletion?
    
    /// Completion callback for external access
    public var onCompletion: ((OnboardingResult) -> Void)?
    
    /// Connected platform data
    private var connectedPlatformData: [String: PlatformData] = [:]
    
    /// API client
    private let apiClient: OnairosAPIClient
    
    /// Training manager
    private var trainingManager: TrainingManager?
    
    /// Initialize coordinator
    /// - Parameters:
    ///   - state: Onboarding state
    ///   - config: SDK configuration
    ///   - apiClient: API client instance
    public init(state: OnboardingState, config: OnairosConfig, apiClient: OnairosAPIClient) {
        self.state = state
        self.config = config
        self.apiClient = apiClient
        
        // Configure API client
        apiClient.configure(baseURL: config.apiBaseURL)
    }
    
    /// Start the onboarding flow
    /// - Parameters:
    ///   - presentingViewController: View controller to present from
    ///   - completion: Completion handler
    public func start(
        from presentingViewController: UIViewController,
        completion: @escaping OnboardingCompletion
    ) {
        self.completion = completion
        
        // Reset state
        state.reset()
        
        // Create and present modal
        let modalController = OnairosModalController(
            coordinator: self,
            state: state,
            config: config
        )
        
        self.modalController = modalController
        
        // Present modal with animation
        modalController.modalPresentationStyle = .overFullScreen
        modalController.modalTransitionStyle = .crossDissolve
        
        presentingViewController.present(modalController, animated: true)
    }
    
    /// Dismiss the onboarding flow
    /// - Parameter result: Onboarding result
    private func dismiss(with result: OnboardingResult) {
        print("🔍 [DEBUG] OnboardingCoordinator.dismiss called with result: \(result)")
        
        // Ensure we're on the main thread for UI operations
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let modalController = self.modalController {
                // Use the custom dismissModal method for better animation
                modalController.dismissModal { [weak self] in
                    print("🔍 [DEBUG] Modal dismissal completed, calling completion handlers")
                    self?.completion?(result)
                    self?.onCompletion?(result)
                    self?.cleanup()
                }
            } else {
                print("⚠️ [DEBUG] Modal controller is nil, calling completion handlers directly")
                self.completion?(result)
                self.onCompletion?(result)
                self.cleanup()
            }
        }
    }
    
    /// Clean up resources
    private func cleanup() {
        modalController = nil
        completion = nil
        connectedPlatformData.removeAll()
        trainingManager?.disconnect()
        trainingManager = nil
    }
    
    // MARK: - Step Navigation
    
    /// Proceed to next step
    public func proceedToNextStep() {
        print("🔍 [DEBUG] proceedToNextStep called")
        print("🔍 [DEBUG] Current step: \(state.currentStep)")
        print("🔍 [DEBUG] State email: '\(state.email)'")
        print("🔍 [DEBUG] Email validation result: \(state.validateCurrentStep())")
        
        guard state.validateCurrentStep() else {
            print("🔍 [DEBUG] Step validation failed - showing error")
            state.errorMessage = "Please complete the current step before proceeding."
            return
        }
        
        print("🔍 [DEBUG] Step validation passed - proceeding with step: \(state.currentStep)")
        
        switch state.currentStep {
        case .email:
            print("🔍 [DEBUG] Calling handleEmailStep()")
            handleEmailStep()
        case .verify:
            print("🔍 [DEBUG] Calling handleVerifyStep()")
            handleVerifyStep()
        case .connect:
            // Manual proceed from connect step
            print("🔍 [DEBUG] Calling handleConnectStepProceed()")
            handleConnectStepProceed()
        case .success:
            print("🔍 [DEBUG] Calling handleSuccessStep()")
            handleSuccessStep()
        case .pin:
            print("🔍 [DEBUG] Calling handlePINStep()")
            handlePINStep()
        case .training:
            print("🔍 [DEBUG] Calling handleTrainingComplete()")
            handleTrainingComplete()
        }
    }
    
    /// Handle manual proceed from connect step
    private func handleConnectStepProceed() {
        if config.isTestMode {
            print("🧪 [TEST MODE] User manually proceeding from connect step")
        }
        
        // User manually chose to proceed (either with or without connections)
        // Skip the success step and go directly to PIN creation
        state.currentStep = .pin
        
        if config.isTestMode {
            print("🧪 [TEST MODE] Moving directly to PIN step")
        }
    }
    
    /// Go back to previous step
    public func goBackToPreviousStep() {
        print("🔙 [COORDINATOR] Going back from step: \(state.currentStep)")
        
        switch state.currentStep {
        case .email:
            // Can't go back from first step
            cancelOnboarding()
        case .verify:
            state.currentStep = .email
        case .connect:
            state.currentStep = .verify
        case .success:
            state.currentStep = .connect
        case .pin:
            state.currentStep = .connect // Go back to connect step, skip success
        case .training:
            // Stop any ongoing training before going back
            print("🛑 [COORDINATOR] Stopping training and returning to PIN step")
            trainingManager?.disconnect()
            
            // Reset training state
            state.trainingProgress = 0.0
            state.trainingStatus = "Initializing..."
            
            // Go back to PIN step
            state.currentStep = .pin
        }
        
        // Clear any error messages and loading state
        state.errorMessage = nil
        state.isLoading = false
        
        print("🔙 [COORDINATOR] Moved to step: \(state.currentStep)")
    }
    
    /// Cancel onboarding flow
    public func cancelOnboarding() {
        print("🚫 [COORDINATOR] cancelOnboarding called")
        
        // Stop any ongoing training
        trainingManager?.disconnect()
        
        // Reset state to prevent any ongoing operations
        state.isLoading = false
        state.errorMessage = nil
        
        // Dismiss with user cancelled result
        dismiss(with: .failure(.userCancelled))
    }
    
    // MARK: - Step Handlers
    
    /// Handle email input step
    private func handleEmailStep() {
        state.isLoading = true
        state.errorMessage = nil
        
        // In test mode, accept any email immediately
        if config.isTestMode {
            print("🧪 Test mode - accepting email: \(state.email)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state.isLoading = false
                self?.state.currentStep = .verify
            }
            return
        }
        
        Task {
            let result = await apiClient.requestEmailVerification(email: state.email)
            
            await MainActor.run {
                state.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Email verification request successful")
                    
                    // Store account info if provided
                    if let accountInfo = response.accountInfo {
                        state.accountInfo = accountInfo
                    }
                    
                    state.currentStep = .verify
                case .failure(let error):
                    print("❌ Email verification failed: \(error)")
                    
                    let userFriendlyMessage = getUserFriendlyErrorMessage(for: error)
                    state.errorMessage = userFriendlyMessage
                    
                    if config.isDebugMode {
                        print("🔍 Debug mode - proceeding to verify step despite API failure")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                            self?.state.errorMessage = nil
                            self?.state.currentStep = .verify
                        }
                    }
                }
            }
        }
    }
    
    /// Get user-friendly error message for API failures
    /// - Parameter error: OnairosError to convert
    /// - Returns: User-friendly error message
    private func getUserFriendlyErrorMessage(for error: OnairosError) -> String {
        switch error {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .networkError(let reason):
            return "Network error: \(reason). Please try again."
        case .apiError(let message, let statusCode):
            if let statusCode = statusCode {
                switch statusCode {
                case 404:
                    return "Email verification service is temporarily unavailable. Please try again later."
                case 429:
                    return "Too many requests. Please wait a moment and try again."
                case 500...599:
                    return "Server error. Please try again later."
                default:
                    return "Unable to verify email: \(message). Please try again."
                }
            } else {
                return "Unable to verify email: \(message). Please try again."
            }
        case .emailVerificationFailed(let reason):
            return "Email verification failed: \(reason). Please try again."
        default:
            return "Unable to verify email. Please check your internet connection and try again."
        }
    }
    
    /// Handle email verification step
    private func handleVerifyStep() {
        state.isLoading = true
        state.errorMessage = nil
        
        // In test mode, skip API call and proceed directly
        if config.isTestMode {
            print("🧪 [TEST MODE] Verify step - accepting any code: \(state.verificationCode)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state.isLoading = false
                self?.state.currentStep = .connect
            }
            return
        }
        
        Task {
            let result = await apiClient.verifyEmailCode(email: state.email, code: state.verificationCode)
            
            await MainActor.run {
                state.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isSuccessfulVerification {
                        print("✅ Email verification successful with JWT token")
                        
                        // ENHANCED: Extract and store userName from multiple possible locations
                        extractAndStoreUserName(from: response)
                        
                        // Handle user data from the API response
                        if let user = response.user {
                            storeUserData(user, isNewUser: !(response.existingUser ?? true))
                        }
                        
                        // Check if this is a new user
                        if let existingUser = response.existingUser {
                            print("👤 User: \(existingUser ? "Existing" : "New")")
                        }
                        
                        state.currentStep = .connect
                    } else if response.success {
                        print("⚠️ Code validation successful but no JWT token received")
                        handleVerificationFailure(response: response)
                    } else {
                        print("❌ Email verification failed")
                        handleVerificationFailure(response: response)
                    }
                case .failure(let error):
                    print("❌ Email verification API call failed: \(error)")
                    handleVerificationError(error: error)
                }
            }
        }
    }
    
    /// Extract and store userName from email verification response
    /// This handles multiple possible response structures to ensure userName is always stored
    private func extractAndStoreUserName(from response: EmailVerificationResponse) {
        print("🔍 [USERNAME DEBUG] Extracting userName from email verification response")
        
        var extractedUserName: String?
        
        // Method 1: Try to get userName from response.user
        if let user = response.user {
            extractedUserName = user.userName
            print("🔍 [USERNAME DEBUG] Method 1: Found userName from response.user: \(user.userName)")
        }
        
        // Method 2: Try to get userName from JWT token payload
        if extractedUserName == nil {
            if let jwtToken = response.userJWTToken {
                if let userInfo = JWTTokenManager.parseJWTPayload(token: jwtToken) {
                    // First try top-level userName
                    if let userName = userInfo["userName"] as? String {
                        extractedUserName = userName
                        print("🔍 [USERNAME DEBUG] Method 2a: Found userName from JWT payload: \(userName)")
                    }
                    // Then try full_user_object.userName (backend structure)
                    else if let fullUserObject = userInfo["full_user_object"] as? [String: Any],
                            let userName = fullUserObject["userName"] as? String {
                        extractedUserName = userName
                        print("🔍 [USERNAME DEBUG] Method 2b: Found userName from JWT full_user_object: \(userName)")
                    }
                    // Also try username (lowercase) for compatibility
                    else if let username = userInfo["username"] as? String {
                        extractedUserName = username
                        print("🔍 [USERNAME DEBUG] Method 2c: Found username (lowercase) from JWT payload: \(username)")
                    }
                }
            }
        }
        
        // Method 3: Try to get userName from accountInfo
        if extractedUserName == nil {
            if let accountInfo = response.accountInfo {
                if let userName = accountInfo["userName"]?.value as? String {
                    extractedUserName = userName
                    print("🔍 [USERNAME DEBUG] Method 3: Found userName from accountInfo: \(userName)")
                }
            }
        }
        
        // Method 4: Try to get userName from accountDetails (alternative field name)
        if extractedUserName == nil {
            if let accountInfo = response.accountInfo {
                if let accountDetails = accountInfo["accountDetails"]?.value as? [String: Any] {
                    if let userName = accountDetails["userName"] as? String {
                        extractedUserName = userName
                        print("🔍 [USERNAME DEBUG] Method 4: Found userName from accountDetails: \(userName)")
                    }
                }
            }
        }
        
        // Store the extracted userName
        if let userName = extractedUserName {
            UserDefaults.standard.set(userName, forKey: "onairos_username")
            print("✅ [USERNAME DEBUG] Successfully stored userName: \(userName)")
            
            // Verify storage
            let storedUserName = UserDefaults.standard.string(forKey: "onairos_username")
            print("🔍 [USERNAME DEBUG] Verification - stored userName: \(storedUserName ?? "nil")")
        } else {
            print("❌ [USERNAME DEBUG] Failed to extract userName from response")
            print("🔍 [USERNAME DEBUG] Response structure:")
            print("   - response.user: \(response.user != nil ? "present" : "nil")")
            print("   - response.userJWTToken: \(response.userJWTToken != nil ? "present" : "nil")")
            print("   - response.accountInfo: \(response.accountInfo != nil ? "present" : "nil")")
            
            // Fallback: Use email-based username but log a warning
            let fallbackUserName = extractUsername(from: state.email)
            UserDefaults.standard.set(fallbackUserName, forKey: "onairos_username")
            print("⚠️ [USERNAME DEBUG] Using fallback userName from email: \(fallbackUserName)")
            print("⚠️ [USERNAME DEBUG] THIS MAY CAUSE PIN STORAGE ISSUES - userName mismatch with backend")
        }
    }
    
    /// Store user data from verification response
    private func storeUserData(_ user: EmailVerificationResponse.EmailVerificationData.UserData, isNewUser: Bool) {
        // Store user data in UserDefaults for later use
        UserDefaults.standard.set(user.userId, forKey: "onairos_user_id")
        UserDefaults.standard.set(user.userName, forKey: "onairos_username")
        UserDefaults.standard.set(user.name, forKey: "onairos_user_name")
        UserDefaults.standard.set(user.email, forKey: "onairos_user_email")
        UserDefaults.standard.set(user.verified, forKey: "onairos_user_verified")
        UserDefaults.standard.set(user.creationDate, forKey: "onairos_user_creation_date")
        UserDefaults.standard.set(isNewUser, forKey: "onairos_is_new_user")
        
        print("💾 User data stored locally")
    }
    
    /// Handle verification failure from API response
    private func handleVerificationFailure(response: EmailVerificationResponse) {
        if config.isDebugMode {
            state.errorMessage = "Invalid verification code, but debug mode allows proceeding..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                print("🔍 Debug mode - proceeding despite invalid code")
                self?.state.errorMessage = nil
                self?.state.currentStep = .connect
            }
        } else {
            if let error = response.error {
                state.errorMessage = error
                if let attemptsRemaining = response.attemptsRemaining {
                    state.errorMessage = "\(error) (\(attemptsRemaining) attempts remaining)"
                }
            } else {
                state.errorMessage = "Invalid verification code. Please check your email and try again."
            }
        }
    }
    
    /// Handle verification API error
    private func handleVerificationError(error: OnairosError) {
        // CRITICAL FIX: Always show error message first, never dismiss modal on API failure
        let userFriendlyMessage = getUserFriendlyVerificationErrorMessage(for: error)
        state.errorMessage = userFriendlyMessage
        
        if config.isDebugMode {
            // In debug mode, show error but allow proceeding after delay
            print("🔍 [DEBUG] Debug mode - showing verification error but will allow proceeding")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                print("🔍 [DEBUG] Debug mode - proceeding to connect step despite verification API failure")
                self?.state.errorMessage = nil
                self?.state.currentStep = .connect
            }
        } else {
            // In production mode, stay on verification step and show error
            print("🔍 [DEBUG] Production mode - staying on verification step with error message")
            // DO NOT dismiss modal or proceed - let user retry or cancel manually
        }
    }
    
    /// Get user-friendly error message for verification API failures
    /// - Parameter error: OnairosError to convert
    /// - Returns: User-friendly error message
    private func getUserFriendlyVerificationErrorMessage(for error: OnairosError) -> String {
        switch error {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .networkError(let reason):
            return "Network error: \(reason). Please try again."
        case .apiError(let message, let statusCode):
            if let statusCode = statusCode {
                switch statusCode {
                case 400:
                    return "Invalid verification code format. Please enter the 6-digit code from your email."
                case 404:
                    return "Verification service is temporarily unavailable. Please try again later."
                case 429:
                    return "Too many verification attempts. Please wait a moment and try again."
                case 500...599:
                    return "Server error during verification. Please try again later."
                default:
                    return "Unable to verify code: \(message). Please try again."
                }
            } else {
                return "Unable to verify code: \(message). Please try again."
            }
        case .invalidCredentials:
            return "Invalid verification code. Please check your email and enter the correct 6-digit code."
        default:
            return "Unable to verify code. Please check your internet connection and try again."
        }
    }
    
    /// Handle platform connection step
    private func handleConnectStep() {
        if config.isTestMode {
            print("🧪 [TEST MODE] Connect step - allowing manual proceed without platform connections")
        }
        
        // In test mode or if empty connections are allowed, show the connect screen but don't auto-advance
        // User needs to manually press "Continue" or "Skip" button
        if config.isTestMode || config.allowEmptyConnections || config.isDebugMode {
            // Don't auto-advance - let user manually proceed
            // The UI will show a "Continue" or "Skip" button that calls proceedToNextStep()
            if config.isTestMode {
                print("🧪 [TEST MODE] Connect step ready - user can manually proceed")
            }
        } else if !state.connectedPlatforms.isEmpty {
            // User has connected platforms, they can proceed manually
            if config.isDebugMode {
                print("🐛 [DEBUG] Connect step - user has connected platforms, can proceed")
            }
        } else {
            // User must connect at least one platform
            state.errorMessage = "Please connect at least one platform to continue."
        }
    }
    
    /// Handle success step (auto-advance)
    /// NOTE: Success step is a brief "Success!" screen between Connect and PIN steps
    /// The SuccessStepViewController handles its own auto-advance, so this method
    /// is called when the user manually proceeds from the success step
    private func handleSuccessStep() {
        if config.isTestMode {
            print("🧪 [TEST MODE] Success step - user manually proceeding to PIN")
        }
        
        // User manually proceeded from success step, move to PIN
        state.currentStep = .pin
    }
    
    /// Handle PIN creation step
    private func handlePINStep() {
        // In test mode, skip API call and proceed directly to training
        if config.isTestMode {
            print("🧪 [TEST MODE] PIN step - accepting any PIN: \(state.pin)")
            state.isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state.isLoading = false
                self?.state.currentStep = .training
                print("🧪 [TEST MODE] Moving to training step")
                self?.startAITraining()
            }
            return
        }
        
        // PIN has been submitted to backend via PINStepViewController
        // No need for additional registration - proceed directly to training
        print("✅ [PIN STEP] PIN submitted successfully, proceeding to training")
        state.currentStep = .training
        startAITraining()
    }
    
    /// Start AI training (public method for external access)
    public func startTraining() {
        state.currentStep = .training
        startAITraining()
    }
    
    /// Check email verification status
    /// - Parameter email: Email address to check
    /// - Returns: Verification status response
    public func checkEmailVerificationStatus(email: String) async -> Result<EmailVerificationStatusResponse, OnairosError> {
        return await apiClient.checkEmailVerificationStatus(email: email)
    }
    
    /// Handle training completion
    private func handleTrainingComplete() {
        // Save session
        UserDefaults.standard.set(true, forKey: "onairos_session_saved")
        UserDefaults.standard.set(state.email, forKey: "onairos_user_email")
        
        // Create success result
        let onboardingData = OnboardingData(
            apiURL: config.apiBaseURL,
            token: "placeholder_token", // Would be returned by API
            userData: [
                "email": state.email,
                "pin": state.pin
            ],
            connectedPlatforms: connectedPlatformData,
            sessionSaved: true,
            inferenceData: nil,
            partner: nil,
            accountInfo: state.accountInfo?.mapValues { $0.value }
        )
        
        dismiss(with: .success(onboardingData))
    }
    
    // MARK: - Platform Authentication
    
    /// Authenticate with specific platform
    /// - Parameter platform: Platform to authenticate
    /// - Returns: Platform data
    private func authenticatePlatform(_ platform: Platform) async throws -> PlatformData {
        switch platform.authMethod {
        case .nativeSDK:
            return try await authenticateYouTube()
        case .oauth:
            return try await authenticateOAuth(platform)
        }
    }
    
    /// Authenticate with YouTube platform
    /// - Returns: YouTube platform data
    private func authenticateYouTube() async throws -> PlatformData {
        // Initialize YouTube authentication manager
        YouTubeAuthManager.shared.initialize()
        
        // Authenticate with YouTube using native SDK
        let credentials = try await YouTubeAuthManager.shared.authenticate()
        
        // Get username from stored user data or use email
        let username = UserDefaults.standard.string(forKey: "onairos_username") ?? extractUsername(from: state.email)
        
        // Send credentials to backend for verification and data sync
        let result = await apiClient.authenticateYouTube(
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken ?? "",
            idToken: credentials.idToken,
            username: username
        )
        
        switch result {
        case .success(let response):
            print("✅ [YouTube Auth] Successfully authenticated with backend")
            return PlatformData(
                platform: "youtube",
                accessToken: credentials.accessToken,
                refreshToken: credentials.refreshToken,
                expiresAt: credentials.expiresAt,
                userData: response.userData?.mapValues { $0.value }
            )
        case .failure(let error):
            print("❌ [YouTube Auth] Backend authentication failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Extract username from email address
    /// - Parameter email: Email address
    /// - Returns: Username (part before @)
    private func extractUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? email
    }
    
    /// Authenticate with OAuth platform
    /// - Parameter platform: Platform to authenticate
    /// - Returns: Platform data
    private func authenticateOAuth(_ platform: Platform) async throws -> PlatformData {
        // Placeholder - would open OAuth WebView
        throw OnairosError.platformUnavailable(platform.displayName)
        
        /*
        // Example implementation:
        let authCode = try await OAuthManager.shared.authenticate(platform: platform)
        let username = UserDefaults.standard.string(forKey: "onairos_username") ?? ""
        let request = PlatformAuthRequest(
            platform: platform.rawValue,
            authCode: authCode,
            username: username
        )
        
        let result = await apiClient.authenticatePlatform(request)
        
        switch result {
        case .success(let response):
            return PlatformData(
                platform: platform.rawValue,
                accessToken: response.token,
                refreshToken: nil,
                expiresAt: nil,
                userData: response.userData?.mapValues { $0.value }
            )
        case .failure(let error):
            throw error
        }
        */
    }
    
    // MARK: - AI Training
    
    /// Start AI model training
    private func startAITraining() {
        state.setTrainingProgress(0.0)
        state.trainingStatus = "Initializing AI training..."
        
        if config.simulateTraining {
            simulateTraining()
        } else {
            startRealTraining()
        }
    }
    
    /// Simulate training progress for testing
    private func simulateTraining() {
        // Slower simulation in test mode so user can see the training screen
        let interval = config.isTestMode ? 0.1 : 0.1
        let increment = config.isTestMode ? 0.015 : 0.02  // Slower in test mode
        
        // CRITICAL: Protect against invalid increment values
        guard !interval.isNaN && !interval.isInfinite && interval > 0 &&
              !increment.isNaN && !increment.isInfinite && increment > 0 else {
            print("🚨 [ERROR] Invalid training simulation parameters - interval: \(interval), increment: \(increment)")
            // Fallback to safe values
            state.setTrainingProgress(1.0)
            state.trainingStatus = "Training completed"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handleTrainingComplete()
            }
            return
        }
        
        if config.isTestMode {
            print("🧪 [TEST MODE] Starting training simulation - will take ~10 seconds to complete")
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // CRITICAL: Protect against NaN in current progress
            let currentProgress = self.state.trainingProgress
            guard !currentProgress.isNaN && !currentProgress.isInfinite else {
                print("🚨 [ERROR] Current training progress is NaN: \(currentProgress)")
                timer.invalidate()
                self.state.setTrainingProgress(1.0)
                self.handleTrainingComplete()
                return
            }
            
            // Safely increment progress with NaN protection
            let newProgress = currentProgress + increment
            guard !newProgress.isNaN && !newProgress.isInfinite else {
                print("🚨 [ERROR] New training progress would be NaN: \(newProgress)")
                timer.invalidate()
                self.state.setTrainingProgress(1.0)
                self.handleTrainingComplete()
                return
            }
            
            self.state.setTrainingProgress(newProgress)
            
            // Update status messages based on progress
            if self.config.isTestMode {
                // More obvious test mode messages
                if self.state.trainingProgress >= 0.2 && self.state.trainingProgress < 0.4 {
                    self.state.trainingStatus = "🧪 TEST MODE: Simulating data analysis..."
                } else if self.state.trainingProgress >= 0.4 && self.state.trainingProgress < 0.7 {
                    self.state.trainingStatus = "🧪 TEST MODE: Building mock AI model..."
                } else if self.state.trainingProgress >= 0.7 && self.state.trainingProgress < 0.9 {
                    self.state.trainingStatus = "🧪 TEST MODE: Finalizing simulation..."
                } else if self.state.trainingProgress < 0.2 {
                    self.state.trainingStatus = "🧪 TEST MODE: Initializing test training..."
                }
            } else {
                // Normal simulation messages
                if self.state.trainingProgress >= 0.3 && self.state.trainingProgress < 0.4 {
                    self.state.trainingStatus = "Analyzing your data..."
                } else if self.state.trainingProgress >= 0.6 && self.state.trainingProgress < 0.7 {
                    self.state.trainingStatus = "Building your AI model..."
                } else if self.state.trainingProgress >= 0.9 && self.state.trainingProgress < 1.0 {
                    self.state.trainingStatus = "Finalizing training..."
                }
            }
            
            if self.state.trainingProgress >= 1.0 {
                timer.invalidate()
                self.state.setTrainingProgress(1.0)  // Ensure exactly 1.0, no NaN
                self.state.trainingStatus = self.config.isTestMode ? "🧪 TEST MODE: Training simulation complete!" : "Training complete!"
                
                // Longer completion delay in test mode so user can see the completion
                let completionDelay = self.config.isTestMode ? 3.0 : 1.5
                if self.config.isTestMode {
                    print("🧪 [TEST MODE] Training complete! Will finish in \(completionDelay) seconds")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                    if self.config.isTestMode {
                        print("🧪 [TEST MODE] Completing onboarding flow with success")
                    }
                    self.handleTrainingComplete()
                }
            }
        }
    }
    
    /// Start real AI training with Socket.IO
    private func startRealTraining() {
        trainingManager = TrainingManager(config: config)
        
        trainingManager?.onProgress = { [weak self] progress in
            Task { @MainActor in
                // Protect against NaN values from external progress updates
                self?.state.setTrainingProgress(progress.percentage)
                self?.state.trainingStatus = progress.status
            }
        }
        
        trainingManager?.onComplete = { [weak self] in
            Task { @MainActor in
                self?.state.setTrainingProgress(1.0)  // Ensure exactly 1.0, no NaN
                self?.state.trainingStatus = "Training complete!"
                
                // Auto-complete after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.handleTrainingComplete()
                }
            }
        }
        
        trainingManager?.onError = { [weak self] error in
            Task { @MainActor in
                self?.state.errorMessage = error.localizedDescription
                // Fall back to simulation on error
                self?.simulateTraining()
            }
        }
        
        // Prepare user data with enhanced username resolution
        var resolvedUsername = UserDefaults.standard.string(forKey: "onairos_username")
        var usernameSource = "UserDefaults"
        
        // If no username in UserDefaults, try to get it from the current JWT token
        if resolvedUsername == nil {
            if let jwtToken = JWTTokenManager.shared.getCachedToken() {
                if let userInfo = JWTTokenManager.parseJWTPayload(token: jwtToken) {
                    // Try full_user_object.userName first (backend structure)
                    if let fullUserObject = userInfo["full_user_object"] as? [String: Any],
                       let userName = fullUserObject["userName"] as? String {
                        resolvedUsername = userName
                        usernameSource = "JWT full_user_object"
                    }
                    // Try top-level userName
                    else if let userName = userInfo["userName"] as? String {
                        resolvedUsername = userName
                        usernameSource = "JWT userName"
                    }
                    // Try username (lowercase)
                    else if let username = userInfo["username"] as? String {
                        resolvedUsername = username
                        usernameSource = "JWT username"
                    }
                }
            }
        }
        
        // Final fallback: extract from email
        let finalUsername = resolvedUsername ?? extractUsername(from: state.email)
        if resolvedUsername == nil {
            usernameSource = "email extraction"
        }
        
        let userData: [String: Any] = [
            "email": state.email,
            "username": finalUsername,
            "platforms": Array(state.connectedPlatforms)
        ]
        
        print("🔍 [TRAINING DEBUG] Using username for training: \(finalUsername)")
        print("🔍 [TRAINING DEBUG] Username source: \(usernameSource)")
        print("🔍 [TRAINING DEBUG] UserDefaults username: \(UserDefaults.standard.string(forKey: "onairos_username") ?? "nil")")
        print("🔍 [TRAINING DEBUG] JWT token available: \(JWTTokenManager.shared.getCachedToken() != nil ? "YES" : "NO")")
        
        // Prepare connected platforms data in the correct format
        var connectedPlatformsArray: [[String: Any]] = []
        for (platformName, platformData) in connectedPlatformData {
            var platformDict: [String: Any] = [
                "platform": platformName,
                "accessToken": platformData.accessToken
            ]
            
            if let refreshToken = platformData.refreshToken {
                platformDict["refreshToken"] = refreshToken
            }
            if let expiresAt = platformData.expiresAt {
                platformDict["expiresAt"] = expiresAt.timeIntervalSince1970
            }
            if let userData = platformData.userData {
                platformDict["userData"] = userData
            }
            
            connectedPlatformsArray.append(platformDict)
        }
        
        let connectedPlatforms: [String: Any] = [
            "platforms": connectedPlatformsArray
        ]
        
        // Start training with proper parameters
        trainingManager?.startTraining(
            userData: userData,
            email: state.email,
            connectedPlatforms: connectedPlatforms
        )
    }
    
    // MARK: - Platform Connection Management
    
    /// Handle platform connection success
    /// - Parameter platform: Platform that was successfully connected
    public func handlePlatformConnected(_ platform: Platform) {
        print("📱 [OnboardingCoordinator] Platform connected: \(platform.displayName)")
        
        // Update connected platforms data
        let platformData = PlatformData(
            platform: platform.rawValue,
            accessToken: UserDefaults.standard.string(forKey: "onairos_\(platform.rawValue)_token") ?? "",
            refreshToken: nil,
            expiresAt: UserDefaults.standard.object(forKey: "onairos_\(platform.rawValue)_token_expires") as? Date,
            userData: [:]
        )
        
        connectedPlatformData[platform.rawValue] = platformData
        
        // Log connection success
        print("✅ [OnboardingCoordinator] Successfully stored platform data for \(platform.displayName)")
    }
    
    /// Connect to platform (called from UI)
    /// - Parameter platform: Platform to connect to
    public func connectToPlatform(_ platform: Platform) {
        print("🔗 [OnboardingCoordinator] Connecting to platform: \(platform.displayName)")
        
        // Set loading state
        state.isLoading = true
        
        Task {
            do {
                // Add timeout specifically for YouTube to prevent freezing
                let platformData: PlatformData
                if platform == .youtube {
                    platformData = try await withTimeout(seconds: 5) {
                        try await self.authenticatePlatform(platform)
                    }
                } else {
                    platformData = try await self.authenticatePlatform(platform)
                }
                
                await MainActor.run {
                    // Store platform data
                    self.connectedPlatformData[platform.rawValue] = platformData
                    
                    // Add to connected platforms
                    self.state.connectedPlatforms.insert(platform.rawValue)
                    
                    // Clear loading state
                    self.state.isLoading = false
                    
                    print("✅ [OnboardingCoordinator] Successfully connected to \(platform.displayName)")
                }
                
            } catch {
                await MainActor.run {
                    self.state.isLoading = false
                    
                    // Handle timeout specifically for YouTube
                    if platform == .youtube && error is TimeoutError {
                        self.state.errorMessage = "YouTube connection timed out. Please try again or check your connection."
                        print("⏰ [OnboardingCoordinator] YouTube connection timed out after 5 seconds")
                    } else {
                        self.state.errorMessage = "Failed to connect to \(platform.displayName): \(error.localizedDescription)"
                        print("❌ [OnboardingCoordinator] Failed to connect to \(platform.displayName): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Execute async operation with timeout
    /// - Parameters:
    ///   - seconds: Timeout duration in seconds
    ///   - operation: Async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: TimeoutError if operation times out
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Return the first result (either success or timeout)
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return result
        }
    }
} 