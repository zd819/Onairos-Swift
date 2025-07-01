import UIKit
import Combine

/// Base class for all onboarding step view controllers
@MainActor
public class BaseStepViewController: UIViewController, LoadingCapable {
    
    /// Coordinator reference
    protected weak var coordinator: OnboardingCoordinator?
    
    /// Onboarding state
    protected let state: OnboardingState
    
    /// Configuration
    protected let config: OnairosConfig
    
    /// Main scroll view for content
    protected let scrollView = UIScrollView()
    
    /// Content view inside scroll view
    protected let contentView = UIView()
    
    /// Header view for logo and title
    protected let headerView = UIView()
    
    /// Onairos logo image view
    protected let logoImageView = UIImageView()
    
    /// Step title label
    protected let titleLabel = UILabel()
    
    /// Step subtitle label
    protected let subtitleLabel = UILabel()
    
    /// Main content stack view
    protected let contentStackView = UIStackView()
    
    /// Footer view for buttons
    protected let footerView = UIView()
    
    /// Primary action button
    protected let primaryButton = UIButton(type: .system)
    
    /// Secondary action button
    protected let secondaryButton = UIButton(type: .system)
    
    /// Loading indicator
    protected let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    /// Error message label
    protected let errorLabel = UILabel()
    
    /// Combine cancellables
    protected var cancellables = Set<AnyCancellable>()
    
    /// Initialize base step view controller
    /// - Parameters:
    ///   - coordinator: Onboarding coordinator
    ///   - state: Onboarding state
    ///   - config: SDK configuration
    public init(
        coordinator: OnboardingCoordinator?,
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
        setupConstraints()
        setupObservers()
        configureStep()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Adjust for keyboard if needed
        registerForKeyboardNotifications()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unregisterForKeyboardNotifications()
    }
    
    /// Setup basic UI components
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        // Content view
        scrollView.addSubview(contentView)
        
        // Header view
        setupHeaderView()
        contentView.addSubview(headerView)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        contentView.addSubview(contentStackView)
        
        // Footer view
        setupFooterView()
        contentView.addSubview(footerView)
        
        // Error label
        setupErrorLabel()
        contentView.addSubview(errorLabel)
    }
    
    /// Setup header view components
    private func setupHeaderView() {
        // Logo image view
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "onairos-logo") // Placeholder
        logoImageView.backgroundColor = .systemBlue // Placeholder color
        logoImageView.layer.cornerRadius = 25
        headerView.addSubview(logoImageView)
        
        // Title label
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        // Subtitle label
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        headerView.addSubview(subtitleLabel)
    }
    
    /// Setup footer view components
    private func setupFooterView() {
        // Primary button
        primaryButton.backgroundColor = .systemBlue
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        primaryButton.layer.cornerRadius = 12
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        footerView.addSubview(primaryButton)
        
        // Secondary button
        secondaryButton.backgroundColor = .clear
        secondaryButton.setTitleColor(.systemBlue, for: .normal)
        secondaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        secondaryButton.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
        footerView.addSubview(secondaryButton)
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        footerView.addSubview(loadingIndicator)
    }
    
    /// Setup error label
    private func setupErrorLabel() {
        errorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
    }
    
    /// Setup Auto Layout constraints
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        footerView.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo, title, subtitle constraints
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Button and loading constraints
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 50),
            logoImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Content stack view
            contentStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Error label
            errorLabel.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Footer view
            footerView.topAnchor.constraint(greaterThanOrEqualTo: errorLabel.bottomAnchor, constant: 20),
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            footerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Primary button
            primaryButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            primaryButton.topAnchor.constraint(equalTo: footerView.topAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Secondary button
            secondaryButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            secondaryButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 12),
            secondaryButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor)
        ])
    }
    
    /// Setup state observers
    private func setupObservers() {
        // Observe error messages
        state.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showError(errorMessage)
            }
            .store(in: &cancellables)
        
        // Observe loading state
        state.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }
    
    /// Configure step-specific content (override in subclasses)
    open func configureStep() {
        // Override in subclasses
    }
    
    /// Primary button action (override in subclasses)
    @objc open func primaryButtonTapped() {
        coordinator?.proceedToNextStep()
    }
    
    /// Secondary button action (override in subclasses)
    @objc open func secondaryButtonTapped() {
        coordinator?.goBackToPreviousStep()
    }
    
    /// Show error message
    /// - Parameter message: Error message to display
    private func showError(_ message: String?) {
        if let message = message, !message.isEmpty {
            errorLabel.text = message
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }
    }
    
    /// Set loading state
    /// - Parameter isLoading: Loading state
    public func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            primaryButton.setTitle("", for: .normal)
            primaryButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            primaryButton.isEnabled = true
            // Restore button title in subclasses
        }
    }
    
    /// Register for keyboard notifications
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// Unregister from keyboard notifications
    private func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// Handle keyboard will show
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        let adjustedHeight = keyboardHeight - safeAreaBottom
        
        scrollView.contentInset.bottom = adjustedHeight
        scrollView.verticalScrollIndicatorInsets.bottom = adjustedHeight
        
        // Scroll to ensure input fields are visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToActiveInput()
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// Handle keyboard will hide
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// Scroll to active input field
    private func scrollToActiveInput() {
        // Find the first responder (active input field)
        if let activeField = findFirstResponder(in: contentStackView) {
            let fieldFrame = activeField.convert(activeField.bounds, to: scrollView)
            let visibleRect = CGRect(
                x: 0,
                y: fieldFrame.origin.y - 20,
                width: scrollView.bounds.width,
                height: fieldFrame.height + 40
            )
            scrollView.scrollRectToVisible(visibleRect, animated: true)
        }
    }
    
    /// Find first responder in view hierarchy
    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        
        return nil
    }
} 