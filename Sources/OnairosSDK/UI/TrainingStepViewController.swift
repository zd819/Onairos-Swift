import UIKit

/// AI training step view controller
@MainActor
public class TrainingStepViewController: BaseStepViewController {
    
    /// Training progress view
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    /// Progress percentage label
    private let progressLabel = UILabel()
    
    /// Training status label
    private let statusLabel = UILabel()
    
    /// Flag to track if training is being cancelled
    private var isCancelling = false
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Creating Your Persona"
        subtitleLabel.text = "This will only take a moment. We're personalizing your experience."
        
        // Configure buttons
        primaryButton.setTitle("Cancel", for: .normal)
        primaryButton.backgroundColor = .systemRed
        primaryButton.setTitleColor(.white, for: .normal)
        secondaryButton.isHidden = true
        
        // Setup training UI
        setupTrainingUI()
        
        // Bind to state
        bindToState()
    }
    
    /// Setup training UI components
    private func setupTrainingUI() {
        // Progress view
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        
        // Progress label
        progressLabel.text = "0%"
        progressLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        progressLabel.textColor = .label
        progressLabel.textAlignment = .center
        
        // Status label
        statusLabel.text = "Initializing..."
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        // Add to content stack (remove animation view, put progress label under progress bar)
        contentStackView.addArrangedSubview(progressView)
        contentStackView.addArrangedSubview(progressLabel)
        contentStackView.addArrangedSubview(statusLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    /// Bind to onboarding state
    private func bindToState() {
        // Observe training progress
        state.$trainingProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.updateProgress(progress)
            }
            .store(in: &cancellables)
        
        // Observe training status
        state.$trainingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateStatus(status)
            }
            .store(in: &cancellables)
    }
    
    /// Update progress UI
    /// - Parameter progress: Progress value (0.0 to 1.0)
    private func updateProgress(_ progress: Double) {
        // Don't update UI if we're cancelling
        guard !isCancelling else { return }
        
        // CRITICAL: Protect against NaN progress values
        guard !progress.isNaN && !progress.isInfinite else {
            print("🚨 [ERROR] Received NaN progress value: \(progress)")
            // Set to safe fallback value
            updateProgress(0.0)
            return
        }
        
        // Clamp progress to valid range
        let safeProgress = min(max(progress, 0.0), 1.0)
        let percentage = Int(safeProgress * 100)
        
        // CRITICAL: Protect Float conversion for UIProgressView
        let progressFloat = Float(safeProgress)
        guard !progressFloat.isNaN && !progressFloat.isInfinite else {
            print("🚨 [ERROR] Progress Float conversion resulted in NaN")
            return
        }
        
        // Animate progress view with safe value
        UIView.animate(withDuration: 0.3) {
            self.progressView.progress = progressFloat
        }
        
        // Update percentage label
        progressLabel.text = "\(percentage)%"
        
        // Update button when complete
        if safeProgress >= 1.0 {
            // Ensure we're on main actor for UI updates
            Task { @MainActor in
                // Show completion animation
                self.showCompletionAnimation()
                
                // Update button
                self.primaryButton.setTitle("Complete", for: .normal)
                self.primaryButton.backgroundColor = .systemGreen
                
                // Auto-complete after delay - but only if there's no error
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // Don't auto-advance if there's an insufficient training data error
                    let hasTrainingError = self.statusLabel.text?.contains("No negative interaction data found") == true ||
                                          self.statusLabel.text?.contains("You need to dislike/downvote content") == true ||
                                          self.statusLabel.text?.contains("0 disliked interactions") == true
                    
                    if self.state.trainingProgress >= 1.0 && !self.isCancelling && !hasTrainingError {
                        self.coordinator?.proceedToNextStep()
                    }
                }
            }
        }
    }
    
    /// Update status text
    /// - Parameter status: Status message
    private func updateStatus(_ status: String) {
        // Don't update status if we're cancelling
        guard !isCancelling else { return }
        
        UIView.transition(
            with: statusLabel,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.statusLabel.text = status
            }
        )
        
        // Check if this is an insufficient training data error
        if status.contains("No negative interaction data found") || 
           status.contains("You need to dislike/downvote content") ||
           status.contains("0 disliked interactions") {
            handleInsufficientTrainingDataError(status)
        }
    }
    
    /// Handle insufficient training data error - show briefly then navigate back to connect
    /// - Parameter errorMessage: The error message to display
    private func handleInsufficientTrainingDataError(_ errorMessage: String) {
        print("⚠️ [TRAINING] Insufficient training data detected - will navigate back to connect screen")
        
        // Make status label red to indicate error
        statusLabel.textColor = .systemRed
        
        // Update button to show error state
        primaryButton.setTitle("Need More Data", for: .normal)
        primaryButton.backgroundColor = .systemOrange
        primaryButton.isEnabled = false
        
        // Show error message briefly (3 seconds) then navigate back
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, !self.isCancelling else { return }
            
            print("🔄 [TRAINING] Navigating back to connect screen after insufficient training data")
            
            // Update UI to show transitioning
            self.statusLabel.text = "Taking you back to connect more data..."
            self.statusLabel.textColor = .systemBlue
            
            self.primaryButton.setTitle("Going Back...", for: .normal)
            self.primaryButton.backgroundColor = .systemBlue
            
            // Navigate back to connect step after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                
                // Reset to connect step while preserving current state
                self.coordinator?.goBackToConnectStep()
            }
        }
    }
    
    /// Show completion animation
    private func showCompletionAnimation() {
        // Don't show completion animation if we're cancelling
        guard !isCancelling else { return }
        
        // Check if there's an error in the current status before showing completion
        if statusLabel.text?.contains("No negative interaction data found") == true ||
           statusLabel.text?.contains("You need to dislike/downvote content") == true ||
           statusLabel.text?.contains("0 disliked interactions") == true {
            // Don't show completion animation if there's an error
            print("⚠️ [TRAINING] Not showing completion animation due to insufficient training data error")
            return
        }
        
        // Simple completion animation - just animate the progress bar to green
        UIView.animate(withDuration: 0.5) {
            self.progressView.progressTintColor = .systemGreen
        }
        
        // Update status to show completion
        statusLabel.text = "Persona created successfully!"
    }
    
    public override func setLoading(_ isLoading: Bool) {
        // Don't use base loading state for training step
        // Training has its own progress indication
    }
    
    public override func primaryButtonTapped() {
        print("🔍 [TRAINING] Primary button tapped - progress: \(state.trainingProgress)")
        
        if state.trainingProgress >= 1.0 {
            // Complete training
            print("✅ [TRAINING] Training complete - proceeding to next step")
            super.primaryButtonTapped()
        } else {
            // Cancel training
            print("❌ [TRAINING] User cancelled training")
            cancelTraining()
        }
    }
    
    /// Cancel the training process with user confirmation
    private func cancelTraining() {
        // Prevent multiple cancellation attempts
        guard !isCancelling else {
            print("⚠️ [TRAINING] Already cancelling, ignoring duplicate request")
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Cancel Training?",
            message: "Are you sure you want to cancel persona creation? You'll return to the PIN creation step.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue Training", style: .cancel) { _ in
            print("🔄 [TRAINING] User chose to continue training")
        })
        
        alert.addAction(UIAlertAction(title: "Go Back to PIN", style: .destructive) { [weak self] _ in
            self?.performCancellation()
        })
        
        present(alert, animated: true)
    }
    
    /// Perform the actual cancellation and return to PIN step
    private func performCancellation() {
        print("🚫 [TRAINING] Performing cancellation - returning to PIN step")
        
        // Set cancellation flag
        isCancelling = true
        
        // Update UI to show cancellation
        primaryButton.setTitle("Going Back...", for: .normal)
        primaryButton.backgroundColor = .systemGray
        primaryButton.isEnabled = false
        
        statusLabel.text = "Returning to PIN creation..."
        
        // Cancel with a slight delay to show the UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            print("🔙 [TRAINING] Going back to PIN step")
            
            // Ensure coordinator exists before calling
            if let coordinator = self.coordinator {
                coordinator.goBackToPreviousStep()
            } else {
                print("⚠️ [TRAINING] Coordinator is nil - cannot go back to PIN step")
                // Fallback: try to dismiss the modal directly
                if let presentingVC = self.presentingViewController {
                    presentingVC.dismiss(animated: true)
                }
            }
        }
    }
    
    deinit {
        print("🗑️ [TRAINING] TrainingStepViewController deallocated")
        // Cleanup is handled automatically when view controller is deallocated
    }
} 