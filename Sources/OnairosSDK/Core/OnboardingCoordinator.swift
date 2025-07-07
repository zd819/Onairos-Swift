import UIKit
import Foundation

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
        modalController?.dismiss(animated: true) { [weak self] in
            print("🔍 [DEBUG] Modal dismissal completed, calling completion handlers")
            self?.completion?(result)
            self?.onCompletion?(result)
            self?.cleanup()
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
        state.currentStep = .success
        
        if config.isTestMode {
            print("🧪 [TEST MODE] Moving to success step")
        }
    }
    
    /// Go back to previous step
    public func goBackToPreviousStep() {
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
            state.currentStep = .success
        case .training:
            state.currentStep = .pin
        }
        
        state.errorMessage = nil
    }
    
    /// Cancel onboarding flow
    public func cancelOnboarding() {
        dismiss(with: .failure(.userCancelled))
    }
    
    // MARK: - Step Handlers
    
    /// Handle email input step
    private func handleEmailStep() {
        print("🔍 [DEBUG] handleEmailStep called with email: '\(state.email)'")
        print("🔍 [DEBUG] Current step: \(state.currentStep)")
        print("🔍 [DEBUG] Config - isTestMode: \(config.isTestMode), isDebugMode: \(config.isDebugMode)")
        
        state.isLoading = true
        state.errorMessage = nil
        
        // In test mode, accept any email immediately
        if config.isTestMode {
            print("🧪 [TEST MODE] Email step - accepting any email: \(state.email)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                print("🧪 [TEST MODE] Setting isLoading to false and moving to verify step")
                self?.state.isLoading = false
                self?.state.currentStep = .verify
                print("🧪 [TEST MODE] Moving to verification step - new step: \(self?.state.currentStep ?? .email)")
            }
            return
        }
        
        print("🔍 [DEBUG] Making API call for email verification...")
        Task {
            let result = await apiClient.requestEmailVerification(email: state.email)
            print("🔍 [DEBUG] API call completed with result: \(result)")
            
            await MainActor.run {
                state.isLoading = false
                
                switch result {
                case .success:
                    print("🔍 [DEBUG] Email verification success - moving to verify step")
                    state.currentStep = .verify
                case .failure(let error):
                    print("🔍 [DEBUG] Email verification failed: \(error)")
                    
                    // CRITICAL FIX: Always show error message first, never dismiss modal on API failure
                    let userFriendlyMessage = getUserFriendlyErrorMessage(for: error)
                    state.errorMessage = userFriendlyMessage
                    
                    if config.isDebugMode {
                        // In debug mode, show error but allow proceeding after delay
                        print("🔍 [DEBUG] Debug mode - showing error but will allow proceeding")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                            print("🔍 [DEBUG] Debug mode - proceeding to verify step despite API failure")
                            self?.state.errorMessage = nil
                            self?.state.currentStep = .verify
                        }
                    } else {
                        // In production mode, stay on email step and show error
                        print("🔍 [DEBUG] Production mode - staying on email step with error message")
                        // DO NOT dismiss modal or proceed - let user retry or cancel manually
                    }
                }
                print("🔍 [DEBUG] Final step after API call: \(state.currentStep)")
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
        
        // In test mode, accept any verification code immediately
        if config.isTestMode {
            print("🧪 [TEST MODE] Verify step - accepting any code: \(state.verificationCode)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state.isLoading = false
                self?.state.currentStep = .connect
                print("🧪 [TEST MODE] Moving to connect step")
            }
            return
        }
        
        Task {
            let result = await apiClient.verifyEmailCode(
                email: state.email,
                code: state.verificationCode
            )
            
            await MainActor.run {
                state.isLoading = false
                
                switch result {
                case .success(let verified):
                    if verified {
                        print("🔍 [DEBUG] Email verification code validated successfully")
                        state.currentStep = .connect
                    } else {
                        print("🔍 [DEBUG] Email verification code invalid")
                        if config.isDebugMode {
                            // In debug mode, show error but allow proceeding after delay
                            state.errorMessage = "Invalid verification code, but debug mode allows proceeding..."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                                print("🔍 [DEBUG] Debug mode - proceeding to connect step despite invalid code")
                                self?.state.errorMessage = nil
                                self?.state.currentStep = .connect
                            }
                        } else {
                            state.errorMessage = "Invalid verification code. Please check your email and try again."
                        }
                    }
                case .failure(let error):
                    print("🔍 [DEBUG] Email verification API call failed: \(error)")
                    
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
            }
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
    private func handleSuccessStep() {
        if config.isTestMode {
            print("🧪 [TEST MODE] Success step - showing brief success screen then moving to PIN")
        }
        state.currentStep = .pin
        
        // Auto-advance after a brief moment to show the success screen
        let delay = config.isTestMode ? 1.5 : 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            // Success step auto-advances to PIN - this is intended behavior
            if self?.config.isTestMode == true {
                print("🧪 [TEST MODE] Auto-advancing from success to PIN step")
            }
            // No need to call handleSuccessStep() again, just let the UI update
        }
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
        
        // Send PIN to backend and start training
        Task {
            do {
                let userData = createUserRegistrationData()
                let result = await apiClient.registerUser(userData)
                
                switch result {
                case .success:
                    await MainActor.run {
                        state.currentStep = .training
                        startAITraining()
                    }
                case .failure(let error):
                    await MainActor.run {
                        if config.isDebugMode {
                            // In debug mode, proceed even if registration fails
                            state.currentStep = .training
                            startAITraining()
                        } else {
                            state.errorMessage = error.localizedDescription
                            state.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    /// Create user registration data
    private func createUserRegistrationData() -> UserRegistrationRequest {
        return UserRegistrationRequest(
            email: state.email,
            pin: state.pin,
            connectedPlatforms: connectedPlatformData
        )
    }
    
    /// Start AI training (public method for external access)
    public func startTraining() {
        state.currentStep = .training
        startAITraining()
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
            partner: nil
        )
        
        dismiss(with: .success(onboardingData))
    }
    
    // MARK: - Platform Authentication
    
    /// Handle platform connection success
    /// - Parameter platform: Platform that was successfully connected
    public func handlePlatformConnected(_ platform: Platform) {
        print("📱 [OnboardingCoordinator] Platform connected: \(platform.displayName)")
        
        // Update connected platforms data
        let platformData = PlatformData(
            accessToken: UserDefaults.standard.string(forKey: "onairos_\(platform.rawValue)_token") ?? "",
            refreshToken: nil,
            expiresAt: UserDefaults.standard.object(forKey: "onairos_\(platform.rawValue)_token_expires") as? Date,
            userData: [:]
        )
        
        connectedPlatformData[platform.rawValue] = platformData
        
        // Log connection success
        print("✅ [OnboardingCoordinator] Successfully stored platform data for \(platform.displayName)")
    }
    
    /// Connect to platform (legacy method for backward compatibility)
    /// - Parameter platform: Platform to connect to
    public func connectToPlatform(_ platform: Platform) {
        print("🔗 [OnboardingCoordinator] Connecting to platform: \(platform.displayName)")
        
        // This method can be used for non-OAuth platforms or additional setup
        // For OAuth platforms, the connection is handled by the webview flow
        
        switch platform.authMethod {
        case .oauth:
            print("ℹ️ [OnboardingCoordinator] OAuth platforms handled by webview")
        case .nativeSDK:
            print("ℹ️ [OnboardingCoordinator] Native SDK platforms need additional setup")
        }
    }
    
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
    
    /// Authenticate with YouTube using Google Sign-In
    /// - Returns: YouTube platform data
    private func authenticateYouTube() async throws -> PlatformData {
        // Placeholder - would use Google Sign-In SDK
        throw OnairosError.googleSignInFailed("Google Sign-In not configured")
        
        /*
        // Example implementation when Google Sign-In is available:
        let credentials = try await YouTubeAuthManager.shared.authenticate()
        let result = await apiClient.authenticateYouTube(
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            idToken: credentials.idToken
        )
        
        switch result {
        case .success(let response):
            return PlatformData(
                platform: "youtube",
                accessToken: credentials.accessToken,
                refreshToken: credentials.refreshToken,
                expiresAt: credentials.expiresAt,
                userData: response.userData?.mapValues { $0.value }
            )
        case .failure(let error):
            throw error
        }
        */
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
        let request = PlatformAuthRequest(
            platform: platform.rawValue,
            authCode: authCode
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
        
        // Start training
        let userData: [String: Any] = [
            "email": state.email,
            "platforms": Array(state.connectedPlatforms),
            "deviceInfo": DeviceInfo()
        ]
        
        trainingManager?.startTraining(userData: userData)
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
    
    /// Connect to platform (legacy method for backward compatibility)
    /// - Parameter platform: Platform to connect to
    public func connectToPlatform(_ platform: Platform) {
        print("🔗 [OnboardingCoordinator] Connecting to platform: \(platform.displayName)")
        
        // This method can be used for non-OAuth platforms or additional setup
        // For OAuth platforms, the connection is handled by the webview flow
        
        switch platform.authMethod {
        case .oauth:
            print("ℹ️ [OnboardingCoordinator] OAuth platforms handled by webview")
        case .nativeSDK:
            print("ℹ️ [OnboardingCoordinator] Native SDK platforms need additional setup")
        }
    }
} 