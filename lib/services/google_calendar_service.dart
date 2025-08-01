import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class GoogleCalendarService {
  static const String _calendarApiUrl = 'https://www.googleapis.com/calendar/v3';

  /// Create a calendar event using the user's Google access token
  static Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? location,
  }) async {
    try {
      // Get the user's Google access token
      final String? accessToken = await AuthService.getGoogleAccessToken();
      
      if (accessToken == null) {
        throw Exception('No Google access token available. Please sign in with Google.');
      }

      // Prepare the event data
      final eventData = {
        'summary': title,
        'description': description,
        'start': {
          'dateTime': startDateTime.toIso8601String(),
          'timeZone': 'Asia/Kolkata', // Adjust timezone as needed
        },
        'end': {
          'dateTime': endDateTime.toIso8601String(),
          'timeZone': 'Asia/Kolkata',
        },
        if (location != null) 'location': location,
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 60}, // 1 hour before
            {'method': 'popup', 'minutes': 1440}, // 1 day before
          ],
        },
      };

      // Make the API call to create the event
      final response = await http.post(
        Uri.parse('$_calendarApiUrl/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(eventData),
      );

      if (response.statusCode == 200) {
        final eventResponse = json.decode(response.body);
        
        return {
          'status': 'success',
          'message': 'Calendar event created successfully',
          'event_id': eventResponse['id'],
          'event_link': eventResponse['htmlLink'],
          'event_details': {
            'start': eventResponse['start']['dateTime'],
            'end': eventResponse['end']['dateTime'],
            'summary': eventResponse['summary'],
          },
        };
      } else {
        if (kDebugMode) {
          print('Calendar API Error: ${response.statusCode} - ${response.body}');
        }
        
        // Handle specific error cases
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        
        return {
          'status': 'error',
          'error_message': 'Failed to create calendar event: $errorMessage',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating calendar event: $e');
      }
      
      return {
        'status': 'error',
        'error_message': 'Error creating calendar event: ${e.toString()}',
      };
    }
  }

  /// Create a warranty reminder event
  static Future<Map<String, dynamic>> createWarrantyReminder({
    required String productName,
    required String brand,
    required DateTime expiryDate,
    String? warrantyPeriod,
    String? category,
  }) async {
    try {
      // Calculate reminder date (2 days before expiry)
      final reminderDate = expiryDate.subtract(Duration(days: 2));
      
      // For debugging - let's be more lenient with date checking
      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day); // Strip time component
      final reminderDateOnly = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
      
      if (kDebugMode) {
        print('Expiry Date: $expiryDate');
        print('Reminder Date: $reminderDate');
        print('Current Date: $currentDate');
        print('Reminder Date Only: $reminderDateOnly');
        print('Is reminder in past: ${reminderDateOnly.isBefore(currentDate)}');
      }
      
      // Don't create reminders for past dates (comparing date only, not time)
      if (reminderDateOnly.isBefore(currentDate)) {
        return {
          'status': 'error',
          'error_message': 'Cannot create reminder for past dates. Expiry: ${_formatDate(expiryDate)}, Reminder would be: ${_formatDate(reminderDate)}',
        };
      }

      final title = '🛡️ Warranty Expiring Soon: $productName';
      final description = '''
🛡️ WARRANTY EXPIRATION REMINDER

Product: $productName
Brand: $brand
${warrantyPeriod != null ? 'Warranty Period: $warrantyPeriod\n' : ''}${category != null ? 'Category: $category\n' : ''}Expiry Date: ${_formatDate(expiryDate)}

⚠️ Your warranty will expire in 2 days!
📋 Keep your receipt and warranty card handy
📞 Contact customer service if needed

Generated by Raseed - Your Smart Receipt Manager
      '''.trim();

      // Set reminder time to 9 AM
      final reminderDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // 9 AM
        0,
      );

      final endDateTime = reminderDateTime.add(Duration(hours: 1));

      return await createCalendarEvent(
        title: title,
        description: description,
        startDateTime: reminderDateTime,
        endDateTime: endDateTime,
      );
    } catch (e) {
      return {
        'status': 'error',
        'error_message': 'Error creating warranty reminder: ${e.toString()}',
      };
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Check if the user has calendar permissions
  static Future<bool> hasCalendarPermission() async {
    return await AuthService.hasCalendarPermission();
  }

  /// Get user's calendar list (optional feature)
  static Future<List<Map<String, dynamic>>> getUserCalendars() async {
    try {
      final String? accessToken = await AuthService.getGoogleAccessToken();
      
      if (accessToken == null) {
        throw Exception('No Google access token available');
      }

      final response = await http.get(
        Uri.parse('$_calendarApiUrl/users/me/calendarList'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        throw Exception('Failed to get calendars: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user calendars: $e');
      }
      return [];
    }
  }
}
