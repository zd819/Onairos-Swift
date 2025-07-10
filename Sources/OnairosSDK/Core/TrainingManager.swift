import Foundation
import SocketIO

/// Manages AI model training with Socket.IO connection
public class TrainingManager {
    
    /// Socket.IO client
    private var socket: SocketIOClient?
    
    /// Socket manager
    private var manager: SocketManager?
    
    /// Configuration
    private let config: OnairosConfig
    
    /// Training progress callback
    public var onProgress: ((TrainingProgress) -> Void)?
    
    /// Training completion callback
    public var onComplete: (() -> Void)?
    
    /// Training error callback
    public var onError: ((OnairosError) -> Void)?
    
    /// Connection status
    private var isConnected = false
    
    /// Socket ID for training requests
    private var socketId: String?
    
    /// User email for socket room joining
    private var userEmail: String?
    
    /// Initialize training manager
    /// - Parameter config: SDK configuration
    public init(config: OnairosConfig) {
        self.config = config
        setupSocket()
    }
    
    /// Setup Socket.IO connection
    private func setupSocket() {
        guard let url = URL(string: config.apiBaseURL) else {
            onError?(.configurationError("Invalid API URL"))
            return
        }
        
        // Get JWT token for authentication
        let jwtToken = getJWTToken()
        
        var socketConfig: [SocketIOClientOption] = [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(3),
            .reconnectWait(2)
        ]
        
        // Add JWT authentication if available
        if let token = jwtToken {
            socketConfig.append(.extraHeaders(["Authorization": "Bearer \(token)"]))
        }
        
        manager = SocketManager(socketURL: url, config: socketConfig)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    /// Get JWT token from keychain or storage
    private func getJWTToken() -> String? {
        // Try to get JWT token from keychain first (synchronous access to cached token)
        if let token = JWTTokenManager.shared.getCachedToken() {
            return token
        }
        
        // Fallback to UserDefaults (for development)
        return UserDefaults.standard.string(forKey: "onairos_jwt_token")
    }
    
    /// Setup Socket.IO event handlers
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("TrainingManager: Socket connected")
            self?.isConnected = true
            self?.socketId = self?.socket?.sid
            
            // Join user's socket room for training updates
            if let email = self?.userEmail {
                self?.socket?.emit("join", ["username": email])
                print("TrainingManager: Joined socket room for user: \(email)")
            }
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("TrainingManager: Socket disconnected")
            self?.isConnected = false
            self?.socketId = nil
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("TrainingManager: Socket error: \(data)")
            self?.onError?(.socketConnectionFailed)
        }
        
        // Backend schema events
        socket?.on(TrainingEvent.etaUpdate.rawValue) { [weak self] data, ack in
            self?.handleTrainingETAUpdate(data: data)
        }
        
        socket?.on(TrainingEvent.update.rawValue) { [weak self] data, ack in
            self?.handleTrainingUpdate(data: data)
        }
        
        socket?.on(TrainingEvent.completed.rawValue) { [weak self] data, ack in
            self?.handleTrainingCompleted(data: data)
        }
        
        socket?.on(TrainingEvent.inferenceCompleted.rawValue) { [weak self] data, ack in
            self?.handleInferenceCompleted(data: data)
        }
        
        socket?.on(TrainingEvent.modelStandby.rawValue) { [weak self] data, ack in
            self?.handleModelStandby(data: data)
        }
        
        // Legacy events for backward compatibility
        socket?.on(TrainingEvent.progress.rawValue) { [weak self] data, ack in
            self?.handleTrainingProgress(data: data)
        }
        
        socket?.on(TrainingEvent.complete.rawValue) { [weak self] data, ack in
            self?.handleTrainingComplete(data: data)
        }
        
