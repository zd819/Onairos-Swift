# Changelog

All notable changes to the Onairos Swift SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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