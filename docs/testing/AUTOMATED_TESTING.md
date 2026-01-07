# BookBed Automated Testing Guide (v1.0)

**Last Updated**: 2024-07-30
**Scope**: Unit, Widget, and Integration tests for Flutter (Owner Dashboard + Widget) and Cloud Functions.

This document provides instructions for running the automated tests in the BookBed project. For manual testing procedures, refer to the [Pre-Production Testing Plan](./PRE_PRODUCTION_TESTING_PLAN.md).

---

## 📋 Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Flutter Testing (Owner Dashboard & Widget)](#2-flutter-testing-owner-dashboard--widget)
   - [Running All Tests](#21-running-all-tests)
   - [Running a Single Test File](#22-running-a-single-test-file)
   - [Viewing Test Coverage](#23-viewing-test-coverage)
   - [Troubleshooting Flutter Tests](#24-troubleshooting-flutter-tests)
3. [Cloud Functions Testing](#3-cloud-functions-testing)
   - [Setup](#31-setup)
   - [Running All Tests](#32-running-all-tests)
   - [Running Tests in Watch Mode](#33-running-tests-in-watch-mode)
   - [Viewing Test Coverage](#34-viewing-test-coverage)
4. [Continuous Integration (CI)](#4-continuous-integration-ci)

---

## 1. Prerequisites

Before running any tests, ensure you have completed the full project setup as described in `docs/setup.md`.

**Key requirements**:
- Flutter SDK (v3.x+)
- Node.js (v18+)
- Firebase CLI (v13.x+)
- All Flutter and NPM dependencies installed (`flutter pub get`, `cd functions && npm install`)

---

## 2. Flutter Testing (Owner Dashboard & Widget)

Our Flutter tests are located in the `test/` directory and follow the standard Flutter testing framework, including unit, widget, and integration tests.

### 2.1 Running All Tests

To run all automated tests for the Flutter applications, execute the following command from the root of the repository:

```bash
flutter test
```

This command will discover and run all files ending in `_test.dart` within the `test/` directory.

### 2.2 Running a Single Test File

If you want to run tests for a specific file, you can provide the path to that file:

```bash
# Example: Run tests for the booking confirmation screen
flutter test test/features/widget/presentation/screens/booking_confirmation_screen_test.dart
```

### 2.3 Viewing Test Coverage

We use the `test` command's built-in coverage generation.

1.  **Generate Coverage Data**:
    Run the test command with the `--coverage` flag. This creates a `coverage/lcov.info` file.

    ```bash
    flutter test --coverage
    ```

2.  **Generate HTML Report**:
    To view the coverage report in a more readable format, you can generate an HTML report. This requires the `lcov` package, which can be installed on macOS via Homebrew (`brew install lcov`) or on Linux via apt (`sudo apt-get install lcov`).

    ```bash
    # Generate the HTML report in a directory named 'coverage_report'
    genhtml coverage/lcov.info -o coverage_report
    ```

3.  **View the Report**:
    Open the generated `index.html` file in your browser.

    ```bash
    # On macOS
    open coverage_report/index.html

    # On Linux
    xdg-open coverage_report/index.html
    ```

### 2.4 Troubleshooting Flutter Tests

-   **Generated Files Out of Date**: If you see errors related to `.g.dart` or `.freezed.dart` files, it's likely the generated code is stale. Run the build runner to regenerate them:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
-   **Missing Dependencies**: Ensure you've run `flutter pub get` after any `pubspec.yaml` changes.

---

## 3. Cloud Functions Testing

Our Cloud Functions tests are located in the `functions/test/` directory and use the Jest testing framework.

### 3.1 Setup

All commands for Cloud Functions tests must be run from within the `functions/` directory.

```bash
cd functions
```

Ensure all dependencies, including development dependencies, are installed:

```bash
npm install
```

### 3.2 Running All Tests

To run all Jest tests for the Cloud Functions, use the `test` script defined in `package.json`.

```bash
# From within the functions/ directory
npm test
```

This command will run all files ending in `.test.ts` or `.spec.ts` inside the `functions/test/` directory.

### 3.3 Running Tests in Watch Mode

For active development, you can run Jest in "watch" mode. This will automatically re-run tests when a file is changed.

```bash
# From within the functions/ directory
npm test -- --watch
```

### 3.4 Viewing Test Coverage

The `test` script is pre-configured to generate coverage information.

1.  **Generate Coverage Data**:
    The `--coverage` flag is included by default in the `npm test` script. After running the tests, a `coverage/` directory will be created inside `functions/`.

2.  **View the Report**:
    The report is generated in multiple formats. The most accessible is the HTML report.

    ```bash
    # On macOS
    open coverage/lcov-report/index.html

    # On Linux
    xdg-open coverage/lcov-report/index.html
    ```

**Note on Test Coverage**: The current test coverage for Cloud Functions is very low. This is a known issue and is being actively improved.

---

## 4. Continuous Integration (CI)

Our CI pipeline (e.g., GitHub Actions) automatically runs all the tests mentioned above on every pull request and push to the main branch.

**CI Commands**:
-   `flutter analyze`
-   `flutter test`
-   `cd functions && npm install && npm test`

A pull request cannot be merged unless all tests and analysis steps pass. This ensures that new changes do not break existing functionality.
