# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Run app: `flutter run`
- Run tests: `flutter test`
- Run specific test: `flutter test test/widget_test.dart`
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`
- Build for web: `flutter build web`

## Code Style Guidelines
- Follow Flutter standard linting rules (flutter_lints package)
- Import order: dart, flutter, external packages, relative imports
- Use camelCase for variables/methods, PascalCase for classes/enums
- Prefer using const constructors when possible
- Wrap widgets in Semantics for accessibility
- Use Provider for state management
- Handle errors with try/catch blocks and show user-friendly messages
- Follow Material Design guidelines for UI components
- Use responsive layouts that work on all device sizes