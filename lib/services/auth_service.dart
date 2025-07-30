import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as googleapis_auth;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Google Sign-In with calendar permissions - works on all platforms
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/calendar.events', // Calendar permission
    ],
    // For web, this will use the client ID from index.html meta tag
    // For mobile, this will use the configuration from platform-specific files
  );

  // Store Google credentials for calendar access
  static googleapis_auth.AccessCredentials? _googleCredentials;

  // Initialize Firebase services
  static Future<void> initialize() async {
    try {
      // Firebase is already initialized in main.dart
      print('AuthService initialized successfully');
    } catch (e) {
      print('AuthService initialization error: $e');
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Get current user email
  static String? get currentUserEmail => _auth.currentUser?.email;
  
  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to create user with email: $email');
      
      // Create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print('User created successfully with UID: ${user.uid}');
        
        // Update display name
        await user.updateDisplayName(name);
        print('Display name updated to: $name');
        
        // Create user document in Firestore with Knowledge Graph collection
        await _createUserDocument(user, name);
        print('User document and Knowledge Graph collection created in Firestore');
        
        return {
          'success': true,
          'message': 'Account created successfully!',
          'user': user,
        };
      } else {
        print('User creation failed - user is null');
        return {
          'success': false,
          'message': 'Failed to create account',
        };
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      print('Unexpected error during signup: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Create a new user account (alias for signUp for clarity)
  static Future<Map<String, dynamic>> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    return await signUp(
      name: name,
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Update last login time
        await _updateLastLogin(user.uid);
        
        return {
          'success': true,
          'message': 'Welcome back!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase signin failed: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      print('Unexpected error during signin: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase
      _googleCredentials = null; // Clear stored credentials
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Sign in with Google (with calendar permissions)
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Sign in with Google (this will request calendar permissions)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in was cancelled',
        };
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Store credentials for calendar access
      _googleCredentials = googleapis_auth.AccessCredentials(
        googleapis_auth.AccessToken(
          'Bearer',
          googleAuth.accessToken!,
          DateTime.now().add(Duration(hours: 1)).toUtc(), // Expires in 1 hour
        ),
        null, // Refresh token may not be available
        ['https://www.googleapis.com/auth/calendar.events'],
      );

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if this is a new user
        bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // Create user document for new Google users
          await _createUserDocument(user, user.displayName ?? 'Google User');
        } else {
          // Update last login for existing users
          await _updateLastLogin(user.uid);
        }

        return {
          'success': true,
          'message': isNewUser ? 'Welcome to Raseed!' : 'Welcome back!',
          'user': user,
          'hasCalendarPermission': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Google sign-in failed',
        };
      }
    } catch (e) {
      print('Google sign-in error: $e');
      return {
        'success': false,
        'message': 'Google sign-in failed: ${e.toString()}',
      };
    }
  }

  /// Get Google access token for calendar API
  static Future<String?> getGoogleAccessToken() async {
    try {
      if (_googleCredentials != null && 
          _googleCredentials!.accessToken.expiry.isAfter(DateTime.now().toUtc())) {
        return _googleCredentials!.accessToken.data;
      }

      // Try to refresh the token
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        _googleCredentials = googleapis_auth.AccessCredentials(
          googleapis_auth.AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().add(Duration(hours: 1)).toUtc(),
          ),
          null, // Refresh token may not be available
          ['https://www.googleapis.com/auth/calendar.events'],
        );
        
        return googleAuth.accessToken;
      }
      
      return null;
    } catch (e) {
      print('Error getting Google access token: $e');
      return null;
    }
  }

  /// Check if user has calendar permissions
  static Future<bool> hasCalendarPermission() async {
    try {
      final String? token = await getGoogleAccessToken();
      return token != null;
    } catch (e) {
      print('Error checking calendar permission: $e');
      return false;
    }
  }

  /// Create user document in Firestore with Knowledge Graph collection - using email as unique ID
  static Future<void> _createUserDocument(User user, String name) async {
    try {
      // Use email as the document ID for uniqueness instead of display name
      String userDocumentId = user.email!; // e.g., "sample@gmail.com"
      print('Creating user document for email: $userDocumentId in new structure');
      
      // Create user document in new structure: /users/{email}/_user_info
      await _firestore.collection('users').doc(userDocumentId).set({
        '_user_info': {
          'uid': user.uid,
          'name': name,
          'email': user.email,
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'knowledge_graphs_count': 0,
          'receipts_scanned': 0,
        }
      });

      print('User document created successfully for email: $userDocumentId in new structure');
      print('Knowledge graphs collection will be created when first receipt is scanned');
    } catch (e) {
      print('Error creating user document: $e');
      // Re-throw the error so the signup process knows it failed
      rethrow;
    }
  }

  /// Update last login time in new structure
  static Future<void> _updateLastLogin(String uid) async {
    try {
      // Get user email to access their collection
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        await _firestore.collection('users').doc(user.email!).update({
          '_user_info.last_login': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Delete user document and all related data from new structure
  static Future<void> _deleteUserDocument(String uid) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        String userEmail = user.email!; // Use email instead of display name
        
        // Delete user's knowledge graphs collection from new structure
        QuerySnapshot graphs = await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('knowledge_graphs')
            .get();
        
        for (QueryDocumentSnapshot doc in graphs.docs) {
          await doc.reference.delete();
        }
        
        // Delete user document from new structure
        await _firestore.collection('users').doc(userEmail).delete();
        
        print('User document and related data deleted successfully for email: $userEmail from new structure');
      }
    } catch (e) {
      print('Error deleting user document: $e');
    }
  }

  /// Get user data from Firestore using new structure
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        String userEmail = user.email!; // Use email instead of display name
        DocumentSnapshot doc = await _firestore.collection('users').doc(userEmail).get();
        if (doc.exists) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          return userData['_user_info'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send reset email: $e',
      };
    }
  }

  /// Delete user account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore first
        await _deleteUserDocument(user.uid);
        
        // Delete Firebase Auth user
        await user.delete();
        
        return {
          'success': true,
          'message': 'Account deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete account: $e',
      };
    }
  }

  /// Update user profile (name)
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.displayName != null) {
        String oldUsername = user.displayName!;
        
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        
        // Update user document in Firestore
        await _firestore.collection(oldUsername).doc('_user_info').update({
          'name': name,
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        return {
          'success': true,
          'message': 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  /// Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email registration: $e');
      return false;
    }
  }

  /// Get current user data (Firebase only)
  static Map<String, dynamic>? getCurrentUserData() {
    if (_auth.currentUser != null) {
      return {
        'uid': _auth.currentUser!.uid,
        'name': _auth.currentUser!.displayName,
        'email': _auth.currentUser!.email,
      };
    }
    return null;
  }

  /// Store scanned receipt in user's knowledge graph collection
  static Future<Map<String, dynamic>> storeReceiptKnowledgeGraph({
    required String receiptName,
    required Map<String, dynamic> receiptData,
    required Map<String, dynamic> knowledgeGraphData,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in or email not found',
        };
      }

      String userEmail = user.email!; // Use email instead of display name
      
      // Create a meaningful document ID with scan date and receipt name
      DateTime now = DateTime.now();
      String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      String formattedTime = '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      
      // Clean receipt name for use in document ID (remove special characters)
      String cleanReceiptName = receiptName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      if (cleanReceiptName.length > 30) {
        cleanReceiptName = cleanReceiptName.substring(0, 30);
      }
      
      // Create document ID: date_time_receiptName
      String receiptDocId = '${formattedDate}_${formattedTime}_$cleanReceiptName';
      String receiptId = receiptData['receipt_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Extract and organize data in the new structure
      // First try to get items from knowledgeGraphData (which contains the full backend response)
      List<dynamic> items = [];
      if (knowledgeGraphData.containsKey('items')) {
        items = knowledgeGraphData['items'] ?? [];
      } else if (receiptData.containsKey('items')) {
        items = receiptData['items'] ?? [];
      }
      
      print('Found ${items.length} items to process for products');
      
      List<Map<String, dynamic>> products = items.map((item) => {
        'name': item['name'] ?? 'Unknown Item',
        'brand': item['brand'] ?? '',
        'price': item['unit_price'] ?? item['price'] ?? 0.0,
        'quantity': item['quantity'] ?? 1,
        'category': item['category'] ?? 'General',
        'warranty': item['has_warranty'] ?? false,
        'warranty_period': item['has_warranty'] == true ? (item['warranty_period'] ?? '12 months') : null,
        'warranty_end_date': item['warranty_end_date'],
        'expiry_date': item['expiry_date'], // Use expiry_date instead of warranty_end_date
        'has_expiry': item['has_expiry'] ?? false,
        'is_expiring_soon': item['is_expiring_soon'] ?? false,
        'product_type': item['product_type'] ?? '',
        'is_food': item['is_food'] ?? false,
        'is_discounted': item['is_discounted'] ?? false,
      }).toList();

      // Build relationships array
      List<Map<String, dynamic>> relationships = [
        {
          'subject': userEmail,
          'predicate': 'MADE_PURCHASE',
          'object': 'receipt:$receiptId'
        },
        {
          'subject': 'receipt:$receiptId',
          'predicate': 'ISSUED_BY',
          'object': 'merchant:${receiptData['merchant_name'] ?? 'Unknown'}'
        },
      ];

      // Add product relationships
      for (var product in products) {
        relationships.addAll([
          {
            'subject': 'receipt:$receiptId',
            'predicate': 'CONTAINS_PRODUCT',
            'object': 'product:${product['name']}'
          },
          {
            'subject': 'product:${product['name']}',
            'predicate': 'BELONGS_TO_CATEGORY',
            'object': product['category']
          },
        ]);

        if (product['warranty'] == true) {
          relationships.add({
            'subject': 'product:${product['name']}',
            'predicate': 'HAS_WARRANTY',
            'object': 'true'
          });
          if (product['expiry_date'] != null) {
            relationships.add({
              'subject': 'product:${product['name']}',
              'predicate': 'EXPIRES_ON',
              'object': product['expiry_date']
            });
          }
        }
      }

      // Add merchant location relationship
      Map<String, dynamic> location = receiptData['location'] ?? {};
      if (location['country'] != null) {
        relationships.add({
          'subject': 'merchant:${receiptData['merchant_name'] ?? 'Unknown'}',
          'predicate': 'LOCATED_IN',
          'object': location['country']
        });
      }

      // Calculate category distribution
      Map<String, int> categoryDistribution = {};
      for (var product in products) {
        String category = product['category'] ?? 'General';
        categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
      }

      // Create the new organized structure
      Map<String, dynamic> organizedData = {
        'data': {
          'graph_built': true,
          'created_at': now.toIso8601String(),
          'receipt_id': receiptId,
          'receipt_name': receiptName,
          'receipt_summary': '${products.length} items',
          'total_amount': receiptData['total_amount'] ?? 0.0,
          'currency': receiptData['currency'] ?? 'USD',
          'user': {
            'uid': user.uid,
            'username': userEmail,
            'email': user.email,
          },
        },
        'merchant_details': {
          'merchant': {
            'name': receiptData['merchant_name'] ?? 'Unknown Merchant',
            'category': receiptData['business_category'] ?? 'Retail',
            'location': {
              'city': location['city'] ?? 'Unknown',
              'state': location['state'] ?? 'Unknown',
              'country': location['country'] ?? 'USA',
            }
          }
        },
        'products': products,
        'relationships': relationships,
        'analytics': {
          'item_count': products.length,
          'warranty_count': products.where((p) => p['warranty'] == true).length,
          'brand_count': products.map((p) => p['brand']).where((b) => b != '').toSet().length,
          'shopping_pattern': receiptData['shopping_pattern'] ?? 'Regular',
          'category_distribution': categoryDistribution,
        }
      };
      
      // Store in the new structure: /users/{email}/knowledge_graphs/{receiptId}
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('knowledge_graphs')
          .doc(receiptDocId)
          .set(organizedData);

      // Also update user info in the new structure
      await _firestore.collection('users').doc(userEmail).set({
        '_user_info': {
          'uid': user.uid,
          'username': userEmail,
          'email': user.email,
          'receipts_scanned': FieldValue.increment(1),
          'knowledge_graphs_count': FieldValue.increment(1),
          'last_activity': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      print('Receipt knowledge graph stored successfully for email: $userEmail in new structure');
      
      return {
        'success': true,
        'message': 'Receipt scanned and knowledge graph created successfully!',
        'receiptId': receiptId,
        'documentId': receiptDocId, // The meaningful document ID
        'receiptName': receiptName,
        'scanDate': formattedDate,
      };
    } catch (e) {
      print('Error storing receipt knowledge graph: $e');
      return {
        'success': false,
        'message': 'Failed to store receipt data: $e',
      };
    }
  }

  /// Get all knowledge graphs for current user from new structure
  static Future<List<Map<String, dynamic>>> getUserKnowledgeGraphs() async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        print('No user logged in or email not found, returning empty knowledge graphs');
        return [];
      }

      String userEmail = user.email!;
      
      // Query from new structure: /users/{email}/knowledge_graphs/
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('knowledge_graphs')
          .orderBy('data.created_at', descending: true)
          .get();

      print('Retrieved ${snapshot.docs.length} knowledge graphs for email: $userEmail from new structure');

      List<Map<String, dynamic>> knowledgeGraphs = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
        
        // Transform the new structure back to the format expected by the graph visualization
        Map<String, dynamic> transformedData = {
          'doc_id': doc.id,
          'receipt_data': {
            'receipt_id': docData['data']?['receipt_id'],
            'merchant_name': docData['merchant_details']?['merchant']?['name'],
            'total_amount': docData['data']?['total_amount'],
            'formatted_total': '\$${(docData['data']?['total_amount'] ?? 0.0).toStringAsFixed(2)}',
            'currency': docData['data']?['currency'],
            'business_category': docData['merchant_details']?['merchant']?['category'],
            'location': docData['merchant_details']?['merchant']?['location'],
            'processing_time': '0.00s',
            'created_at': docData['data']?['created_at'],
            'version': '1.0.0',
            'item_count': docData['analytics']?['item_count'],
            'warranty_count': docData['analytics']?['warranty_count'],
            'brand_count': docData['analytics']?['brand_count'],
            'category_count': docData['analytics']?['category_distribution']?.length,
            'shopping_pattern': docData['analytics']?['shopping_pattern'],
            'items': docData['products'],
          },
          'knowledge_graph': {
            'nodes': _convertProductsToNodes(docData['products'] ?? []),
            'edges': _convertRelationshipsToEdges(docData['relationships'] ?? []),
            'analytics': docData['analytics'],
          }
        };
        
        knowledgeGraphs.add(transformedData);
      }

      print('Retrieved ${knowledgeGraphs.length} knowledge graphs for email: $userEmail from new structure');
      return knowledgeGraphs;
    } catch (e) {
      print('Error getting user knowledge graphs: $e');
      return [];
    }
  }

  /// Helper method to convert products to nodes format
  static List<Map<String, dynamic>> _convertProductsToNodes(List<dynamic> products) {
    List<Map<String, dynamic>> nodes = [];
    int nodeId = 1;
    
    for (var product in products) {
      nodes.add({
        'id': 'product_$nodeId',
        'label': product['name'] ?? 'Unknown Product',
        'type': 'product',
        'size': 15,
        'color': '#4CAF50',
        'metadata': {
          'name': product['name'],
          'brand': product['brand'],
          'price': product['price'],
          'category': product['category'],
          'warranty': product['warranty'],
        }
      });
      nodeId++;
    }
    
    return nodes;
  }

  /// Helper method to convert relationships to edges format
  static List<Map<String, dynamic>> _convertRelationshipsToEdges(List<dynamic> relationships) {
    List<Map<String, dynamic>> edges = [];
    int edgeId = 1;
    
    for (var relationship in relationships) {
      edges.add({
        'id': 'edge_$edgeId',
        'from': relationship['subject'],
        'to': relationship['object'],
        'label': relationship['predicate'],
        'type': relationship['predicate']
      });
      edgeId++;
    }
    
    return edges;
  }

  /// Get knowledge graph count for current user from new structure
  static Future<int> getUserKnowledgeGraphCount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) return 0;

      String userEmail = user.email!; // Use email instead of display name
      
      // Get count from new structure: /users/{email}/_user_info
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userEmail)
          .get();
          
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> userInfo = userData['_user_info'] ?? {};
        return userInfo['knowledge_graphs_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting knowledge graph count: $e');
      return 0;
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-api-key':
      case 'api-key-not-valid':
      case 'api-key-not-valid.-please-pass-a-valid-api-key.':
        return 'Firebase configuration error. Please check your Firebase project settings.';
      case 'app-not-authorized':
        return 'App not authorized to use Firebase Authentication.';
      default:
        return 'Firebase error ($errorCode). Please try again or contact support.';
    }
  }
}