        socket?.on(TrainingEvent.error.rawValue) { [weak self] data, ack in
            self?.handleTrainingError(data: data)
        }
    }
    
    /// Start AI training
    /// - Parameters:
    ///   - userData: User data for training
    ///   - email: User email for socket room joining
    ///   - connectedPlatforms: Connected social media platforms
    public func startTraining(userData: [String: Any], email: String, connectedPlatforms: [String: Any]) {
        guard let socket = socket else {
            onError?(.configurationError("Socket not initialized"))
            return
        }
        
        // Store user email for socket room joining
        self.userEmail = email
        
        // Connect if not connected
        if !isConnected {
            socket.connect()
            
            // Wait for connection before starting training
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.initiateTraining(userData: userData, connectedPlatforms: connectedPlatforms)
            }
        } else {
            initiateTraining(userData: userData, connectedPlatforms: connectedPlatforms)
        }
    }
    
    /// Initiate training via API call
    /// - Parameters:
    ///   - userData: User data for training
    ///   - connectedPlatforms: Connected social media platforms
    private func initiateTraining(userData: [String: Any], connectedPlatforms: [String: Any]) {
        guard let socketId = socketId, isConnected else {
            onError?(.socketConnectionFailed)
            return
        }
        
        // Start with initial progress
        let initialProgress = TrainingProgress(
            percentage: 0.0,
            status: "Initiating AI training..."
        )
        onProgress?(initialProgress)
        
        // Call the training API endpoint
        Task {
            let result = await OnairosAPIClient.shared.startAITraining(
                socketId: socketId,
                userData: userData,
                connectedPlatforms: connectedPlatforms
            )
            
            await MainActor.run {
                switch result {
                case .success(let response):
                    print("TrainingManager: Training initiated successfully: \(response)")
                    
                    // Update progress
                    let progress = TrainingProgress(
                        percentage: 0.1,
                        status: "Training started successfully..."
                    )
                    self.onProgress?(progress)
                    
                case .failure(let error):
                    print("TrainingManager: Training initiation failed: \(error)")
                    self.onError?(error)
                }
            }
        }
    }
    
    /// Emit training start event (legacy method for backward compatibility)
    /// - Parameter userData: User data for training
    private func emitTrainingStart(userData: [String: Any]) {
        guard let socket = socket, isConnected else {
            onError?(.socketConnectionFailed)
            return
        }
        
        var trainingData = userData
        trainingData["timestamp"] = Date().timeIntervalSince1970
        trainingData["platform"] = "iOS"
        
        socket.emit(TrainingEvent.start.rawValue, trainingData)
        
        // Start with initial progress
        let initialProgress = TrainingProgress(
            percentage: 0.0,
            status: "Connecting to AI training server..."
        )
        onProgress?(initialProgress)
    }
    
    /// Handle training ETA update event (backend schema)
    /// - Parameter data: ETA update data from socket
    private func handleTrainingETAUpdate(data: [Any]) {
        guard let etaData = data.first as? [String: Any] else {
            return
        }
        
        let eta = etaData["eta"] as? Int ?? 0
        let percent = etaData["percent"] as? Double ?? 0.0
        
        let progress = TrainingProgress(
            percentage: percent / 100.0, // Convert from 0-100 to 0-1
            status: "Training progress: \(Int(percent))% - ETA: \(eta)s"
        )
        
        onProgress?(progress)
    }
    
    /// Handle training update event (backend schema)
    /// - Parameter data: Training update data from socket
    private func handleTrainingUpdate(data: [Any]) {
        guard let updateData = data.first as? [String: Any] else {
            return
        }
        
        // Handle different types of updates
        if let success = updateData["success"] as? Bool, success {
            if let requiresConnections = updateData["requiresConnections"] as? Bool, requiresConnections {
                let error = OnairosError.trainingFailed("No social media connections found. Please connect at least one platform.")
                onError?(error)
                return
            }
        }
        
        if let error = updateData["error"] as? String {
            let onairosError = OnairosError.trainingFailed(error)
            onError?(onairosError)
            return
        }
        
        if let warning = updateData["warning"] as? String {
            let progress = TrainingProgress(
                percentage: 0.2,
                status: "Warning: \(warning) - Continuing training..."
            )
            onProgress?(progress)
            return
        }
        
        if let status = updateData["status"] as? String {
            let progress = TrainingProgress(
                percentage: 0.5,
                status: status
            )
            onProgress?(progress)
        }
    }
    
    /// Handle training completed event (backend schema)
    /// - Parameter data: Training completion data from socket
    private func handleTrainingCompleted(data: [Any]) {
        let progress = TrainingProgress(
            percentage: 0.9,
            status: "Training completed! Running final tests..."
        )
        onProgress?(progress)
    }
    
    /// Handle inference completed event (backend schema)
    /// - Parameter data: Inference completion data from socket
    private func handleInferenceCompleted(data: [Any]) {
        guard let inferenceData = data.first as? [String: Any] else {
            let progress = TrainingProgress(
                percentage: 0.95,
                status: "Inference completed!"
            )
            onProgress?(progress)
            return
        }
        
        let status = inferenceData["status"] as? String ?? "Inference completed!"
        let progress = TrainingProgress(
            percentage: 0.95,
            status: status
        )
        onProgress?(progress)
    }
    
    /// Handle model standby event (backend schema)
    /// - Parameter data: Model standby data from socket
    private func handleModelStandby(data: [Any]) {
        guard let standbyData = data.first as? [String: Any] else {
            completeTraining()
            return
        }
        
        if let completed = standbyData["completed"] as? Bool, completed {
            let message = standbyData["message"] as? String ?? "Model trained and ready!"
            let progress = TrainingProgress(
                percentage: 1.0,
                status: message,
                isComplete: true
            )
            onProgress?(progress)
            completeTraining()
        }
    }
    
    /// Complete training and clean up
    private func completeTraining() {
        onComplete?()
        
        // Disconnect after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.disconnect()
        }
    }
    
    /// Handle training progress event (legacy)
    /// - Parameter data: Progress data from socket
    private func handleTrainingProgress(data: [Any]) {
        guard let progressData = data.first as? [String: Any] else {
            return
        }
        
        let percentage = progressData["percentage"] as? Double ?? 0.0
        let status = progressData["status"] as? String ?? "Training in progress..."
        
        let progress = TrainingProgress(
            percentage: percentage / 100.0, // Convert from 0-100 to 0-1
            status: status
        )
        
        onProgress?(progress)
    }
    
    /// Handle training completion event
    /// - Parameter data: Completion data from socket
    private func handleTrainingComplete(data: [Any]) {
        let progress = TrainingProgress(
            percentage: 1.0,
            status: "Training complete!",
            isComplete: true
        )
        
        onProgress?(progress)
        onComplete?()
        
        // Disconnect after completion
        disconnect()
    }
    
    /// Handle training error event
    /// - Parameter data: Error data from socket
    private func handleTrainingError(data: [Any]) {
        let errorMessage = (data.first as? [String: Any])?["message"] as? String ?? "Training failed"
        let error = OnairosError.trainingFailed(errorMessage)
        
        onError?(error)
    }
    
    /// Disconnect from socket
    public func disconnect() {
        socket?.disconnect()
        isConnected = false
    }
    
    /// Clean up resources
    deinit {
        disconnect()
    }
}

