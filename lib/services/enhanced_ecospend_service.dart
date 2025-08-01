import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Enhanced Ecospend Service with Question Classification Support
/// 
/// Provides enhanced methods for:
/// - Enhanced text chat with AI assistant and question classification
/// - Real data validation
/// - Conversation context management
/// - Intent-based responses
class EnhancedEcospendService {
  static const String _baseUrl = 'https://raseed-gcloud-381171297188.asia-south1.run.app/economix';
  
  // Conversation history for context
  static List<Map<String, dynamic>> _conversationHistory = [];
  
  /// Enhanced chat with Economix AI assistant with question classification
  static Future<Map<String, dynamic>> chatWithEconomixEnhanced({
    required String userId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final requestBody = {
        'user_email': userId,
        'message': message,
        'message_type': messageType,
        'conversation_history': _conversationHistory.take(10).toList(), // Last 10 messages for context
        'user_context': userContext,
        'enhanced_classification': true, // Request enhanced features
      };

      if (kDebugMode) {
        print('🚀 Enhanced Chat Request: ${json.encode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Update conversation history
        _addToConversationHistory(message, data['response'] ?? '');
        
        if (data['success'] == true) {
          return {
            'success': true,
            'response': data['response'],
            'message_type': data['message_type'] ?? 'response',
            'timestamp': data['timestamp'],
            
            // Enhanced classification data
            'intent_classified': data['intent_classified'],
            'confidence': data['confidence'],
            'suggestions': data['suggestions'] ?? [],
            'context': data['context'],
            'time_scope': data['time_scope'],
            'category_filter': data['category_filter'],
            'merchant_filter': data['merchant_filter'],
            'amount_filter': data['amount_filter'],
            'required_data': data['required_data'] ?? [],
            
            // Real data indicators
            'using_real_data': data['using_real_data'] ?? false,
            'data_validation': data['data_validation'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to get response from Economix AI',
            'response': data['response'] ?? 'Sorry, I encountered an error. Please try again.',
            'error_type': data['error_type'] ?? 'unknown_error',
          };
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Bad request: ${errorData['detail'] ?? 'Invalid request'}',
          'response': 'Please check your input and try again.',
          'error_type': 'validation_error',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed',
          'response': 'Please log in again to continue.',
          'error_type': 'auth_error',
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many requests',
          'response': 'Please wait a moment before trying again.',
          'error_type': 'rate_limit_error',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'response': 'Our servers are experiencing issues. Please try again later.',
          'error_type': 'server_error',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Enhanced Chat Error: $e');
      }
      
      return {
        'success': false,
        'message': 'Network error: $e',
        'response': 'Unable to connect to our servers. Please check your internet connection and try again.',
        'error_type': 'network_error',
      };
    }
  }

  /// Validate user has real data before chatting
  static Future<Map<String, dynamic>> validateUserData({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/validate-data/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'has_real_data': data['has_real_data'] ?? false,
          'transaction_count': data['transaction_count'] ?? 0,
          'total_spent': data['total_spent'] ?? 0.0,
          'data_quality': data['data_quality'] ?? 'unknown',
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'has_real_data': false,
          'message': 'Unable to validate user data',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Data Validation Error: $e');
      }
      return {
        'success': false,
        'has_real_data': false,
        'message': 'Network error during data validation',
      };
    }
  }

  /// Get conversation suggestions based on user's data and history
  static Future<List<String>> getConversationSuggestions({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/suggestions/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions'] ?? []);
      } else {
        return _getDefaultSuggestions();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Suggestions Error: $e');
      }
      return _getDefaultSuggestions();
    }
  }

  /// Get financial insights summary
  static Future<Map<String, dynamic>> getFinancialSummary({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/summary/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Unable to fetch financial summary',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Summary Error: $e');
      }
      return {
        'success': false,
        'message': 'Network error during summary fetch',
      };
    }
  }

  /// Add message to conversation history
  static void _addToConversationHistory(String userMessage, String botResponse) {
    _conversationHistory.addAll([
      {
        'role': 'user',
        'content': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'role': 'assistant',
        'content': botResponse,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ]);

    // Keep only last 20 messages (10 exchanges)
    if (_conversationHistory.length > 20) {
      _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
    }
  }

  /// Clear conversation history
  static void clearConversationHistory() {
    _conversationHistory.clear();
  }

  /// Get default suggestions when API fails
  static List<String> _getDefaultSuggestions() {
    return [
      "How much did I spend this month?",
      "Analyze my spending patterns",
      "What's my biggest expense category?",
      "Compare this month to last month",
      "Help me create a budget",
      "How can I save more money?",
    ];
  }

  /// Legacy method for backward compatibility
  static Future<Map<String, dynamic>> chatWithEconomix({
    required String userId,
    required String message,
    String messageType = 'text',
  }) async {
    return await chatWithEconomixEnhanced(
      userId: userId,
      message: message,
      messageType: messageType,
    );
  }

  // TODO: Add other enhanced methods for image analysis, file processing, etc.
  // These can be implemented as needed to maintain existing functionality
}
