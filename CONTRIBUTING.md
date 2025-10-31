# Contributing to Synheart Emotion

We welcome contributions to the Synheart Emotion library! This is a multi-platform monorepo containing SDKs for Flutter, Python, Android, and iOS. This document provides guidelines for contributing to the project.

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/synheart-emotion.git
   cd synheart-emotion
   ```
3. **Install dependencies** based on which SDK you're working on (see below)

## 📂 Repository Structure

This is a monorepo containing multiple SDKs:

```
synheart-emotion/
├── sdks/
│   ├── flutter/      # Flutter/Dart SDK
│   ├── python/       # Python SDK
│   ├── android/      # Android SDK (Kotlin)
│   └── ios/          # iOS SDK (Swift)
├── examples/         # Example applications
├── docs/             # Documentation (RFC, Model Cards)
├── models/           # Model definitions and assets
├── tools/            # Development tools
└── test/             # Cross-platform test suite
```

## 🧪 Development Setup by SDK

### Flutter SDK

```bash
cd sdks/flutter

# Copy models from root/models (if needed)
mkdir -p assets/ml
cp ../../models/*.json assets/ml/

# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format .
```

**Note**: Models are automatically copied during CI/CD. For local development, run the copy script: `./scripts/copy-models.sh`

### Python SDK

```bash
cd sdks/python

# Copy models from root/models (if needed)
mkdir -p src/synheart_emotion/data
cp ../../models/*.json src/synheart_emotion/data/

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -e .[dev]
```

**Note**: Models are automatically copied during CI/CD. For local development, run: `./scripts/copy-models.sh`

```bash
# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=synheart_emotion --cov-report=html

# Format code
black src/ tests/
isort src/ tests/

# Type checking
mypy src/

# Lint
flake8 src/ tests/
```

### Android SDK

```bash
cd sdks/android

# Build the project
./gradlew build

# Run tests
./gradlew test

# Clean build
./gradlew clean

# Generate documentation
./gradlew javadoc

# Lint check
./gradlew lint
```

### iOS SDK

```bash
cd sdks/ios

# Build package
swift build

# Run tests
swift test

# Generate Xcode project (optional)
swift package generate-xcodeproj

# Lint CocoaPods spec
pod lib lint SynheartEmotion.podspec
```

## 📝 Types of Contributions

### 🐛 Bug Reports

When reporting bugs, please include:

- **Description**: Clear description of the bug
- **SDK/Platform**: Which SDK (Flutter, Python, Android, iOS) and platform/OS
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: 
  - SDK version (e.g., Flutter 3.10.0, Python 3.11)
  - Device/platform details
  - OS version
- **Code Sample**: Minimal code that reproduces the issue
- **Logs**: Relevant error messages or stack traces

### ✨ Feature Requests

For new features, please include:

- **Use Case**: Why is this feature needed?
- **Proposed Solution**: How should it work?
- **Target SDKs**: Which SDKs should support this feature?
- **Alternatives**: Other solutions you've considered
- **Additional Context**: Any other relevant information

### 🔧 Code Contributions

#### Areas We Need Help With

1. **Model Improvements**
   - Better emotion detection accuracy
   - Support for additional emotion categories
   - Personalization algorithms
   - Model optimization for mobile devices

2. **Performance Optimizations**
   - Faster inference algorithms (< 5ms target)
   - Memory usage improvements
   - Battery optimization
   - Platform-specific optimizations

3. **Platform Integrations**
   - Better integration with wearable devices
   - Native code implementations
   - Platform-specific optimizations
   - New platform support (e.g., React Native, Web)

4. **Testing & Validation**
   - More comprehensive test coverage across all SDKs
   - Cross-platform integration tests
   - Performance benchmarks
   - Real-world validation studies

5. **Documentation**
   - API documentation improvements
   - Tutorials and guides for each SDK
   - Code examples for each platform
   - Architecture documentation

#### Code Style Guidelines

**General Principles:**
- Follow platform-specific conventions (Dart, Python PEP 8, Kotlin, Swift)
- Use meaningful variable and function names
- Add comprehensive documentation
- Include unit tests for new functionality
- Ensure all tests pass before submitting
- Maintain API consistency across SDKs

**Platform-Specific:**

- **Flutter/Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Python**: Follow [PEP 8](https://pep8.org/) and use type hints
- **Android/Kotlin**: Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- **iOS/Swift**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

#### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes** and ensure:
   - Code is properly formatted for the platform
   - All tests pass for the affected SDKs
   - No lint/analysis issues
   - Documentation is updated
   - CHANGELOG.md is updated (if applicable)
   - Cross-SDK API consistency is maintained

3. **Run relevant checks**:
   
   **For Flutter changes:**
   ```bash
   cd sdks/flutter
   flutter analyze
   flutter test
   ```
   
   **For Python changes:**
   ```bash
   cd sdks/python
   pytest tests/ -v
   black --check src/ tests/
   mypy src/
   ```
   
   **For Android changes:**
   ```bash
   cd sdks/android
   ./gradlew test
   ./gradlew lint
   ```
   
   **For iOS changes:**
   ```bash
   cd sdks/ios
   swift test
   swift build
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```
   
   Use conventional commit messages:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates/enhancements
   - `Refactor:` for code refactoring
   - `Docs:` for documentation changes
   - Include SDK prefix if relevant: `[Flutter]`, `[Python]`, `[Android]`, `[iOS]`

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub with:
   - Clear title and description
   - Reference any related issues (#issue-number)
   - Specify which SDK(s) are affected
   - Include screenshots for UI changes
   - Describe testing performed
   - Checklist of what was tested

## 🧪 Testing Guidelines

### Unit Tests

- Test all public APIs
- Include edge cases and error conditions
- Use descriptive test names
- Follow the AAA pattern (Arrange, Act, Assert)
- Maintain high test coverage (> 80%)

### Integration Tests

- Test complete workflows
- Verify performance requirements (< 5ms inference latency)
- Test with realistic data
- Cross-platform consistency tests

### Benchmarks

- Include performance benchmarks for new features
- Ensure performance targets are met
- Document performance characteristics
- Compare performance across platforms

### Cross-Platform Testing

When making changes that affect multiple SDKs:
- Test the same feature across all platforms
- Verify API consistency
- Check that outputs are equivalent
- Document any platform-specific differences

## 📚 Documentation

### Code Documentation

- Document all public APIs
- Include usage examples
- Explain complex algorithms
- Add inline comments for non-obvious code
- Use platform-appropriate documentation formats:
  - Dart: DartDoc comments
  - Python: Docstrings (Google or NumPy style)
  - Kotlin: KDoc comments
  - Swift: Documentation comments

### README Updates

- Update SDK-specific READMEs for new features
- Include code examples for each platform
- Update installation instructions
- Document breaking changes
- Update root README if repository structure changes

### Documentation Files

- **RFC Documents**: Located in `docs/` for architectural decisions
- **Model Cards**: Document model changes in `docs/MODEL_CARD.md`
- **CHANGELOG**: Update root `CHANGELOG.md` for all user-facing changes (single changelog for all SDKs)

## 🔒 Security & Privacy

When contributing, please ensure:

- No sensitive data is logged or stored
- Privacy-first design principles are followed
- Security best practices are implemented
- No hardcoded secrets or credentials
- On-device processing is maintained
- All data processing happens locally (no network calls)
- Compliance with privacy regulations (GDPR, HIPAA considerations)

## 🏷️ Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes (affect all SDKs)
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

**Important**: All SDKs must maintain version consistency. When releasing, all SDK versions should be updated to match.

### Release Checklist

- [ ] All tests pass across all SDKs
- [ ] Documentation is updated for affected SDKs
- [ ] Root CHANGELOG.md is updated (single changelog for all SDKs)
- [ ] Version is bumped in all SDKs:
  - `sdks/flutter/pubspec.yaml`
  - `sdks/python/pyproject.toml`
  - `sdks/android/build.gradle`
  - `sdks/ios/SynheartEmotion.podspec` and `Package.swift`
- [ ] Release notes are written
- [ ] Publishing workflows are tested (dry-run)
- [ ] Breaking changes are documented
- [ ] Migration guides are provided (if needed)

### Publishing Process

Releases are automated via GitHub Actions workflows:

1. Create a GitHub release with tag `vX.Y.Z`
2. All SDK publishing workflows trigger automatically
3. Verify packages appear in repositories
4. For Android: Manually close and release Maven Central staging repository

See `README.md` for publishing workflow details.

## 🔄 Maintaining API Consistency

Since this is a multi-platform SDK, maintain API consistency:

- **Core API**: Keep the same method names and signatures across platforms
- **Configuration**: Similar configuration options across SDKs
- **Error Handling**: Consistent error types and messages
- **Data Structures**: Equivalent data structures (Result objects, Config objects)
- **Behavior**: Same algorithm results across platforms

## 💬 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different perspectives and experiences
- Be patient with questions

### Communication

- Use clear, concise language
- Provide context for questions
- Be patient with responses
- Use appropriate channels:
  - **Issues**: Bug reports and feature requests
  - **Discussions**: Questions and general discussion
  - **Pull Requests**: Code review and discussion

## 🆘 Getting Help

- **Documentation**: 
  - Root `README.md` for overview
  - SDK-specific READMEs in `sdks/*/README.md`
  - Root `CHANGELOG.md` for version history (single file for all SDKs)
  - RFC documents in `docs/RFC-E1.1.md`
  - Model Card in `docs/MODEL_CARD.md`
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Pull Requests**: Ask questions in PR comments

## 📄 License

By contributing to Synheart Emotion, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be recognized in:

- Root README contributors section
- Root CHANGELOG.md for each release (single changelog for all SDKs)
- Release notes
- Project documentation

## 🎯 Quick Reference

### Testing Commands

| SDK | Test Command | Lint/Analyze |
|-----|-------------|--------------|
| Flutter | `flutter test` | `flutter analyze` |
| Python | `pytest tests/` | `mypy src/`, `black --check` |
| Android | `./gradlew test` | `./gradlew lint` |
| iOS | `swift test` | `swift build` (compiler checks) |

### File Locations

- **Tests**: 
  - Flutter: `test/` (root) or `sdks/flutter/test/`
  - Python: `sdks/python/tests/`
  - Android: `sdks/android/src/test/`
  - iOS: `sdks/ios/Tests/`
- **Source Code**: `sdks/{sdk}/src/` or `sdks/{sdk}/lib/`
- **Documentation**: `sdks/{sdk}/README.md` and root `docs/`

### Important Files to Update

- Root `CHANGELOG.md`: All user-facing changes (single file for all SDKs)
- `README.md`: Root repository structure and overview
- SDK READMEs: SDK-specific changes
- Version files: Must be updated together

Thank you for contributing to Synheart Emotion! 🎉
