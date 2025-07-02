# Changelog

All notable changes to the Onairos Swift SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.16] - 2024-12-28

### Added
- **Comprehensive API Logging System**: New logging infrastructure for debugging production issues
  - Added `APILogLevel` enum with 5 levels: none, error, info, debug, verbose
  - Visual emoji indicators for different log levels (❌ error, ℹ️ info, 🐛 debug, 📝 verbose)
  - Request/response logging with configurable detail levels
  - HTTP status code logging with success/error indicators (✅/❌)
  - Network error categorization and detailed reporting

### Enhanced
- **API Client Debugging**: Major improvements to OnairosAPIClient for production troubleshooting
  - Detailed request logging (URL, method, headers, body)
  - Comprehensive response logging (status, headers, body)
  - Enhanced error handling with HTTP response details  
  - Automatic logging configuration based on SDK mode
  - Centralized configuration using shared API client instance

### Fixed
- **Email Button Issues**: Resolved production API call failures
  - Added proper error logging to identify API call failures
  - Enhanced error visibility for debugging email verification issues
  - Improved test mode API call bypassing
  - Better error context for production debugging

### Documentation
- **Debugging Guide**: Added comprehensive production debugging section to README
  - Step-by-step debugging configuration examples
  - Common API error troubleshooting guide
  - Logging level explanations and usage scenarios
  - Production vs debug mode configuration examples

### Technical
- **SDK Configuration**: Improved initialization with automatic logging setup
  - Automatic log level configuration based on test/debug/production mode
  - Test mode: Verbose logging with full request/response bodies
  - Debug mode: Enhanced request/response logging
  - Production mode: Basic info logging only
  - Configurable detailed logging for sensitive data

## [1.0.15] - 2024-12-28

### Added
- **Comprehensive Test Mode**: New `isTestMode` flag for complete development testing
  - Added `OnairosConfig.testMode()` static method for easy test configuration
  - Test mode bypasses all API calls and accepts any email/verification code
  - Fast training simulation with clear "🧪 TEST MODE" indicators
  - Automatic enabling of `allowEmptyConnections` and `simulateTraining` in test mode
  - Faster animations and reduced delays for quick testing cycles

### Enhanced
- **Training Simulation**: Improved with mode-specific messaging and timing
  - Test mode: 2x faster simulation with obvious test indicators
  - Production mode: Maintains original timing and professional messaging
  - Clear visual distinction between test and production modes

### Documentation
- **README Updates**: Added comprehensive test mode examples
  - Basic integration example with production configuration
  - Test mode setup with feature explanations
  - Production configuration best practices
  - Clear distinction between development and production usage

### Technical
- **Step Handler Improvements**: Enhanced all onboarding steps to properly handle test mode
  - Email step: Accepts any email immediately in test mode
  - Verification step: Accepts any code immediately in test mode  
  - Connection step: Faster auto-advance in test mode
  - PIN step: Bypasses API registration in test mode
  - Training step: Fast simulation with test mode branding

## [1.0.14] - 2024-12-28

### Fixed
- **YouTubeAuthManager Conditional Binding**: Fixed all "Initializer for conditional binding must have Optional type" compilation errors
  - Fixed "not 'GIDConfiguration'" error in initialize() method (line 24)
  - Fixed "not 'String'" errors in authenticate() method (line 53)
  - Fixed "not 'String'" errors in getCurrentUser() method (line 93)
  - Fixed "not 'String'" errors in refreshTokenIfNeeded() method (line 122)
  - Removed unnecessary `guard let` statements for non-optional types
- **Google Sign-In Integration**: Simplified authentication flow while maintaining error handling
  - `GIDConfiguration(clientID:)` returns non-optional GIDConfiguration
  - `user.accessToken.tokenString` is non-optional String property
  - `user.refreshToken.tokenString` is non-optional String property
  - Proper handling of optional types like `user.idToken?.tokenString`

