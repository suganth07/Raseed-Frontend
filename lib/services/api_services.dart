import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/receipt_data.dart';
import 'auth_service.dart';

class ApiService {
  // Updated to use our new backend port and simplified endpoints
  static const String baseUrl = 'http://localhost:8001';

  /// Get consistent user ID from logged-in user - use full email as unique identifier
  static String _getCurrentUserId() {
    String userId = "sample@gmail.com"; // Default fallback
    final user = AuthService.currentUser;
    if (user?.email != null) {
      // Use full email as user ID for uniqueness
      userId = user!.email!; // sample@gmail.com stays as sample@gmail.com
    }
    return userId;
  }

  // Upload receipt using our new structured Document AI endpoint
  // Web-compatible version
  static Future<Map<String, dynamic>> uploadReceipt(dynamic image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      
      // Get consistent user ID from logged-in user
      request.fields['user_id'] = _getCurrentUserId();

      if (kIsWeb) {
        // For web: image is Uint8List
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image as Uint8List,
          filename: 'receipt.jpg',
          contentType: MediaType('image', 'jpeg'), // Specify proper MIME type
        ));
      } else {
        // For mobile: image is File
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }

      // Set timeout
      var response = await request.send().timeout(Duration(seconds: 30));
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          return json.decode(responseData);
        } catch (e) {
          throw Exception('Invalid response format from server');
        }
      } else {
        // Try to parse error message from response
        try {
          var errorData = json.decode(responseData);
          var errorMessage = errorData['detail'] ?? 'Unknown server error';
          throw Exception('Upload failed (${response.statusCode}): $errorMessage');
        } catch (e) {
          throw Exception('Upload failed (${response.statusCode}): $responseData');
        }
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout - please try again');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error - check your connection');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  // Health check for our backend
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/health'));
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  // Check Document AI health specifically
  static Future<Map<String, dynamic>> checkDocumentAIHealth() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/health/document-ai'));
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Document AI health check failed: $e');
    }
  }

  // Knowledge Graph Methods
  
  // Get user's knowledge graph
  static Future<Map<String, dynamic>> getUserKnowledgeGraph(String userId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/graphs/user/$userId'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {}; // No graph found
      } else {
        throw Exception('Failed to get knowledge graph (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Build graph from receipt
  static Future<Map<String, dynamic>> buildGraphFromReceipt(String receiptId) async {
    try {
      var response = await http.post(Uri.parse('$baseUrl/receipts/$receiptId/build-graph'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to build graph (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get graph analytics
  static Future<Map<String, dynamic>> getGraphAnalytics(String graphId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/graphs/$graphId/analytics'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get analytics (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Upload receipt with automatic graph building - Returns ReceiptData model
  static Future<ReceiptData> uploadReceiptWithGraphModel(dynamic image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-with-graph'));
      
      // Add consistent user_id
      request.fields['user_id'] = _getCurrentUserId();

      if (kIsWeb) {
        // For web: image is Uint8List
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image as Uint8List,
          filename: 'receipt.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        // For mobile: image is File
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }

      // Set timeout
      var response = await request.send().timeout(Duration(seconds: 45)); // Longer timeout for graph building
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          var jsonData = json.decode(responseData);
          return ReceiptData.fromJson(jsonData);
        } catch (e) {
          throw Exception('Invalid response format from server: $e');
        }
      } else {
        // Try to parse error message from response
        try {
          var errorData = json.decode(responseData);
          var errorMessage = errorData['detail'] ?? 'Unknown server error';
          throw Exception('Upload with graph failed (${response.statusCode}): $errorMessage');
        } catch (e) {
          throw Exception('Upload with graph failed (${response.statusCode}): $responseData');
        }
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout - graph building takes time, please try again');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error - check your connection');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  // Upload receipt with automatic graph building
  static Future<Map<String, dynamic>> uploadReceiptWithGraph(dynamic image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-with-graph'));
      
      // Add consistent user_id
      request.fields['user_id'] = _getCurrentUserId();

      if (kIsWeb) {
        // For web: image is Uint8List
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image as Uint8List,
          filename: 'receipt.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        // For mobile: image is File
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }

      // Set timeout
      var response = await request.send().timeout(Duration(seconds: 45)); // Longer timeout for graph building
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          return json.decode(responseData);
        } catch (e) {
          throw Exception('Invalid response format from server');
        }
      } else {
        // Try to parse error message from response
        try {
          var errorData = json.decode(responseData);
          var errorMessage = errorData['detail'] ?? 'Unknown server error';
          throw Exception('Upload with graph failed (${response.statusCode}): $errorMessage');
        } catch (e) {
          throw Exception('Upload with graph failed (${response.statusCode}): $responseData');
        }
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout - graph building takes time, please try again');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error - check your connection');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  // Legacy method for compatibility (if needed)
  static Future<Map<String, dynamic>> getAnalytics() async {
    // This would need to be implemented in the backend if needed
    throw UnimplementedError('Analytics endpoint not implemented yet');
  }
}
