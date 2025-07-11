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
        
        // Force light mode for the entire modal
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
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
        containerView.layer.cornerRadius = 28
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        containerView.clipsToBounds = false // Ensure shadows are visible
        view.addSubview(containerView)
        
        // Add drag handle indicator at the top
        setupDragHandle()
        
        setupConstraints()
        setupGestureRecognizers()
    }
    
    /// Setup drag handle indicator
    private func setupDragHandle() {
        let dragHandle = UIView()
        dragHandle.backgroundColor = .systemGray4
        dragHandle.layer.cornerRadius = 2.5
        containerView.addSubview(dragHandle)
        
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dragHandle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dragHandle.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5)
        ])
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
        print("🔍 [DEBUG] OnairosModalController.showCurrentStep called for step: \(state.currentStep)")
        
        // Remove current step view controller
        if let currentStepViewController = currentStepViewController {
            print("🔍 [DEBUG] Removing previous step view controller")
            currentStepViewController.willMove(toParent: nil)
            currentStepViewController.view.removeFromSuperview()
            currentStepViewController.removeFromParent()
        }
        
        // Create new step view controller
        let stepViewController = createStepViewController(for: state.currentStep)
        currentStepViewController = stepViewController
        
        print("🔍 [DEBUG] Created new step view controller: \(type(of: stepViewController))")
        
        // Add as child view controller
        addChild(stepViewController)
        containerView.addSubview(stepViewController.view)
        
        // Setup constraints (add top padding for drag handle)
        stepViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stepViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stepViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stepViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        stepViewController.didMove(toParent: self)
        print("🔍 [DEBUG] Step view controller setup completed")
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
        // Only allow dismissal if not currently loading
        guard !state.isLoading else {
            print("🔍 [DEBUG] Ignoring background tap - currently loading")
            return
        }
        
        // Show confirmation before dismissing to prevent accidental cancellation
        let alert = UIAlertController(
            title: "Cancel Onboarding?",
            message: "Are you sure you want to cancel the onboarding process?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue Onboarding", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancel Onboarding", style: .destructive) { _ in
            self.coordinator?.cancelOnboarding()
        })
        
        present(alert, animated: true)
    }
    
    /// Handle pan gesture for swipe down to dismiss
    @objc private func panGesture(_ gesture: UIPanGestureRecognizer) {
        // Only allow swipe dismiss if not currently loading
        guard !state.isLoading else {
            print("🔍 [DEBUG] Ignoring swipe gesture - currently loading")
            return
        }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        // CRITICAL: Protect against NaN values from gesture calculations
        guard !translation.y.isNaN && !translation.y.isInfinite &&
              !velocity.y.isNaN && !velocity.y.isInfinite else {
            print("🚨 [ERROR] Invalid gesture values - translation.y: \(translation.y), velocity.y: \(velocity.y)")
            return
        }
        
        switch gesture.state {
        case .changed:
            // Only allow downward movement
            if translation.y > 0 {
                // CRITICAL: Protect CGAffineTransform from NaN values
                let transformValue = translation.y
                guard !transformValue.isNaN && !transformValue.isInfinite else {
                    print("🚨 [ERROR] Invalid transform value: \(transformValue)")
                    return
                }
                
                containerView.transform = CGAffineTransform(translationX: 0, y: transformValue)
                
                // Adjust background opacity based on translation
                let progress = min(translation.y / 200, 1.0)
                guard !progress.isNaN && !progress.isInfinite else {
                    print("🚨 [ERROR] Invalid progress value: \(progress)")
                    return
                }
                
                let newAlpha = 1.0 - (progress * 0.5)
                guard !newAlpha.isNaN && !newAlpha.isInfinite else {
                    print("🚨 [ERROR] Invalid alpha value: \(newAlpha)")
                    return
                }
                
                backgroundOverlay.alpha = newAlpha
            }
            
        case .ended, .cancelled:
            // Determine if should dismiss based on translation and velocity
            let shouldDismiss = translation.y > 150 || velocity.y > 800  // Higher threshold
            
            if shouldDismiss {
                // Show confirmation before dismissing to prevent accidental cancellation
                let alert = UIAlertController(
                    title: "Cancel Onboarding?",
                    message: "Are you sure you want to cancel the onboarding process?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Continue Onboarding", style: .cancel) { _ in
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
                })
                
                alert.addAction(UIAlertAction(title: "Cancel Onboarding", style: .destructive) { _ in
                    self.coordinator?.cancelOnboarding()
                })
                
                // Reset position first, then show alert
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: [.curveEaseOut],
                    animations: {
                        self.containerView.transform = .identity
                        self.backgroundOverlay.alpha = 1.0
                    },
                    completion: { _ in
                        self.present(alert, animated: true)
                    }
                )
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