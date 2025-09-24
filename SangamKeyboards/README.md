# Sangam Keyboards

Modern multi-language keyboard for iOS with intelligent predictions and clean architecture.

## Project Structure

- **SangamKeyboards/**: Main container app
- **SangamKeyboardsExtension/**: Keyboard extension with core logic
- **KeyboardCore/**: Shared framework for models and utilities
- **Tests/**: Unit and integration tests

## Architecture

Built with modern Swift concurrency patterns:
- Async input pipeline
- Actor-based components
- Thread-safe state management
- Debounced predictions

## Languages Supported

20+ languages including Tamil, Malayalam, Malay, Jawi, Punjabi, Hindi, Bengali, and more.

## Development

1. Open SangamKeyboards.xcodeproj in Xcode
2. Build and run the main app target
3. Test the keyboard in iOS Simulator

## Setup

Run the keyboard extension setup after installation to enable in iOS Settings.
