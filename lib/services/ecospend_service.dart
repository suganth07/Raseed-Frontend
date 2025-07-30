import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for interacting with Economix Bot API
/// 
/// Provides methods for:
/// - Text chat with AI assistant
/// - Image analysis and receipt processing
/// - File processing
/// - Audio processing
/// - Financial insights and summaries
class EcospendService {
  static const String _baseUrl = 'https://raseed-gcloud-381171297188.asia-south1.run.app/economix';
  
  /// Chat with Economix AI assistant using text
  static Future<Map<String, dynamic>> chatWithEconomix({
    required String userId, // This is actually the user's email now
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final requestBody = {
        'user_email': userId, // Send as user_email to match backend expectation
        'message': message,
        'message_type': messageType,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'response': data['response'],
            'message_type': data['message_type'],
            'timestamp': data['timestamp'],
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to get response from Economix AI',
            'response': 'Sorry, I encountered an error. Please try again.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to connect to Economix AI',
          'response': 'Sorry, I could not connect to the server.',
        };
      }
    } catch (e) {
      debugPrint('Economix chat error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'response': 'Sorry, I could not connect to the server. Please check your internet connection.',
      };
    }
  }

  /// Process image with Economix AI (receipt analysis, etc.)
  static Future<Map<String, dynamic>> chatWithImage({
    required String userId, // This is actually the user's email now
    required List<int> imageBytes,
    String query = '',
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat/image'));
      
      request.fields['user_email'] = userId; // Send as user_email to match backend expectation
      request.fields['query'] = query;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'response': data['response'],
            'message_type': data['message_type'],
            'query': data['query'],
            'timestamp': data['timestamp'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to process image',
        'response': 'Sorry, I had trouble analyzing that image.',
      };
    } catch (e) {
      debugPrint('Economix image error: $e');
      return {
        'success': false,
        'message': 'Network error while processing image',
        'response': 'Sorry, I could not process the image.',
      };
    }
  }

  /// Process file with Economix AI (PDF, Excel, etc.)
  static Future<Map<String, dynamic>> chatWithFile({
    required String userId,
    required List<int> fileBytes,
    required String filename,
    String query = '',
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat/file'));
      
      request.fields['user_email'] = userId;
      request.fields['query'] = query;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'response': data['response'],
            'message_type': data['message_type'],
            'filename': data['filename'],
            'query': data['query'],
            'timestamp': data['timestamp'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to process file',
        'response': 'Sorry, I had trouble processing that file.',
      };
    } catch (e) {
      debugPrint('Economix file error: $e');
      return {
        'success': false,
        'message': 'Network error while processing file',
        'response': 'Sorry, I could not process the file.',
      };
    }
  }

  /// Get financial summary for user
  static Future<Map<String, dynamic>> getFinancialSummary(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/financial-summary?user_email=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'summary': data['summary'],
            'generated_at': data['generated_at'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to get financial summary',
      };
    } catch (e) {
      debugPrint('Financial summary error: $e');
      return {
        'success': false,
        'message': 'Network error while getting financial summary',
      };
    }
  }

  /// Get shopping recommendations
  static Future<Map<String, dynamic>> getShoppingRecommendations({
    required String userId,
    String category = 'all',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/recommendations/shopping?user_email=$userId&category=$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'recommendations': data['recommendations'],
            'category': data['category'],
            'generated_at': data['generated_at'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to get shopping recommendations',
      };
    } catch (e) {
      debugPrint('Shopping recommendations error: $e');
      return {
        'success': false,
        'message': 'Network error while getting recommendations',
      };
    }
  }

  /// Get spending insights
  static Future<Map<String, dynamic>> getSpendingInsights({
    required String userId,
    String period = 'month',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/insights/spending?user_email=$userId&period=$period'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'insights': data['insights'],
            'period': data['period'],
            'generated_at': data['generated_at'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to get spending insights',
      };
    } catch (e) {
      debugPrint('Spending insights error: $e');
      return {
        'success': false,
        'message': 'Network error while getting insights',
      };
    }
  }

  /// Get chat history
  static Future<Map<String, dynamic>> getChatHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history?user_email=$userId&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'messages': data['messages'],
            'count': data['count'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to get chat history',
      };
    } catch (e) {
      debugPrint('Chat history error: $e');
      return {
        'success': false,
        'message': 'Network error while getting chat history',
      };
    }
  }

  /// Clear chat history
  static Future<Map<String, dynamic>> clearChatHistory(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/history'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'user_email': userId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'deleted_count': data['deleted_count'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to clear chat history',
      };
    } catch (e) {
      debugPrint('Clear chat history error: $e');
      return {
        'success': false,
        'message': 'Network error while clearing chat history',
      };
    }
  }

  /// Check Economix service health
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'service': data['service'],
          'capabilities': data['capabilities'],
          'version': data['version'],
        };
      }

      return {
        'success': false,
        'message': 'Health check failed',
      };
    } catch (e) {
      debugPrint('Health check error: $e');
      return {
        'success': false,
        'message': 'Network error during health check',
      };
    }
  }
}
