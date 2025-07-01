import UIKit

/// AI training step view controller
public class TrainingStepViewController: BaseStepViewController {
    
    /// Training progress view
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    /// Progress percentage label
    private let progressLabel = UILabel()
    
    /// Training status label
    private let statusLabel = UILabel()
    
    /// Training animation view
    private let animationView = UIView()
    
    /// Animated dots for training indicator
    private var animationDots: [UIView] = []
    
    /// Animation timer
    private var animationTimer: Timer?
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Training Your AI"
        subtitleLabel.text = "Building your personalized model..."
        
        // Configure buttons
        primaryButton.setTitle("Cancel", for: .normal)
        primaryButton.backgroundColor = .systemRed
        secondaryButton.isHidden = true
        
        // Setup training UI
        setupTrainingUI()
        
        // Bind to state
        bindToState()
        
        // Start training animation
        startTrainingAnimation()
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
        
        // Animation view
        setupAnimationView()
        
        // Add to content stack
        contentStackView.addArrangedSubview(animationView)
        contentStackView.addArrangedSubview(progressLabel)
        contentStackView.addArrangedSubview(progressView)
        contentStackView.addArrangedSubview(statusLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalToConstant: 80),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    /// Setup training animation view
    private func setupAnimationView() {
        animationView.backgroundColor = .clear
        
        // Create animated dots
        let dotCount = 5
        let dotSize: CGFloat = 12
        let spacing: CGFloat = 16
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = spacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        for i in 0..<dotCount {
            let dot = UIView()
            dot.backgroundColor = .systemBlue
            dot.layer.cornerRadius = dotSize / 2
            dot.alpha = 0.3
            
            animationDots.append(dot)
            stackView.addArrangedSubview(dot)
            
            // Set fixed size
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize)
            ])
        }
        
        animationView.addSubview(stackView)
        
        // Center stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: animationView.centerYAnchor)
        ])
    }
    
    /// Start training animation
    private func startTrainingAnimation() {
        var currentDotIndex = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Reset all dots
            self.animationDots.forEach { $0.alpha = 0.3 }
            
            // Highlight current dot
            if currentDotIndex < self.animationDots.count {
                UIView.animate(withDuration: 0.2) {
                    self.animationDots[currentDotIndex].alpha = 1.0
                    self.animationDots[currentDotIndex].transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                } completion: { _ in
                    UIView.animate(withDuration: 0.1) {
                        self.animationDots[currentDotIndex].transform = .identity
                    }
                }
            }
            
            currentDotIndex = (currentDotIndex + 1) % self.animationDots.count
        }
    }
    
    /// Stop training animation
    private func stopTrainingAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Reset all dots
        animationDots.forEach { dot in
            dot.alpha = 0.3
            dot.transform = .identity
        }
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
        let percentage = Int(progress * 100)
        
        // Animate progress view
        UIView.animate(withDuration: 0.3) {
            self.progressView.progress = Float(progress)
        }
        
        // Update percentage label
        progressLabel.text = "\(percentage)%"
        
        // Update button when complete
        if progress >= 1.0 {
            stopTrainingAnimation()
            
            // Show completion animation
            showCompletionAnimation()
            
            // Update button
            primaryButton.setTitle("Complete", for: .normal)
            primaryButton.backgroundColor = .systemGreen
            
            // Auto-complete after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if self.state.trainingProgress >= 1.0 {
                    self.coordinator?.proceedToNextStep()
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
        // Change all dots to green
        animationDots.forEach { dot in
            UIView.animate(withDuration: 0.5) {
                dot.backgroundColor = .systemGreen
                dot.alpha = 1.0
                dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    dot.transform = .identity
                }
            }
        }
        
        // Add checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addCompletionCheckmark()
        }
    }
    
    /// Add completion checkmark
    private func addCompletionCheckmark() {
        let checkmarkLabel = UILabel()
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = .systemFont(ofSize: 32, weight: .bold)
        checkmarkLabel.textColor = .systemGreen
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.alpha = 0
        
        animationView.addSubview(checkmarkLabel)
        
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmarkLabel.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: animationView.centerYAnchor, constant: -20)
        ])
        
        // Animate checkmark appearance
        checkmarkLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: {
                checkmarkLabel.alpha = 1.0
                checkmarkLabel.transform = .identity
            }
        )
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
        stopTrainingAnimation()
    }
} 