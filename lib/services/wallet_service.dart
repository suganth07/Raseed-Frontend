import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet_models.dart';

class WalletService {
  static const String baseUrl = 'https://raseed-gcloud-381171297188.asia-south1.run.app/wallet';
  
  // Get eligible wallet items for a user
  static Future<WalletItemsResponse> getEligibleItems(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/eligible-items/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WalletItemsResponse.fromJson(data);
      } else {
        return WalletItemsResponse(
          success: false,
          items: [],
          totalReceipts: 0,
          totalWarranties: 0,
          error: 'Failed to load eligible items: ${response.statusCode}',
        );
      }
    } catch (e) {
      return WalletItemsResponse(
        success: false,
        items: [],
        totalReceipts: 0,
        totalWarranties: 0,
        error: 'Network error: $e',
      );
    }
  }

  // Generate wallet pass
  static Future<PassGenerationResponse> generatePass({
    required String itemId,
    required String passType,
    required String userId,
  }) async {
    try {
      final request = PassGenerationRequest(
        itemId: itemId,
        passType: passType,
        userId: userId,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/generate-pass'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PassGenerationResponse.fromJson(data);
      } else {
        return PassGenerationResponse(
          success: false,
          error: 'Failed to generate pass: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PassGenerationResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Check wallet service health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Wallet service health check failed: $e');
      return false;
    }
  }

  // Get user's wallet passes
  static Future<Map<String, dynamic>> getUserPasses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-passes/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to load user passes: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
