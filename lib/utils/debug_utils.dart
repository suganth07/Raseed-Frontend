import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Utility class to handle overflow and debug settings
class DebugUtils {
  /// Completely disable overflow indicators in debug mode
  static void disableOverflowIndicators() {
    if (kDebugMode) {
      // Override the debug paint method to prevent overflow indicators
      debugPaintSizeEnabled = false;
    }
  }

  /// Custom error widget builder that hides overflow errors
  static Widget customErrorWidgetBuilder(FlutterErrorDetails details) {
    // Check if this is an overflow error
    if (details.toString().toLowerCase().contains('overflow') ||
        details.toString().toLowerCase().contains('renderoverflow')) {
      // Return an invisible widget for overflow errors
      return const SizedBox.shrink();
    }
    
    // For other errors, show a clean error indicator in debug mode
    if (kDebugMode) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 16,
        ),
      );
    }
    
    // In release mode, hide all error widgets
    return const SizedBox.shrink();
  }

  /// Initialize debug settings
  static void initialize() {
    disableOverflowIndicators();
    
    // Set custom error widget builder
    ErrorWidget.builder = customErrorWidgetBuilder;
  }
}
