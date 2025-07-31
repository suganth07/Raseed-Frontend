import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for interacting with Ecospend AI Assistant API
/// 
/// Provides methods for:
/// - Spending analysis and visualization
/// - Location-based store recommendations
/// - Sustainability tips and recycling centers
/// - AI-powered chat functionality
class EcospendService {
  static const String _baseUrl = 'http://localhost:8001/ecospend';
  
  /// Get comprehensive spending analysis for a user
  static Future<Map<String, dynamic>> getSpendingAnalysis(String userEmail) async {
    try {
      final requestBody = {
        'user_email': userEmail,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/spending-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Spending analysis retrieved successfully'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'No spending data found',
            'data': null
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to analyze spending data',
          'data': null
        };
      }
    } catch (e) {
      debugPrint('Ecospend spending analysis error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'data': null
      };
    }
  }
  }

  /// Get location-based store recommendations
  static Future<Map<String, dynamic>> getLocationRecommendations(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/location-recommendations/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message']
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Could not find your location. Please ensure location access is enabled.',
          'data': null
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get location recommendations',
          'data': null
        };
      }
    } catch (e) {
      debugPrint('Ecospend location recommendations error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'data': null
      };
    }
  }

  /// Get personalized sustainability tips and money-saving advice
  static Future<Map<String, dynamic>> getSustainabilityTips(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sustainability-tips/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get sustainability tips',
          'data': null
        };
      }
    } catch (e) {
      debugPrint('Ecospend sustainability tips error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'data': null
      };
    }
  }

  /// Chat with Ecospend AI assistant
  static Future<Map<String, dynamic>> chatWithEcospend({
    required String userEmail,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      final requestBody = {
        'user_email': userEmail,
        'message': message,
        'context': context ?? {},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'response': data['response'],
          'suggestions': data['suggestions'] ?? [],
          'data': data['data'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get response from Ecospend AI',
          'response': 'Sorry, I encountered an error. Please try again.',
          'suggestions': [],
        };
      }
    } catch (e) {
      debugPrint('Ecospend chat error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'response': 'Sorry, I could not connect to the server. Please check your internet connection.',
        'suggestions': [],
      };
    }
  }

  /// Get Ecospend service information and capabilities
  static Future<Map<String, dynamic>> getEcospendInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get Ecospend information',
        };
      }
    } catch (e) {
      debugPrint('Ecospend info error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Get spending chart image URL
  static String getChartUrl(String chartFilename) {
    return '$_baseUrl/chart/$chartFilename';
  }

  /// Check if Ecospend service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Ecospend service check error: $e');
      return false;
    }
  }
}