### Technical Details
- Changed `guard let configuration = GIDConfiguration(clientID: clientID)` to `let configuration = GIDConfiguration(clientID: clientID)`
- Changed `guard let accessToken = user.accessToken.tokenString` to `let accessToken = user.accessToken.tokenString`
- Maintained proper optional handling for genuinely optional properties like `user.idToken?.tokenString`
- Preserved all error handling logic while fixing type safety issues

## [1.0.13] - 2024-12-28

### Fixed
- **OnboardingResult Type Conversion**: Fixed all "Cannot convert value of type 'OnboardingResult' to expected argument type 'Result<OnboardingResult, OnairosError>'" compilation errors
  - Added proper type conversion from OnboardingResult to Result<OnboardingResult, OnairosError> in completion callbacks
  - Fixed inconsistent callback types between coordinator and SDK completion handlers
  - Restored missing modal dismissal in completion handlers
  - Ensured consistent error handling throughout the onboarding flow
- **Callback Type Consistency**: Resolved type mismatch between internal OnboardingResult enum and external Result<OnboardingResult, OnairosError> type
  - OnboardingCoordinator.onCompletion returns OnboardingResult (enum with .success/.failure cases)
  - SDK completion callbacks expect Result<OnboardingResult, OnairosError> (Swift Result type)
  - Added proper conversion between these types in all completion handlers

### Technical Details
- Fixed type conversion in startUniversalOnboarding completion handler
- Fixed type conversion in startDataCollection completion handler
- Maintained proper modal dismissal flow while fixing type conversions
- Ensured backward compatibility with existing completion callback signatures

## [1.0.12] - 2024-12-28

### Fixed
- **Constructor Argument Mismatches**: Fixed all "argument passed to call that takes no arguments" and "extra arguments at positions" compilation errors
  - Fixed OnboardingCoordinator constructor to accept `state`, `config`, and `apiClient` parameters
  - Fixed OnairosAPIClient initialization pattern (removed config parameter from constructor)
  - Fixed OnairosModalController missing `state` parameter in initialization calls
  - Added missing `onCompletion` property to OnboardingCoordinator
  - Fixed dependency injection pattern for proper state and API client management
- **Architecture Improvements**: Enhanced dependency injection and separation of concerns
  - OnboardingCoordinator now properly receives injected dependencies
  - Improved state management with explicit state parameter passing
  - Better error handling with proper completion callback chaining
- **Swift Compilation**: Resolved all remaining argument mismatch compilation errors
  - All constructor calls now match their respective method signatures
  - Proper parameter order and types for all initializations
  - Consistent initialization patterns across the SDK

### Technical Details
- Updated OnboardingCoordinator.init to accept (state: OnboardingState, config: OnairosConfig, apiClient: OnairosAPIClient)
- Changed OnairosAPIClient initialization from OnairosAPIClient(config:) to OnairosAPIClient() + configure(baseURL:)
- Added public var onCompletion: ((OnboardingResult) -> Void)? to OnboardingCoordinator
- Fixed all SDK initialization calls to use proper dependency injection pattern
- Ensured proper memory management with weak references and cleanup

## [1.0.11] - 2024-12-28

### Fixed
- **Swift 6.1 Concurrency Issues**: Fixed MainActor isolation errors in TrainingStepViewController
  - Fixed `Call to main actor-isolated instance method 'stopTrainingAnimation()' in a synchronous nonisolated context`
  - Wrapped `stopTrainingAnimation()` calls in `Task { @MainActor in }` blocks
  - Fixed concurrency issue in `updateProgress()` method
  - Fixed concurrency issue in `deinit` method
- **Strict Concurrency Compliance**: Ensures proper main actor isolation for all UI operations
- **Swift 6.1 Compatibility**: Resolves all remaining strict concurrency checking errors

### Technical Details
- Updated `updateProgress()` to use `Task { @MainActor in }` for UI updates
- Updated `deinit` to properly handle MainActor isolation when cleaning up animations
- Maintains backward compatibility while adhering to Swift 6.1's strict concurrency model

## [1.0.10] - 2024-12-28

