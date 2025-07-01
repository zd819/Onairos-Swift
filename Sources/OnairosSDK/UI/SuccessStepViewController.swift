import UIKit

/// Success step view controller with "Never Connect Again" message
public class SuccessStepViewController: BaseStepViewController {
    
    /// Success checkmark view
    private let checkmarkView = UIView()
    
    /// Progress indicator for auto-advance
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    /// Auto-advance timer
    private var autoAdvanceTimer: Timer?
    
    /// Progress timer for animation
    private var progressTimer: Timer?
    
    public override func configureStep() {
        super.configureStep()
        
        // Configure header
        titleLabel.text = "Never Connect Again!"
        subtitleLabel.text = "Your session will be saved for future use"
        
        // Hide buttons initially (will show after timer)
        primaryButton.isHidden = true
        secondaryButton.isHidden = true
        
        // Setup success UI
        setupSuccessUI()
        
        // Start auto-advance
        startAutoAdvance()
    }
    
    /// Setup success UI components
    private func setupSuccessUI() {
        // Checkmark view
        checkmarkView.backgroundColor = .systemGreen
        checkmarkView.layer.cornerRadius = 40
        
        // Add checkmark symbol
        let checkmarkLabel = UILabel()
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = .systemFont(ofSize: 32, weight: .bold)
        checkmarkLabel.textColor = .white
        checkmarkLabel.textAlignment = .center
        checkmarkView.addSubview(checkmarkLabel)
        
        // Progress view
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.0
        
        // Add to content stack
        contentStackView.addArrangedSubview(checkmarkView)
        contentStackView.addArrangedSubview(progressView)
        
        // Add explanation text
        let explanationLabel = UILabel()
        explanationLabel.text = "We'll remember your preferences so you won't need to connect your accounts again in the future."
        explanationLabel.font = .systemFont(ofSize: 16, weight: .regular)
        explanationLabel.textColor = .secondaryLabel
        explanationLabel.textAlignment = .center
        explanationLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(explanationLabel)
        
        // Setup constraints
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmarkView.heightAnchor.constraint(equalToConstant: 80),
            
            checkmarkLabel.centerXAnchor.constraint(equalTo: checkmarkView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: checkmarkView.centerYAnchor),
            
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        // Animate checkmark appearance
        animateCheckmarkAppearance()
    }
    
    /// Animate checkmark appearance
    private func animateCheckmarkAppearance() {
        checkmarkView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        checkmarkView.alpha = 0
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0.2,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: {
                self.checkmarkView.transform = .identity
                self.checkmarkView.alpha = 1.0
            }
        )
    }
    
    /// Start auto-advance timer
    private func startAutoAdvance() {
        let duration: TimeInterval = 3.0
        
        // Start progress animation
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let increment = Float(0.02 / duration)
            self.progressView.progress += increment
            
            if self.progressView.progress >= 1.0 {
                timer.invalidate()
                self.progressTimer = nil
            }
        }
        
        // Auto-advance after duration
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.autoAdvanceToNextStep()
        }
    }
    
    /// Auto-advance to next step
    private func autoAdvanceToNextStep() {
        // Show buttons briefly before advancing
        primaryButton.setTitle("Continue to PIN", for: .normal)
        primaryButton.isHidden = false
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.primaryButton.alpha = 1.0
            },
            completion: { _ in
                // Auto-advance after showing button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.coordinator?.proceedToNextStep()
                }
            }
        )
    }
    
    /// Stop auto-advance (if user interacts)
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
        
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Show buttons for manual control
        primaryButton.setTitle("Continue", for: .normal)
        secondaryButton.setTitle("Back", for: .normal)
        
        primaryButton.isHidden = false
        secondaryButton.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.primaryButton.alpha = 1.0
            self.secondaryButton.alpha = 1.0
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Add tap gesture to stop auto-advance
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    /// Handle view tap to stop auto-advance
    @objc private func viewTapped() {
        if autoAdvanceTimer != nil {
            stopAutoAdvance()
        }
    }
    
    public override func primaryButtonTapped() {
        stopAutoAdvance()
        super.primaryButtonTapped()
    }
    
    public override func secondaryButtonTapped() {
        stopAutoAdvance()
        super.secondaryButtonTapped()
    }
    
    deinit {
        autoAdvanceTimer?.invalidate()
        progressTimer?.invalidate()
    }
} 