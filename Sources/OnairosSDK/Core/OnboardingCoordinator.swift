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
        modalController?.dismiss(animated: true) { [weak self] in
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
        guard state.validateCurrentStep() else {
            state.errorMessage = "Please complete the current step before proceeding."
            return
        }
        
        switch state.currentStep {
        case .email:
            handleEmailStep()
        case .verify:
            handleVerifyStep()
        case .connect:
            handleConnectStep()
        case .success:
            handleSuccessStep()
        case .pin:
            handlePINStep()
        case .training:
            handleTrainingComplete()
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
        state.isLoading = true
        state.errorMessage = nil
        
        // In test mode, accept any email immediately
        if config.isTestMode {
            print("🧪 [TEST MODE] Email step - accepting any email: \(state.email)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state.isLoading = false
                self?.state.currentStep = .verify
                print("🧪 [TEST MODE] Moving to verification step")
            }
            return
        }
        
        Task {
            let result = await apiClient.requestEmailVerification(email: state.email)
            
            await MainActor.run {
                state.isLoading = false
                
                switch result {
                case .success:
                    state.currentStep = .verify
                case .failure(let error):
                    if config.isDebugMode {
                        // In debug mode, allow proceeding even if email verification fails
                        state.currentStep = .verify
                    } else {
                        state.errorMessage = error.localizedDescription
                    }
                }
            }
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
                    if verified || config.isDebugMode {
                        state.currentStep = .connect
                    } else {
                        state.errorMessage = "Invalid verification code. Please try again."
                    }
                case .failure(let error):
                    if config.isDebugMode {
                        // In debug mode, allow proceeding with any code
                        state.currentStep = .connect
                    } else {
                        state.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    /// Handle platform connection step
    private func handleConnectStep() {
        if config.isTestMode {
            print("🧪 [TEST MODE] Connect step - skipping platform connections")
        }
        
        // In test mode, debug mode, or if empty connections are allowed, can proceed without connections
        if config.isTestMode || config.allowEmptyConnections || config.isDebugMode || !state.connectedPlatforms.isEmpty {
            state.currentStep = .success
            
            // Auto-advance after 3 seconds (2 seconds in test mode for visibility)
            let delay = config.isTestMode ? 2.0 : 3.0
            if config.isTestMode {
                print("🧪 [TEST MODE] Auto-advancing to success step in \(delay) seconds")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.handleSuccessStep()
            }
        } else {
            state.errorMessage = "Please connect at least one platform to continue."
        }
    }
    
    /// Handle success step (auto-advance)
    private func handleSuccessStep() {
        if config.isTestMode {
            print("🧪 [TEST MODE] Success step - moving to PIN step")
        }
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
    
    /// Connect to platform
    /// - Parameter platform: Platform to connect
    public func connectToPlatform(_ platform: Platform) {
        state.isLoading = true
        state.errorMessage = nil
        
        Task {
            do {
                let platformData = try await authenticatePlatform(platform)
                
                await MainActor.run {
                    state.isLoading = false
                    state.connectedPlatforms.insert(platform.rawValue)
                    connectedPlatformData[platform.rawValue] = platformData
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    if let onairosError = error as? OnairosError {
                        state.errorMessage = onairosError.localizedDescription
                    } else {
                        state.errorMessage = "Failed to connect to \(platform.displayName)"
                    }
                }
            }
        }
    }
    
    /// Authenticate with specific platform
    /// - Parameter platform: Platform to authenticate
    /// - Returns: Platform data
    private func authenticatePlatform(_ platform: Platform) async throws -> PlatformData {
        switch platform.authMethod {
        case .opacitySDK:
            return try await authenticateInstagram()
        case .nativeSDK:
            return try await authenticateYouTube()
        case .oauth:
            return try await authenticateOAuth(platform)
        }
    }
    
    /// Authenticate with Instagram using Opacity SDK
    /// - Returns: Instagram platform data
    private func authenticateInstagram() async throws -> PlatformData {
        // Placeholder - would use Opacity SDK when available
        throw OnairosError.opacitySDKRequired
        
        /*
        // Example implementation when Opacity SDK is available:
        let profile = try await InstagramAuthManager.shared.getProfile()
        return PlatformData(
            platform: "instagram",
            accessToken: profile.accessToken,
            refreshToken: nil,
            expiresAt: nil,
            userData: profile.userData
        )
        */
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
        state.trainingProgress = 0.0
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
        
        if config.isTestMode {
            print("🧪 [TEST MODE] Starting training simulation - will take ~10 seconds to complete")
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.state.trainingProgress += increment
            
            // Update status messages based on progress
            if config.isTestMode {
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
                self.state.trainingProgress = 1.0
                self.state.trainingStatus = config.isTestMode ? "🧪 TEST MODE: Training simulation complete!" : "Training complete!"
                
                // Longer completion delay in test mode so user can see the completion
                let completionDelay = config.isTestMode ? 3.0 : 1.5
                if config.isTestMode {
                    print("🧪 [TEST MODE] Training complete! Will finish in \(completionDelay) seconds")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                    if config.isTestMode {
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
                self?.state.trainingProgress = progress.percentage
                self?.state.trainingStatus = progress.status
            }
        }
        
        trainingManager?.onComplete = { [weak self] in
            Task { @MainActor in
                self?.state.trainingProgress = 1.0
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
} 