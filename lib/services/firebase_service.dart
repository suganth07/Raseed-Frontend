import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      // Continue without Firebase for demo mode
    }
  }
  
  static FirebaseFirestore get firestore {
    return _firestore ?? FirebaseFirestore.instance;
  }
  
  /// Fetch knowledge graphs for a user from user-specific subcollection
  static Future<List<Map<String, dynamic>>> getUserKnowledgeGraphs(String userId) async {
    try {
      if (_firestore == null) {
        print('Firebase not initialized, no knowledge graphs available');
        return [];
      }
      
      // Query the user-specific subcollection: users/{userId}/knowledge_graphs
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('knowledge_graphs')
          .orderBy('data.created_at', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('Error fetching knowledge graphs: $e');
      return [];
    }
  }
  
  /// Get aggregated analytics from all user's knowledge graphs
  static Future<Map<String, dynamic>> getUserGraphAnalytics(String userId) async {
    try {
      if (_firestore == null) {
        return _getEmptyGraphAnalytics();
      }
      
      final graphs = await getUserKnowledgeGraphs(userId);
      
      if (graphs.isEmpty) {
        return _getEmptyGraphAnalytics();
      }
      
      // Aggregate data from all graphs
      int totalEntities = 0;
      int totalRelations = 0;
      Map<String, int> entityTypeCount = {};
      Map<String, int> relationTypeCount = {};
      List<dynamic> allEntities = [];
      List<dynamic> allRelations = [];
      
      for (var graph in graphs) {
        totalEntities += (graph['total_entities'] as int?) ?? 0;
        totalRelations += (graph['total_relations'] as int?) ?? 0;
        
        final entities = graph['entities'] as List? ?? [];
        final relations = graph['relations'] as List? ?? [];
        
        allEntities.addAll(entities);
        allRelations.addAll(relations);
        
        // Count entity types
        for (var entity in entities) {
          final type = entity['type'] as String? ?? 'unknown';
          entityTypeCount[type] = (entityTypeCount[type] ?? 0) + 1;
        }
        
        // Count relation types
        for (var relation in relations) {
          final type = relation['relation_type'] as String? ?? 'unknown';
          relationTypeCount[type] = (relationTypeCount[type] ?? 0) + 1;
        }
      }
      
      return {
        'total_entities': totalEntities,
        'total_relations': totalRelations,
        'total_graphs': graphs.length,
        'entity_type_distribution': entityTypeCount,
        'relation_type_distribution': relationTypeCount,
        'last_updated': graphs.isNotEmpty ? graphs.first['updated_at'] : DateTime.now().toIso8601String(),
        'entities': allEntities,
        'relations': allRelations,
      };
      
    } catch (e) {
      print('Error calculating graph analytics: $e');
      return _getEmptyGraphAnalytics();
    }
  }
  
  /// Fetch receipt data for knowledge graph (kept for backward compatibility)
  static Future<List<Map<String, dynamic>>> getReceiptData(String userId) async {
    try {
      if (_firestore == null) {
        print('Firebase not initialized, returning mock data');
        return _getMockReceiptData();
      }
      
      final snapshot = await firestore
          .collection('comprehensive_receipts')
          .where('metadata.user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('Error fetching receipt data: $e');
      return _getMockReceiptData();
    }
  }
  
  /// Get user's spending analytics
  static Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      if (_firestore == null) {
        return _getMockAnalytics();
      }
      
      final receipts = await getReceiptData(userId);
      
      double totalSpent = 0;
      Map<String, double> categorySpending = {};
      Map<String, int> merchantFrequency = {};
      
      for (var receipt in receipts) {
        // Calculate total spending
        final amount = (receipt['total_amount'] as num?)?.toDouble() ?? 0.0;
        totalSpent += amount;
        
        // Track category spending
        final category = receipt['category'] as String? ?? 'Other';
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
        
        // Track merchant frequency
        final merchant = receipt['merchant_name'] as String? ?? 'Unknown';
        merchantFrequency[merchant] = (merchantFrequency[merchant] ?? 0) + 1;
      }
      
      return {
        'total_spent': totalSpent,
        'receipt_count': receipts.length,
        'category_spending': categorySpending,
        'merchant_frequency': merchantFrequency,
        'average_transaction': receipts.isNotEmpty ? totalSpent / receipts.length : 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('Error calculating analytics: $e');
      return _getMockAnalytics();
    }
  }
  
  /// Save wallet pass to Firebase
  static Future<bool> saveWalletPass(String userId, Map<String, dynamic> passData) async {
    try {
      if (_firestore == null) {
        print('Firebase not available - pass saved locally (demo mode)');
        return true;
      }
      
      await firestore
          .collection('wallet_passes')
          .add({
        'user_id': userId,
        'pass_data': passData,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error saving wallet pass: $e');
      return false;
    }
  }
  
  /// Get user's wallet passes
  static Future<List<Map<String, dynamic>>> getWalletPasses(String userId) async {
    try {
      if (_firestore == null) {
        return _getMockWalletPasses();
      }
      
      final snapshot = await firestore
          .collection('wallet_passes')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('Error fetching wallet passes: $e');
      return _getMockWalletPasses();
    }
  }
  
  static Map<String, dynamic> _getEmptyGraphAnalytics() {
    return {
      'total_entities': 0,
      'total_relations': 0,
      'total_graphs': 0,
      'entity_type_distribution': <String, int>{},
      'relation_type_distribution': <String, int>{},
      'last_updated': DateTime.now().toIso8601String(),
      'entities': <dynamic>[],
      'relations': <dynamic>[],
      'message': 'no knowledge to display, scan a receipt now'
    };
  }
  
  static List<Map<String, dynamic>> _getMockReceiptData() {
    return [
      {
        'id': 'receipt_1',
        'merchant_name': 'Starbucks Coffee',
        'total_amount': 15.75,
        'category': 'Food & Beverage',
        'items': [
          {'name': 'Grande Latte', 'price': 12.50, 'quantity': 1},
          {'name': 'Blueberry Muffin', 'price': 3.25, 'quantity': 1},
        ],
        'payment_method': 'Credit Card',
        'location': 'Downtown Seattle',
        'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'receipt_2',
        'merchant_name': 'McDonald\'s',
        'total_amount': 8.99,
        'category': 'Fast Food',
        'items': [
          {'name': 'Big Mac Meal', 'price': 8.99, 'quantity': 1},
        ],
        'payment_method': 'Credit Card',
        'location': 'Mall Food Court',
        'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      },
    ];
  }
  
  static Map<String, dynamic> _getMockAnalytics() {
    return {
      'total_spent': 24.74,
      'receipt_count': 2,
      'category_spending': {
        'Food & Beverage': 15.75,
        'Fast Food': 8.99,
      },
      'merchant_frequency': {
        'Starbucks Coffee': 1,
        'McDonald\'s': 1,
      },
      'average_transaction': 12.37,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  static List<Map<String, dynamic>> _getMockWalletPasses() {
    return [
      {
        'id': 'pass_1',
        'pass_data': {
          'type': 'generic',
          'title': 'Starbucks Rewards',
          'description': 'Loyalty Card',
          'points': 125,
          'tier': 'Gold',
        },
        'created_at': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
      },
    ];
  }
}
