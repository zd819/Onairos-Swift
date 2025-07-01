import UIKit
import Combine

/// Main modal controller for the onboarding flow
@MainActor
public class OnairosModalController: UIViewController {
    
    /// Coordinator reference
    private weak var coordinator: OnboardingCoordinator?
    
    /// Onboarding state
    private let state: OnboardingState
    
    /// Configuration
    private let config: OnairosConfig
    
    /// Container view for the modal content
    private let containerView = UIView()
    
    /// Background overlay
    private let backgroundOverlay = UIView()
    
    /// Current step view controller
    private var currentStepViewController: UIViewController?
    
    /// Container view bottom constraint for animations
    private var containerBottomConstraint: NSLayoutConstraint?
    
    /// Initialize modal controller
    /// - Parameters:
    ///   - coordinator: Onboarding coordinator
    ///   - state: Onboarding state
    ///   - config: SDK configuration
    public init(
        coordinator: OnboardingCoordinator,
        state: OnboardingState,
        config: OnairosConfig
    ) {
        self.coordinator = coordinator
        self.state = state
        self.config = config
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupObservers()
        showCurrentStep()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate container view up from bottom
        animateContainerIn()
    }
    
    /// Setup UI components
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Background overlay
        backgroundOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundOverlay.alpha = 0
        view.addSubview(backgroundOverlay)
        
        // Container view
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        view.addSubview(containerView)
        
        setupConstraints()
        setupGestureRecognizers()
    }
    
    /// Setup Auto Layout constraints
    private func setupConstraints() {
        backgroundOverlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Background overlay
            backgroundOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container view
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8)
        ])
        
        // Bottom constraint for animation
        containerBottomConstraint = containerView.topAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint?.isActive = true
    }
    
    /// Setup gesture recognizers
    private func setupGestureRecognizers() {
        // Tap gesture on background to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundOverlay.addGestureRecognizer(tapGesture)
        
        // Pan gesture for swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    /// Setup state observers
    private func setupObservers() {
        // Observe step changes
        state.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showCurrentStep()
            }
            .store(in: &cancellables)
        
        // Observe loading state
        state.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
    }
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Show current step view controller
    private func showCurrentStep() {
        // Remove current step view controller
        if let currentStepViewController = currentStepViewController {
            currentStepViewController.willMove(toParent: nil)
            currentStepViewController.view.removeFromSuperview()
            currentStepViewController.removeFromParent()
        }
        
        // Create new step view controller
        let stepViewController = createStepViewController(for: state.currentStep)
        currentStepViewController = stepViewController
        
        // Add as child view controller
        addChild(stepViewController)
        containerView.addSubview(stepViewController.view)
        
        // Setup constraints
        stepViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            stepViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stepViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stepViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        stepViewController.didMove(toParent: self)
    }
    
    /// Create step view controller for current step
    /// - Parameter step: Onboarding step
    /// - Returns: Step view controller
    private func createStepViewController(for step: OnboardingStep) -> UIViewController {
        switch step {
        case .email:
            return EmailStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        case .verify:
            return VerifyStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        case .connect:
            return ConnectStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        case .success:
            return SuccessStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        case .pin:
            return PINStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        case .training:
            return TrainingStepViewController(
                coordinator: coordinator,
                state: state,
                config: config
            )
        }
    }
    
    /// Update loading state UI
    /// - Parameter isLoading: Loading state
    private func updateLoadingState(_ isLoading: Bool) {
        // Update current step view controller if it supports loading state
        if let loadingCapable = currentStepViewController as? LoadingCapable {
            loadingCapable.setLoading(isLoading)
        }
    }
    
    /// Animate container view in from bottom
    private func animateContainerIn() {
        containerBottomConstraint?.isActive = false
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint?.isActive = true
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: {
                self.backgroundOverlay.alpha = 1
                self.view.layoutIfNeeded()
            }
        )
    }
    
    /// Animate container view out to bottom
    /// - Parameter completion: Completion handler
    private func animateContainerOut(completion: @escaping () -> Void) {
        containerBottomConstraint?.isActive = false
        containerBottomConstraint = containerView.topAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint?.isActive = true
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.backgroundOverlay.alpha = 0
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                completion()
            }
        )
    }
    
    /// Handle background tap
    @objc private func backgroundTapped() {
        coordinator?.cancelOnboarding()
    }
    
    /// Handle pan gesture for swipe down to dismiss
    @objc private func panGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            // Only allow downward movement
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
                
                // Adjust background opacity based on translation
                let progress = min(translation.y / 200, 1.0)
                backgroundOverlay.alpha = 1.0 - (progress * 0.5)
            }
            
        case .ended, .cancelled:
            // Determine if should dismiss based on translation and velocity
            let shouldDismiss = translation.y > 100 || velocity.y > 500
            
            if shouldDismiss {
                coordinator?.cancelOnboarding()
            } else {
                // Snap back to original position
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: [.curveEaseOut],
                    animations: {
                        self.containerView.transform = .identity
                        self.backgroundOverlay.alpha = 1.0
                    }
                )
            }
            
        default:
            break
        }
    }
    
    /// Dismiss modal with animation
    /// - Parameter completion: Completion handler
    public func dismissModal(completion: @escaping () -> Void) {
        animateContainerOut {
            self.dismiss(animated: false, completion: completion)
        }
    }
}

/// Protocol for view controllers that can show loading state
public protocol LoadingCapable {
    func setLoading(_ isLoading: Bool)
}