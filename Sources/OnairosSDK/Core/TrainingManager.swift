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
        
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress(true),
            .reconnects(true),
            .reconnectAttempts(3),
            .reconnectWait(2),
            .timeout(30)
        ])
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    /// Setup Socket.IO event handlers
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("TrainingManager: Socket connected")
            self?.isConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("TrainingManager: Socket disconnected")
            self?.isConnected = false
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("TrainingManager: Socket error: \(data)")
            self?.onError?(.socketConnectionFailed)
        }
        
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
    /// - Parameter userData: User data for training
    public func startTraining(userData: [String: Any]) {
        guard let socket = socket else {
            onError?(.socketConnectionFailed)
            return
        }
        
        // Connect if not connected
        if !isConnected {
            socket.connect()
            
            // Wait for connection before starting training
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.emitTrainingStart(userData: userData)
            }
        } else {
            emitTrainingStart(userData: userData)
        }
    }
    
    /// Emit training start event
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
    
    /// Handle training progress event
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
    /// - Parameter userData: User data (ignored in mock)
    public func startTraining(userData: [String: Any]) {
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