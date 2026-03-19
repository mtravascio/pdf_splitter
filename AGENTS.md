# AGENTS.md - PDF Splitter Project

## Project Overview

This is a Flutter desktop application that splits PDF files based on names found in a CSV file. It uses the GetX state management library and supports Windows, macOS, and Linux.

## Build/Lint/Test Commands

### Flutter Commands
```bash
# Run the application
flutter run

# Build for release
flutter build

# Analyze code for errors and warnings
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with a specific name pattern
flutter test --name "Counter"

# Run tests in a specific directory
flutter test test/
```

### Platform-Specific Builds
```bash
# Build for macOS
flutter build macos

# Build for Linux
flutter build linux

# Build for Windows
flutter build windows
```

## Code Style Guidelines

### Analysis Options
The project uses `flutter_lints` package with default settings. Run `flutter analyze` to check for issues.

### Dart Style Rules
- Use `dart format` to format code before committing
- Enable `prefer_single_quotes` in `analysis_options.yaml` for cleaner code
- Avoid `print()` statements in production code; use the `LogController` instead

### Imports
Organize imports in the following order:
1. Dart SDK imports (`dart:io`, `dart:async`)
2. Flutter/Dart package imports (`package:flutter/...`, `package:csv/...`)
3. Local package imports (`package:pdf_splitter/...`)
4. Relative imports (last resort)

```dart
// Correct import order
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_splitter/logger_controller.dart';
```

### Naming Conventions
- **Classes**: PascalCase (`PdfSplitterController`, `LogController`)
- **Variables/Methods**: camelCase (`csvFilePath`, `pickCsvFile()`, `isProcessing`)
- **Private members**: leading underscore (`_message`, `_initialize()`)
- **Constants**: camelCase or SCREAMING_SNAKE_CASE based on context
- **Rx Variables** (GetX): use `.obs` suffix pattern

### Types
- Use explicit types rather than `var` when the type is not obvious
- Prefer `String`, `int`, `bool`, `double` over dynamic types
- Use `late` for deferred initialization when appropriate
- Use `dynamic` sparingly and only when necessary

### GetX Patterns
- Controllers extend `GetxController` and use `.obs` for reactive state
- Use `Obx()` widget to rebuild UI on reactive changes
- Use `Rx<T>` for nullable reactive types
- Initialize controllers with `Get.put(ControllerName())`

```dart
// Reactive state example
var isProcessing = false.obs;
String get message => _message.value;

// Controller initialization
final PdfSplitterController controller = Get.put(PdfSplitterController());
```

### Error Handling
- Use `try-catch` blocks for async operations
- Provide meaningful error messages
- Use `appError()` method from controller for logging errors
- Handle null-safety explicitly with `?` and `??` operators

```dart
try {
  final result = await someAsyncOperation();
} catch (e) {
  appError('Operation failed: $e');
  message = 'Error: $e';
}
```

### Widget Building
- Keep `build()` methods focused and readable
- Extract complex widgets into separate methods or classes
- Use `const` constructors where possible
- Prefer `Obx()` for reactive UI updates

### File Structure
```
lib/
├── main.dart           # App entry point and PdfSplitterController
├── logger_controller.dart   # Logging functionality
test/
├── widget_test.dart    # Widget tests
assets/
├── send_mail.vbs       # Windows email script
├── send_mail.sh        # Linux/macOS email script
```

## Architecture Notes

### State Management
The app uses GetX for:
- State management (reactive `.obs` variables)
- Dependency injection (`Get.put()`)
- Logging (via `LogController`)

### Key Classes
- `MyApp`: Root MaterialApp widget
- `PdfSplitterController`: Main business logic controller
- `PdfSplitter`: Main UI widget
- `LogController`: Centralized logging

### CSV Format
Expected CSV columns:
- Column 0: Page number (integer)
- Column 1: Name
- Column 2: Description (optional)
- Column 3: Directory (optional)
- Column 4: Subdirectory (optional)
- Column 5: Email address (optional, format: `from: email@example.com`)

### Logging
Use the `LogController` methods for all logging:
- `logInfo()` - General information messages
- `logDebug()` - Debug messages
- `logError()` - Error messages

Never commit code with `print()` statements in production paths.

## Testing Notes
- Widget tests use `WidgetTester` from `flutter_test`
- Use `testWidgets()` for integration tests
- Use `expect()` for assertions
