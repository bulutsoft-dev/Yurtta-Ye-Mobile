import 'package:flutter/foundation.dart';

/// Centralized logging utility for the YurttaYe app.
/// All print statements should be replaced with calls to this class.
/// In release mode, all logs are suppressed for better performance.
class AppLogger {
  static const String _tag = 'YurttaYe';

  /// Log a debug message (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      print('[$_tag][DEBUG] $message');
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      print('[$_tag][INFO] $message');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      print('[$_tag][WARNING] $message');
    }
  }

  /// Log an error message (only in debug mode)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[$_tag][ERROR] $message');
      if (error != null) {
        print('[$_tag][ERROR] Error: $error');
      }
      if (stackTrace != null) {
        print('[$_tag][ERROR] StackTrace: $stackTrace');
      }
    }
  }

  /// Log API-related messages
  static void api(String message) {
    if (kDebugMode) {
      print('[$_tag][API] $message');
    }
  }

  /// Log ad-related messages
  static void ad(String message) {
    if (kDebugMode) {
      print('[$_tag][AD] $message');
    }
  }

  /// Log notification-related messages
  static void notification(String message) {
    if (kDebugMode) {
      print('[$_tag][NOTIFICATION] $message');
    }
  }
}
