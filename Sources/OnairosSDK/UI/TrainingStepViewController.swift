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
    

    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Creating Your Persona"
        subtitleLabel.text = "This will only take a moment. We're personalizing your experience."
        
        // Configure buttons
        primaryButton.setTitle("Cancel", for: .normal)
        primaryButton.backgroundColor = .systemRed
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
                
                // Auto-complete after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.state.trainingProgress >= 1.0 {
                        self.coordinator?.proceedToNextStep()
                    }
                }
            }
        }
    }
    
    /// Update status text
    /// - Parameter status: Status message
    private func updateStatus(_ status: String) {
        UIView.transition(
            with: statusLabel,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.statusLabel.text = status
            }
        )
    }
    
    /// Show completion animation
    private func showCompletionAnimation() {
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
        if state.trainingProgress >= 1.0 {
            // Complete training
            super.primaryButtonTapped()
        } else {
            // Cancel training
            coordinator?.cancelOnboarding()
        }
    }
    
    deinit {
        // Cleanup is handled automatically when view controller is deallocated
    }
} 