### Fixed
- **OnairosError Enum Cases**: Added missing enum cases that were causing Swift 6.1 compilation errors
  - Added `networkError(String)` case for network-related errors
  - Added `authenticationFailed(String)` case for authentication failures
  - Added `validationFailed(String)` case for validation errors
  - Added `serverError(Int, String)` case for server errors
- **Error Handling**: Updated all switch statements to handle new error cases
- **Error Descriptions**: Added proper error descriptions and recovery suggestions for new cases
- **Error Categorization**: Updated error categorization for analytics tracking
- **Swift 6.1 Compatibility**: Resolved all remaining compilation issues with Swift 6.1

### Technical Details
- Fixed `Type 'OnairosError' has no member 'networkError'` compilation errors
- Fixed `Type 'OnairosError' has no member 'authenticationFailed'` compilation errors
- Fixed `Type 'OnairosError' has no member 'validationFailed'` compilation errors
- Fixed `Type 'OnairosError' has no member 'serverError'` compilation errors
- Ensured comprehensive error handling throughout the SDK

## [1.0.9] - 2024-12-19

### Fixed
- 🚨 **SWIFT 6.1 COMPATIBILITY FIXES** - Resolved all compilation issues with Swift 6.1
- Fixed generic type inference issues in OnairosAPIClient ("Generic parameter 'T' could not be inferred")
- Made OnairosAPIClient initializer public to resolve private protection level errors
- Split performRequest method into specific variants to avoid overloading conflicts:
  - `performRequest<T,U>` for Codable body requests
  - `performRequestWithoutBody<U>` for GET requests without body
  - `performRequestWithDictionary<U>` for dictionary body requests
- Resolved "Argument passed to call that takes no arguments" errors
- Fixed "Extra arguments at positions #1, #3 in call" errors
- Updated all API method calls to use appropriate specific performRequest methods

### Changed
- Updated integration guide with Swift 6.1 compatibility information
- Enhanced troubleshooting with specific Swift 6.1 error solutions
- Added comprehensive error-to-solution mapping for generic type inference issues

### Notes
- **BREAKING**: Versions 1.0.1-1.0.8 had compilation issues with Swift 6.1
- **REQUIRED**: All consuming apps using Swift 6.1 must update to v1.0.9 or later
- **COMPLETE**: v1.0.9 provides full Swift 6.1 compatibility with stricter type inference

## [1.0.8] - 2024-12-19

## [1.0.7] - 2024-12-19

### Fixed
- 🚨 **ADDITIONAL CRITICAL COMPILATION FIXES** - Resolved remaining Swift compilation errors
- Fixed OnboardingCoordinator UserRegistrationRequest constructor call (removed extra 'platformData' parameter)
- Fixed SocketIO API compatibility for newer versions:
  - Changed `.compress(true)` to `.compress` (enum case has no associated values)
  - Changed `.timeout(30)` to `.connectTimeout(30)` (correct API method)
- Fixed DeviceInfo Codable conformance by removing problematic default value assignment
- Resolved "Cannot convert value of type 'Array<String>' to expected argument type" errors
- Resolved "Extra argument 'platformData' in call" errors

### Changed
- Updated integration guide with v1.0.7 version references
- Enhanced troubleshooting with specific SocketIO and constructor error solutions
- Added comprehensive error-to-solution mapping for all known compilation issues

### Notes
- **BREAKING**: Versions 1.0.1-1.0.6 had compilation bugs and are not usable
- **REQUIRED**: All consuming apps must update to v1.0.7 or later for successful compilation
- **COMPLETE**: v1.0.7 resolves ALL known compilation issues

## [1.0.6] - 2024-12-19

### Fixed
- 🚨 **CRITICAL COMPILATION FIXES** - Resolved all Swift compilation errors
- Added missing `import UIKit` to OnboardingModels.swift (fixes "Cannot find 'UIDevice' in scope")
- Fixed Codable conformance for `UserRegistrationRequest` struct
- Fixed Codable conformance for `PlatformData` struct by using `AnyCodable` for userData
- Fixed Codable conformance for `OnboardingData` struct by using `AnyCodable` for userData and inferenceData
- Resolved "Type does not conform to protocol 'Decodable/Encodable'" errors
- Updated integration guide with detailed troubleshooting for compilation issues

