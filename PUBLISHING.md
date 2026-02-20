# Publishing to pub.dev

Before publishing the DartX framework to the official Dart package repository ([pub.dev](https://pub.dev)), the following technical and quality requirements must be met.

## 1. Metadata Verification

Ensure the `pubspec.yaml` contains all necessary metadata for public listing:

- **name**: `dartx` (Verify availability)
- **version**: Increment following [Semantic Versioning](https://semver.org/) (e.g., `0.1.0`).
- **description**: A clear, technical summary of the framework.
- **homepage**: Link to the GitHub repository.
- **issue_tracker**: Link to the GitHub issues page.
- **documentation**: Link to the generated API documentation or hosted guides.

## 2. Formatting and Analysis

The code MUST follow the official Dart style guide. Execute the following commands in the project root:

```bash
# Format all files
dart format .

# Perform static analysis
dart analyze
```

There should be **zero** errors, warnings, or lints before proceeding.

## 3. API Documentation Generation

Generate the static HTML documentation to verify that all public APIs are properly documented:

```bash
# Install dartdoc if not present
dart pub global activate dartdoc

# Generate documentation
dart doc .
```

Review the generated files in the `doc/api` directory.

## 4. Dry Run

Validate the package for publishing without actually uploading it:

```bash
dart pub publish --dry-run
```

Pay close attention to any warnings regarding file sizes, missing files, or license issues.

## 5. Deployment

Once all checks pass, publish the package:

```bash
dart pub publish
```

---

## Technical Checklist for Future Versions

- [ ] Support for native compilation (`dart compile exe`).
- [ ] Comprehensive unit test suite with 90%+ code coverage.
- [ ] Inclusion of an `example/` directory with a complete "Hello World" app.
- [ ] Valid `LICENSE` file (e.g., MIT or BSD-3).
