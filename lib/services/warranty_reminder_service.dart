import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'google_calendar_service.dart';
import 'auth_service.dart';

class WarrantyReminderService {
  static const String _baseUrl = 'https://raseed-gcloud-381171297188.asia-south1.run.app'; // Backend port 8001
  
  /// Create calendar reminders for all warranties expiring soon using Google Calendar
  static Future<Map<String, dynamic>> createAllWarrantyReminders(String userId) async {
    try {
      // Check if user has Google Calendar permissions
      final hasPermission = await GoogleCalendarService.hasCalendarPermission();
      if (!hasPermission) {
        return {
          'status': 'error',
          'message': 'Please sign in with Google to enable calendar reminders',
          'requires_google_signin': true,
        };
      }

      // Get all warranty products
      final products = await getWarrantyProducts(userId);
      
      if (products.isEmpty) {
        return {
          'status': 'success',
          'message': 'No warranty products found',
          'reminders_created': 0,
          'total_warranties': 0,
        };
      }

      int remindersCreated = 0;
      List<Map<String, dynamic>> failedReminders = [];

      for (final product in products) {
        try {
          // Parse expiry date
          DateTime? expiryDate;
          if (product['expiry_date'] != null) {
            try {
              expiryDate = DateTime.parse(product['expiry_date'].toString());
            } catch (e) {
              // Try warranty_end_date as backup
              if (product['warranty_end_date'] != null) {
                try {
                  expiryDate = DateTime.parse(product['warranty_end_date'].toString());
                } catch (e2) {
                  continue; // Skip products with invalid dates
                }
              } else {
                continue; // Skip products with invalid dates
              }
            }
          } else if (product['warranty_end_date'] != null) {
            try {
              expiryDate = DateTime.parse(product['warranty_end_date'].toString());
            } catch (e) {
              continue; // Skip products with invalid dates
            }
          }

          if (expiryDate == null) continue;

          // Skip expired products or products expiring too far in future (> 60 days)
          final now = DateTime.now();
          final daysUntilExpiry = expiryDate.difference(now).inDays;
          
          if (daysUntilExpiry < 0 || daysUntilExpiry > 60) {
            continue;
          }

          // Create calendar reminder
          final result = await GoogleCalendarService.createWarrantyReminder(
            productName: product['product_name'] ?? 'Unknown Product',
            brand: product['brand'] ?? 'Unknown Brand',
            expiryDate: expiryDate,
            warrantyPeriod: product['warranty_period']?.toString(),
            category: product['category']?.toString(),
          );

          if (result['status'] == 'success') {
            remindersCreated++;
          } else {
            failedReminders.add({
              'product': product['product_name'],
              'error': result['error_message'] ?? 'Unknown error',
            });
          }
        } catch (e) {
          failedReminders.add({
            'product': product['product_name'] ?? 'Unknown Product',
            'error': e.toString(),
          });
        }
      }

      return {
        'status': 'success',
        'message': 'Created $remindersCreated warranty reminders in your Google Calendar',
        'reminders_created': remindersCreated,
        'total_warranties': products.length,
        'failed_reminders': failedReminders,
        'success': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error creating warranty reminders: $e');
      }
      return {
        'status': 'error',
        'message': 'Error creating warranty reminders: ${e.toString()}',
        'success': false,
      };
    }
  }

  /// Test creating warranty reminders without OAuth (for testing)
  static Future<Map<String, dynamic>> testCreateAllWarrantyReminders(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/warranty-reminders/create-all-test/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to test warranty reminders: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error testing warranty reminders: $e');
      }
      throw Exception('Error testing warranty reminders: $e');
    }
  }

  /// Get warranty products with expiry information for display
  static Future<List<Map<String, dynamic>>> getWarrantyProducts(String userId) async {
    try {
      // URL encode the user ID to handle email addresses properly
      final encodedUserId = Uri.encodeComponent(userId);
      final response = await http.get(
        Uri.parse('$_baseUrl/warranty-reminders/warranty-products/$encodedUserId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['warranty_products'] ?? []);
      } else {
        throw Exception('Failed to get warranty products: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting warranty products: $e');
      }
      throw Exception('Error getting warranty products: $e');
    }
  }

  /// Create a single warranty reminder for a specific product using Google Calendar
  static Future<Map<String, dynamic>> createSingleWarrantyReminder(String userId, String productName) async {
    try {
      // First check if user has Google Calendar permissions
      final hasPermission = await GoogleCalendarService.hasCalendarPermission();
      if (!hasPermission) {
        return {
          'status': 'error',
          'error_message': 'Please sign in with Google to enable calendar reminders',
          'requires_google_signin': true,
        };
      }

      // Get warranty products from backend to find the specific product
      final products = await getWarrantyProducts(userId);
      
      // Find the specific product
      Map<String, dynamic>? targetProduct;
      for (final product in products) {
        if (product['product_name']?.toString().toLowerCase() == productName.toLowerCase()) {
          targetProduct = product;
          break;
        }
      }

      if (targetProduct == null) {
        return {
          'status': 'error',
          'error_message': 'Product "$productName" not found in warranty database',
        };
      }

      // Parse expiry date
      DateTime? expiryDate;
      if (targetProduct['expiry_date'] != null) {
        try {
          expiryDate = DateTime.parse(targetProduct['expiry_date'].toString());
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing expiry_date: $e');
          }
        }
      }
      
      // Also try warranty_end_date field as backup
      if (expiryDate == null && targetProduct['warranty_end_date'] != null) {
        try {
          expiryDate = DateTime.parse(targetProduct['warranty_end_date'].toString());
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing warranty_end_date: $e');
          }
        }
      }

      if (kDebugMode) {
        print('Product: $productName');
        print('Raw expiry_date: ${targetProduct['expiry_date']}');
        print('Raw warranty_end_date: ${targetProduct['warranty_end_date']}');
        print('Parsed expiry date: $expiryDate');
      }

      if (expiryDate == null) {
        return {
          'status': 'error',
          'error_message': 'No valid expiry date found for $productName',
        };
      }

      // Create calendar reminder using Google Calendar API
      final result = await GoogleCalendarService.createWarrantyReminder(
        productName: targetProduct['product_name'] ?? productName,
        brand: targetProduct['brand'] ?? 'Unknown Brand',
        expiryDate: expiryDate,
        warrantyPeriod: targetProduct['warranty_period']?.toString(),
        category: targetProduct['category']?.toString(),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating single reminder: $e');
      }
      return {
        'status': 'error',
        'error_message': 'Error creating reminder: ${e.toString()}',
      };
    }
  }

  /// Get upcoming warranty reminders
  static Future<List<Map<String, dynamic>>> getUpcomingWarrantyReminders(String userId) async {
    try {
      // URL encode the user ID to handle email addresses properly
      final encodedUserId = Uri.encodeComponent(userId);
      final response = await http.get(
        Uri.parse('$_baseUrl/warranty-reminders/upcoming/?user_id=$encodedUserId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
      } else {
        throw Exception('Failed to get upcoming reminders: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting upcoming reminders: $e');
      }
      throw Exception('Error getting upcoming reminders: $e');
    }
  }

  /// Check the health of the warranty reminder service
  static Future<bool> checkServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/warranty-reminders/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Warranty reminder service health check failed: $e');
      }
      return false;
    }
  }
}
