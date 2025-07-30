import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get comprehensive user profile data from Firebase
  static Future<Map<String, dynamic>> getUserProfileData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return _getDefaultUserData();
      }

      String userEmail = user.email!;
      
      // Get user info from users collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userEmail)
          .get();

      Map<String, dynamic> userInfo = {};
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userInfo = userData['_user_info'] ?? {};
      }

      // Get knowledge graphs count
      QuerySnapshot kgSnapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('knowledge_graphs')
          .get();

      int knowledgeGraphsCount = kgSnapshot.docs.length;

      // Calculate total spending and receipts from knowledge graphs
      double totalSpent = 0.0;
      int receiptsCount = 0;
      double thisMonthSpent = 0.0;
      DateTime now = DateTime.now();
      String currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      for (var doc in kgSnapshot.docs) {
        Map<String, dynamic> kgData = doc.data() as Map<String, dynamic>;
        
        // Extract spending from knowledge graph data
        Map<String, dynamic>? data = kgData['data'];
        if (data != null) {
          double amount = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          totalSpent += amount;
          receiptsCount++;

          // Check if this is from current month
          String? createdAt = data['created_at'];
          if (createdAt != null && createdAt.startsWith(currentMonth)) {
            thisMonthSpent += amount;
          }
        }
      }

      return {
        'name': userInfo['name'] ?? user.displayName ?? userEmail.split('@')[0],
        'email': user.email ?? '',
        'knowledgeGraphsCount': knowledgeGraphsCount,
        'totalSpent': totalSpent,
        'receiptsCount': receiptsCount,
        'thisMonthSpent': thisMonthSpent,
        'receiptsScanned': userInfo['receipts_scanned'] ?? receiptsCount,
        'lastActivity': userInfo['last_activity'],
        'createdAt': userInfo['created_at'],
      };

    } catch (e) {
      print('Error fetching user profile data: $e');
      return _getDefaultUserData();
    }
  }

  /// Get default/fallback user data
  static Map<String, dynamic> _getDefaultUserData() {
    User? user = _auth.currentUser;
    return {
      'name': user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
      'email': user?.email ?? '',
      'knowledgeGraphsCount': 0,
      'totalSpent': 0.0,
      'receiptsCount': 0,
      'thisMonthSpent': 0.0,
      'receiptsScanned': 0,
      'lastActivity': null,
      'createdAt': null,
    };
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date for display
  static String formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
