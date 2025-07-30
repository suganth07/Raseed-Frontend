class LocalAuthService {
  static final Map<String, Map<String, dynamic>> _localUsers = {};
  static String? _currentUserId;
  
  // Get current user ID for local auth
  static String? get currentUserId => _currentUserId;
  
  // Check if user is logged in locally
  static bool get isLoggedIn => _currentUserId != null;

  /// Local sign up (for demo/testing purposes)
  static Future<Map<String, dynamic>> localSignUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      if (_localUsers.containsKey(email)) {
        return {
          'success': false,
          'message': 'An account already exists with this email address.',
        };
      }

      // Create local user
      String userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _localUsers[email] = {
        'uid': userId,
        'name': name,
        'email': email,
        'password': password, // In real app, this should be hashed
        'created_at': DateTime.now(),
        'last_login': DateTime.now(),
        'knowledge_graphs_count': 0,
        'receipts_scanned': 0,
      };

      _currentUserId = userId;

      print('Local user created successfully: $email');
      
      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': _LocalUser(userId, name, email),
      };
    } catch (e) {
      print('Local signup error: $e');
      return {
        'success': false,
        'message': 'Failed to create account: $e',
      };
    }
  }

  /// Local sign in (for demo/testing purposes)
  static Future<Map<String, dynamic>> localSignIn({
    required String email,
    required String password,
  }) async {
    try {
      if (!_localUsers.containsKey(email)) {
        return {
          'success': false,
          'message': 'No account found with this email address.',
        };
      }

      Map<String, dynamic> userData = _localUsers[email]!;
      if (userData['password'] != password) {
        return {
          'success': false,
          'message': 'Incorrect password. Please try again.',
        };
      }

      _currentUserId = userData['uid'];
      userData['last_login'] = DateTime.now();

      print('Local user signed in successfully: $email');

      return {
        'success': true,
        'message': 'Welcome back!',
        'user': _LocalUser(userData['uid'], userData['name'], userData['email']),
      };
    } catch (e) {
      print('Local signin error: $e');
      return {
        'success': false,
        'message': 'Failed to sign in: $e',
      };
    }
  }

  /// Local sign out
  static Future<void> localSignOut() async {
    _currentUserId = null;
    print('Local user signed out');
  }

  /// Get local user data
  static Map<String, dynamic>? getLocalUserData(String email) {
    return _localUsers[email];
  }
}

class _LocalUser {
  final String uid;
  final String displayName;
  final String email;

  _LocalUser(this.uid, this.displayName, this.email);
}