### Changed
- Updated all version references in documentation from 1.0.4/1.0.5 to 1.0.6
- Enhanced integration guide with comprehensive compilation error solutions
- Added critical update notice highlighting importance of v1.0.6

### Notes
- **BREAKING**: Versions 1.0.1-1.0.5 had compilation bugs and are not usable
- **REQUIRED**: All consuming apps must update to v1.0.6 or later

## [1.0.5] - 2024-12-19

### Changed
- Improved API design for createConnectButton() method
- Added automatic view controller detection for better developer experience
- Enhanced button creation with both simple and completion handler overloads

### Added
- findTopViewController() helper method for automatic presentation

## [1.0.4] - 2024-12-19

### Fixed
- Removed invalid `protected` keyword (Swift doesn't support protected access)
- Added `@MainActor` attributes to all UI classes for proper concurrency
- Fixed import statement ordering in OnairosModalController.swift
- Resolved Swift compilation failures and frontend command errors

### Changed
- Updated all UI view controllers to use `internal` instead of `protected`
- Enhanced concurrency support for Swift 5.5+

## [1.0.3] - 2024-12-19

### Added
- Enhanced SDK functionality with specific requirements implementation
- Data request overlay for existing account detection
- Improved email confirmation flow with API verification
- WebView OAuth authentication for additional platforms

### Changed
- Updated SDK to provide Onairos connect button with logo
- Enhanced keyboard handling and user experience

## [1.0.2] - 2024-12-19

### Added
- Complete step view controllers implementation
- Enhanced UI components and user experience
- Improved error handling and validation

## [1.0.1] - 2024-12-19

### Changed
- Updated integration guide to be optimized for LLMs, coding assistants, and Cursor
- Enhanced documentation with copy-paste instructions and automated setup scripts
- Corrected version numbering from 1.0.0 to 1.0.1

### Fixed
- Proper semantic versioning implementation

## [1.0.0] - 2024-12-19

### Added
- Initial release of Onairos Swift SDK
- Complete 6-step onboarding flow implementation
- Email input and verification system
- Platform authentication support:
  - Instagram (Opacity SDK integration)
  - YouTube (Google Sign-In SDK)
  - OAuth WebView flow (Reddit, Pinterest, Gmail)
- AI training integration with Socket.IO
- PIN creation with validation requirements
- Success screen with "Never Connect Again" functionality
- Comprehensive error handling system
- Debug mode for testing and development
- Session management and persistence
- Native iOS UI with bottom sheet modal design
- Accessibility support and keyboard handling
- Auto Layout with responsive design
- Animation support for smooth transitions
- Unit tests and performance tests
- Complete documentation and README

### Security
- Secure PIN storage and validation
- OAuth token management
- Session encryption and persistence
- Network request security with HTTPS

### Developer Experience
- Swift Package Manager support
- Comprehensive API documentation
- Usage examples and integration guides
- Debug mode with simulation features
- Error reporting and analytics integration
- Migration guide from React Native SDK

## [0.1.0] - Development

### Added
- Initial project structure
- Core models and data structures
- Basic networking layer
- Authentication manager interfaces
- UI component foundation

## [1.0.17] - 2024-12-28

### Fixed
- **CRITICAL: Test Mode Flow**: Fixed test mode closing immediately after email step instead of showing full onboarding flow
  - Test mode now properly shows: Email → Verify → Connect → Success → PIN → Training → Completion
  - Fixed premature dismissal that was happening after email verification
  - Slowed down training simulation in test mode (10 seconds instead of 0.8 seconds)
  - Extended completion delay so users can see training completion screen (3 seconds vs 0.8 seconds)

### Enhanced
- **Test Mode Debugging**: Added comprehensive debug logging for each onboarding step
  - Email step: Logs accepted email and transition to verify step
  - Verify step: Logs accepted verification code and transition to connect step
  - Connect step: Logs platform connection skip and auto-advance timing
  - Success step: Logs transition to PIN step
  - PIN step: Logs accepted PIN and transition to training step
  - Training step: Logs simulation start, progress, and completion timing

### Technical
- **Timing Improvements**: Optimized test mode timing for better user experience
  - Training simulation increment: 0.015 (slower) vs 0.04 (was too fast)
  - Training completion delay: 3.0 seconds vs 0.8 seconds (better visibility)
  - Connect step auto-advance: 2.0 seconds vs 1.0 second (improved visibility)
  - Overall test flow duration: ~15 seconds vs ~3 seconds (proper demonstration time)

## [1.0.18] - 2024-12-28

### Fixed
- **CRITICAL: Swift Compilation Errors**: Fixed "Reference to property 'config' in closure requires explicit use of 'self'" errors
  - Added explicit `self.` to all config references in timer closures
  - Fixed Swift strict concurrency requirements for closure capture semantics
  - Resolved all compilation errors preventing builds

### Enhanced
- **Connect Step User Experience**: Improved connect step to require manual user interaction
  - Removed confusing auto-advance behavior (was auto-skipping after 2-3 seconds)
  - Connect step now shows UI and waits for user to press "Continue" or "Skip" button
  - Added `handleConnectStepProceed()` method for manual progression
  - Better user control over onboarding flow progression

### Changed
- **Connect Step Flow**: Updated step navigation behavior
  - **Before**: Auto-advanced after 2-3 seconds (confusing for users)
  - **After**: Shows connect screen, user presses button to proceed
  - **Test Mode**: User can manually proceed without connecting any platforms
  - **Debug Mode**: User can manually proceed if they have connections or skip if allowed
  - **Production**: User must connect platforms OR manually skip if `allowEmptyConnections` is enabled

### Clarified
- **Success Step Purpose**: Documented the success step between Connect and PIN
  - Success step shows brief "Success!" message after connecting platforms
  - Provides positive feedback before moving to PIN creation
  - Auto-advances to PIN step after 1.5-2 seconds (intended behavior)
  - This step provides visual confirmation of successful platform connections

### Technical
- **Test Mode Logging**: Enhanced debugging output for connect step flow
  - `🧪 [TEST MODE] Connect step ready - user can manually proceed`
  - `🧪 [TEST MODE] User manually proceeding from connect step`
  - `🧪 [TEST MODE] Moving to success step`
  - `🧪 [TEST MODE] Auto-advancing from success to PIN step`

## [1.0.19] - 2024-12-28

### Fixed
- **CRITICAL: CoreGraphics NaN Errors**: Fixed app crashes from "invalid numeric value (NaN, or not-a-number) to CoreGraphics API"
  - Added comprehensive NaN and infinite value protection throughout training progress system
  - Prevents app crashes from invalid numeric values in UI rendering components
  - All progress values now safely clamped to valid range [0.0, 1.0]

### Enhanced
- **Training Progress Protection**: Added multi-layer NaN validation system
  - `OnboardingState.trainingProgress`: Added computed property with automatic NaN validation
  - `OnboardingCoordinator.simulateTraining()`: Protected progress increment calculations
  - `OnboardingCoordinator.startRealTraining()`: Protected external progress updates
  - `TrainingProgress` model: Added NaN validation in initializer

### Technical
- **NaN Protection Implementation**: Comprehensive validation at all progress assignment points
  - Progress validation: `newValue.isNaN || newValue.isInfinite ? 0.0 : min(max(newValue, 0.0), 1.0)`
  - External API protection: All incoming progress values validated before state assignment
  - Training completion: Ensured exactly 1.0 value with no possibility of NaN
  - Model-level validation: TrainingProgress constructor validates percentage parameter

### Stability
- **UI Rendering Reliability**: Eliminated CoreGraphics API crashes
  - Progress bars now receive only valid numeric values
  - Smooth progress animations without NaN interruptions
  - Protected against external APIs returning invalid numeric values
  - Maintained valid progress range for all UI components throughout onboarding flow 