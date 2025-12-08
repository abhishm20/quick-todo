# Contributing to QuickTodo

Thank you for your interest in contributing to QuickTodo! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Be kind, constructive, and patient with others.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/QuickTodo.git
   cd QuickTodo
   ```
3. Open the project in Xcode:
   ```bash
   open QuickTodo.xcodeproj
   ```

## How to Contribute

### Types of Contributions

- **Bug fixes**: Found a bug? Submit a fix!
- **Features**: Have an idea? Propose it first via an issue
- **Documentation**: Improvements to docs are always welcome
- **Tests**: Help increase test coverage

### Contribution Workflow

1. Check existing issues to avoid duplicates
2. Create an issue for significant changes before starting work
3. Fork and create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

### Requirements

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Swift 5.9+

### Building

1. Open `QuickTodo.xcodeproj` in Xcode
2. Select the QuickTodo scheme
3. Press `⌘+R` to build and run

### Testing

```bash
# Run tests from Xcode
⌘+U

# Or from command line
xcodebuild test -scheme QuickTodo -destination 'platform=macOS'
```

## Code Style

### General Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Keep functions small and focused
- Prefer clarity over brevity

### File Organization

Use `// MARK:` comments to organize code:

```swift
// MARK: - Properties

// MARK: - Lifecycle

// MARK: - Public Methods

// MARK: - Private Helpers
```

### Documentation

Add doc comments for public APIs:

```swift
/// Adds a new todo with the given text.
///
/// - Parameter text: The todo text content
/// - Returns: The created todo
@discardableResult
func addTodo(text: String) -> Todo {
    // ...
}
```

### Naming Conventions

- **Types**: `UpperCamelCase` (e.g., `TodoStore`, `ContentView`)
- **Methods/Properties**: `lowerCamelCase` (e.g., `addTodo`, `isCompleted`)
- **Constants**: `lowerCamelCase` for instance, `UPPER_SNAKE_CASE` for global

### SwiftUI Best Practices

- Extract reusable views into separate files
- Use `@StateObject` for owned objects, `@EnvironmentObject` for shared
- Keep views small and composable

## Pull Request Process

### Before Submitting

1. [ ] Code compiles without warnings
2. [ ] All tests pass
3. [ ] New code has appropriate documentation
4. [ ] Commit messages are clear and descriptive

### PR Guidelines

1. **Title**: Clear, concise description of the change
2. **Description**: Explain what and why (not how)
3. **Size**: Keep PRs focused; split large changes into smaller PRs
4. **Tests**: Include tests for new functionality

### PR Template

```markdown
## Summary
Brief description of the changes

## Changes
- List of specific changes

## Testing
How was this tested?

## Screenshots (if applicable)
```

### Review Process

1. Maintainers will review your PR
2. Address any feedback
3. Once approved, a maintainer will merge

## Reporting Bugs

### Before Reporting

1. Update to the latest version
2. Check if the issue already exists
3. Gather relevant information

### Bug Report Template

Use the issue template or include:

- **Description**: Clear description of the bug
- **Steps to reproduce**: Numbered steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: macOS version, app version
- **Screenshots**: If applicable

## Requesting Features

### Before Requesting

1. Check if it's already planned (roadmap in README)
2. Search existing issues
3. Consider if it fits the project's scope

### Feature Request Template

- **Problem**: What problem does this solve?
- **Solution**: Describe your proposed solution
- **Alternatives**: Other solutions you considered
- **Additional context**: Mockups, examples, etc.

## Questions?

Feel free to open an issue for questions or reach out to maintainers.

---

Thank you for contributing to QuickTodo!
