import 'package:flutter/material.dart';

/// Utility class to manage profile data refresh across the app
class ProfileRefresh {
  static final List<VoidCallback> _listeners = [];
  
  /// Add a listener for profile refresh events
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// Remove a listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  /// Notify all listeners to refresh profile data
  static void notifyRefresh() {
    for (VoidCallback listener in _listeners) {
      listener();
    }
  }
  
  /// Clear all listeners (useful for cleanup)
  static void clearListeners() {
    _listeners.clear();
  }
}
