import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/warranty_reminder_service.dart';

class WarrantyReminderCard extends StatefulWidget {
  final String userId;
  
  const WarrantyReminderCard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<WarrantyReminderCard> createState() => _WarrantyReminderCardState();
}

class _WarrantyReminderCardState extends State<WarrantyReminderCard> 
    with SingleTickerProviderStateMixin {
  
  static const Color _googleBlue = Color(0xFF1976D2);
  static const Color _googleGreen = Color(0xFF0F9D58);
  static const Color _googleRed = Color(0xFFDB4437);
  static const Color _googleSurface = Color(0xFFF8F9FA);
  
  bool _isCreatingReminders = false;
  bool _isCheckingUpcoming = false;
  List<Map<String, dynamic>> _upcomingExpirations = [];
  int _totalRemindersCreated = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUpcomingExpirations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingExpirations() async {
    if (!mounted) return;
    
    setState(() {
      _isCheckingUpcoming = true;
    });

    try {
      final result = await WarrantyReminderService.getUpcomingWarrantyExpirations(
        widget.userId,
        daysAhead: 30
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _upcomingExpirations = List<Map<String, dynamic>>.from(
            result['upcoming_expirations'] ?? []
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load upcoming expirations: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpcoming = false;
        });
      }
    }
  }

  Future<void> _createAllReminders() async {
    if (_isCreatingReminders) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isCreatingReminders = true;
      _totalRemindersCreated = 0;
    });

    _animationController.repeat(reverse: true);

    try {
      final result = await WarrantyReminderService.createAllWarrantyReminders(
        widget.userId
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _totalRemindersCreated = result['reminders_created'] ?? 0;
        });
        
        _showSnackBar(
          'Created ${_totalRemindersCreated} warranty reminders in your calendar!',
          isError: false
        );
        
        // Reload upcoming expirations to reflect changes
        await _loadUpcomingExpirations();
      } else {
        _showSnackBar('Failed to create reminders', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error creating reminders: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReminders = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? _googleRed : _googleGreen,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _googleSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _googleSurface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _googleBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: _googleBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warranty Reminders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get notified 2 days before expiry',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCheckingUpcoming)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Upcoming Expirations Summary
            if (_upcomingExpirations.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, 
                             color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_upcomingExpirations.length} Warranties Expiring Soon',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_upcomingExpirations.take(3).map((warranty) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${warranty['product_name']} (${warranty['days_until_expiry']} days left)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                    )),
                    if (_upcomingExpirations.length > 3)
                      Text(
                        '... and ${_upcomingExpirations.length - 3} more',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isCreatingReminders ? _pulseAnimation.value : 1.0,
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingReminders ? null : _createAllReminders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _googleBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isCreatingReminders ? 0 : 2,
                      ),
                      icon: _isCreatingReminders
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.notifications_active_rounded),
                      label: Text(
                        _isCreatingReminders
                            ? 'Creating Reminders...'
                            : _upcomingExpirations.isEmpty
                                ? 'Check for Warranty Reminders'
                                : 'Create Calendar Reminders',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Success Message
            if (_totalRemindersCreated > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _googleGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _googleGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, 
                         color: _googleGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Created $_totalRemindersCreated reminders in your Google Calendar',
                      style: TextStyle(
                        color: _googleGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Info Text
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reminders will be created in your Google Calendar 2 days before warranty expiration',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
