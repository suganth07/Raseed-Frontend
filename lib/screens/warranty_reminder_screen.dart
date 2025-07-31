import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/warranty_reminder_service.dart';

class WarrantyReminderScreen extends StatefulWidget {
  final String userId;

  const WarrantyReminderScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _WarrantyReminderScreenState createState() => _WarrantyReminderScreenState();
}

class _WarrantyReminderScreenState extends State<WarrantyReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _warrantyProducts = [];
  bool _isLoading = true;
  Set<String> _creatingReminders = {};
  Map<String, String> _createdReminders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWarrantyProducts();
    _loadRemindersFromStorage();
  }

  Future<void> _loadRemindersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString('warranty_reminders_${widget.userId}');
      if (remindersJson != null) {
        final Map<String, dynamic> remindersMap = json.decode(remindersJson);
        setState(() {
          _createdReminders = Map<String, String>.from(remindersMap);
        });
      }
    } catch (e) {
      print('Error loading reminders from storage: $e');
    }
  }

  Future<void> _saveRemindersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = json.encode(_createdReminders);
      await prefs.setString('warranty_reminders_${widget.userId}', remindersJson);
    } catch (e) {
      print('Error saving reminders to storage: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWarrantyProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await WarrantyReminderService.getWarrantyProducts(widget.userId);
      print('DEBUG: Loaded ${products.length} warranty products');
      for (var i = 0; i < products.length && i < 3; i++) {
        print('DEBUG: Product $i: ${products[i]}');
      }
      setState(() {
        _warrantyProducts = products;
      });
    } catch (e) {
      print('DEBUG: Error loading warranty products: $e');
      Fluttertoast.showToast(
        msg: "Error loading warranty products: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _expiredWarranties {
    return _warrantyProducts.where((product) {
      // Check both possible expiry date fields
      String? expiryDateStr = product['warranty_end_date'] ?? product['expiry_date'];
      if (expiryDateStr == null) return false;
      try {
        DateTime endDate = DateTime.parse(expiryDateStr);
        return endDate.isBefore(DateTime.now());
      } catch (e) {
        print('DEBUG: Error parsing date for ${product['product_name']}: $expiryDateStr');
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _activeWarranties {
    return _warrantyProducts.where((product) {
      // Check both possible expiry date fields
      String? expiryDateStr = product['warranty_end_date'] ?? product['expiry_date'];
      if (expiryDateStr == null) return true;
      try {
        DateTime endDate = DateTime.parse(expiryDateStr);
        return endDate.isAfter(DateTime.now());
      } catch (e) {
        print('DEBUG: Error parsing date for ${product['product_name']}: $expiryDateStr');
        return true;
      }
    }).toList();
  }

  Future<void> _createSingleReminder(String productName) async {
    setState(() {
      _creatingReminders.add(productName);
    });

    try {
      final result = await WarrantyReminderService.createSingleWarrantyReminder(widget.userId, productName);
      
      if (result['status'] == 'success') {
        String reminderDate = '';
        if (result['event_details'] != null && result['event_details']['start'] != null) {
          try {
            DateTime startDate = DateTime.parse(result['event_details']['start']);
            reminderDate = "${startDate.day}/${startDate.month}/${startDate.year}";
          } catch (e) {
            reminderDate = 'today';
          }
        } else {
          reminderDate = 'set';
        }
        
        setState(() {
          _createdReminders[productName] = reminderDate;
        });
        
        // Save to persistent storage
        await _saveRemindersToStorage();
        
        Fluttertoast.showToast(
          msg: "✅ Calendar reminder created for $productName!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else if (result['requires_google_signin'] == true) {
        Fluttertoast.showToast(
          msg: "🔑 Please sign in with Google to enable calendar reminders",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        _showGoogleSignInDialog();
      } else {
        throw Exception(result['error_message'] ?? 'Unknown error');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error creating reminder for $productName: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _creatingReminders.remove(productName);
      });
    }
  }

  void _showGoogleSignInDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Google Sign-In Required'),
          content: const Text(
            'To create calendar reminders, please sign in with your Google account. This will give the app permission to create events in your Google Calendar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Sign In with Google'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAllReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await WarrantyReminderService.createAllWarrantyReminders(widget.userId);
      
      if (result['status'] == 'success') {
        Fluttertoast.showToast(
          msg: "✅ Created ${result['reminders_created']} calendar reminders!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        throw Exception(result['error_message'] ?? 'Unknown error');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error creating reminders: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Warranty Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        actions: [
          if (_warrantyProducts.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _createAllReminders,
              icon: Icon(Icons.schedule, color: Theme.of(context).primaryColor),
              label: Text(
                'Set All',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Active (${_activeWarranties.length})',
            ),
            Tab(
              icon: const Icon(Icons.error_outline),
              text: 'Expired (${_expiredWarranties.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWarrantyList(_activeWarranties, false, isDark),
          _buildWarrantyList(_expiredWarranties, true, isDark),
        ],
      ),
    );
  }

  Widget _buildWarrantyList(List<Map<String, dynamic>> warranties, bool isExpired, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (warranties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpired ? Icons.check_circle : Icons.schedule,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isExpired ? 'No expired warranties' : 'No active warranties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                ? 'All your warranties are still active!'
                : 'Process some receipts to see warranty items here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: warranties.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeaderCard(isExpired, isDark);
        }

        final product = warranties[index - 1];
        return _buildWarrantyCard(product, isDark);
      },
    );
  }

  Widget _buildHeaderCard(bool isExpired, bool isDark) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.error : Icons.info,
                  color: isExpired ? Colors.red : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired ? 'Expired Warranties' : 'Active Warranties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                ? 'These warranties have expired. While reminders cannot be set for expired items, you can still review their details.'
                : 'Set calendar reminders for your active warranties. You\'ll be notified 2 days before they expire.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyCard(Map<String, dynamic> product, bool isDark) {
    final productName = product['product_name'] ?? 'Unknown Product';
    final isCreating = _creatingReminders.contains(productName);
    final hasReminder = _createdReminders.containsKey(productName);
    final daysUntilExpiry = product['days_until_expiry'];
    final isExpired = daysUntilExpiry != null && daysUntilExpiry < 0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (product['brand'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Brand: ${product['brand']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isExpired) ...[
                  if (hasReminder)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Reminder Set',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: isCreating ? null : () => _createSingleReminder(productName),
                      icon: isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.schedule, size: 16),
                      label: Text(isCreating ? 'Setting...' : 'Set Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildWarrantyDetails(product, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyDetails(Map<String, dynamic> product, bool isDark) {
    final daysUntilExpiry = product['days_until_expiry'];
    final statusColor = _getStatusColor(daysUntilExpiry);
    final statusText = _getStatusText(daysUntilExpiry);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['warranty_period'] != null) ...[
                  Text(
                    'Warranty: ${product['warranty_period']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (product['warranty_end_date'] != null || product['expiry_date'] != null) ...[
                  Text(
                    'Expires: ${_formatDate(product['warranty_end_date'] ?? product['expiry_date'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int? daysUntilExpiry) {
    if (daysUntilExpiry == null) return Colors.grey;
    if (daysUntilExpiry < 0) return Colors.red;
    if (daysUntilExpiry <= 7) return Colors.orange;
    if (daysUntilExpiry <= 30) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getStatusText(int? daysUntilExpiry) {
    if (daysUntilExpiry == null) return 'No expiry date';
    if (daysUntilExpiry < 0) return 'Expired';
    if (daysUntilExpiry == 0) return 'Expires today';
    if (daysUntilExpiry == 1) return 'Expires tomorrow';
    if (daysUntilExpiry <= 7) return '$daysUntilExpiry days left';
    return '$daysUntilExpiry days left';
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