/// Mock training manager for testing without Socket.IO
public class MockTrainingManager {
    
    /// Configuration
    private let config: OnairosConfig
    
    /// Training progress callback
    public var onProgress: ((TrainingProgress) -> Void)?
    
    /// Training completion callback
    public var onComplete: (() -> Void)?
    
    /// Training error callback
    public var onError: ((OnairosError) -> Void)?
    
    /// Initialize mock training manager
    /// - Parameter config: SDK configuration
    public init(config: OnairosConfig) {
        self.config = config
    }
    
    /// Start mock training
    /// - Parameters:
    ///   - userData: User data (ignored in mock)
    ///   - email: User email (ignored in mock)
    ///   - connectedPlatforms: Connected platforms (ignored in mock)
    public func startTraining(userData: [String: Any], email: String, connectedPlatforms: [String: Any]) {
        simulateTraining()
    }
    
    /// Simulate training progress
    private func simulateTraining() {
        var progress: Double = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            progress += 0.02
            
            var status = "Training your AI model..."
            if progress >= 0.3 && progress < 0.4 {
                status = "Analyzing your data patterns..."
            } else if progress >= 0.6 && progress < 0.7 {
                status = "Building neural network..."
            } else if progress >= 0.9 && progress < 1.0 {
                status = "Finalizing model parameters..."
            }
            
            let trainingProgress = TrainingProgress(
                percentage: min(progress, 1.0),
                status: status,
                isComplete: progress >= 1.0
            )
            
            self?.onProgress?(trainingProgress)
            
            if progress >= 1.0 {
                timer.invalidate()
                
                // Complete after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.onComplete?()
                }
            }
        }
    }
    
    /// Disconnect (no-op for mock)
    public func disconnect() {
        // No-op for mock implementation
    }
} 