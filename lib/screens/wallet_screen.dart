import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import '../models/wallet_models.dart';
import '../widgets/wallet_item_card.dart';
import '../utils/device_compatibility.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<WalletEligibleItem> _allItems = [];
  List<WalletEligibleItem> _receipts = [];
  List<WalletEligibleItem> _warranties = [];

  bool _isLoading = true;
  bool _isHealthy = false;
  String? _error;
  String? _loadingItemId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkServiceHealth();
    _loadEligibleItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkServiceHealth() async {
    final isHealthy = await WalletService.checkHealth();
    setState(() {
      _isHealthy = isHealthy;
    });
  }

  Future<void> _loadEligibleItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      String kgUserId = "sample@gmail.com"; // Default fallback
      if (user.email != null) {
        kgUserId = user.email!;
      }

      final response = await WalletService.getEligibleItems(kgUserId);

      if (response.success) {
        setState(() {
          _allItems = response.items;
          _receipts = response.items.where((item) => item.isReceipt).toList();
          _warranties = response.items.where((item) => item.isWarranty).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load eligible items';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading items: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToWallet(WalletEligibleItem item) async {
    // Check device compatibility first
    final deviceInfo = await DeviceCompatibility.getDeviceInfo();
    if (!deviceInfo.isSupported) {
      _showErrorDialog('Device Compatibility Issue: ${deviceInfo.reason}');
      return;
    }

    setState(() {
      _loadingItemId = item.id;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        _showErrorDialog('User not authenticated');
        return;
      }

      String kgUserId = "sample@gmail.com";
      if (user.email != null) {
        kgUserId = user.email!;
      }

      // Check if user is in test user list for demo mode
      final isTestUser = _isTestUser(kgUserId);
      
      final response = await WalletService.generatePass(
        itemId: item.id,
        passType: item.itemType,
        userId: kgUserId,
      );

      if (response.success && response.walletUrl != null) {
        final uri = Uri.parse(response.walletUrl!);
        if (await canLaunchUrl(uri)) {
          // Launch Google Wallet URL
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Wait a moment for the user to potentially add the pass
          await Future.delayed(const Duration(seconds: 2));

          // Show dialog asking if pass was successfully added
          if (mounted) {
            final wasAdded = await _showPassAddedConfirmation(isTestUser);
            if (wasAdded) {
              setState(() {
                final index = _allItems.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _allItems[index] = WalletEligibleItem(
                    id: item.id,
                    title: item.title,
                    subtitle: item.subtitle,
                    itemType: item.itemType,
                    receiptId: item.receiptId,
                    merchantName: item.merchantName,
                    totalAmount: item.totalAmount,
                    currency: item.currency,
                    transactionDate: item.transactionDate,
                    itemCount: item.itemCount,
                    productName: item.productName,
                    brand: item.brand,
                    warrantyPeriod: item.warrantyPeriod,
                    expiryDate: item.expiryDate,
                    purchaseDate: item.purchaseDate,
                    addedToWallet: true,
                    walletPassId: response.passId,
                    createdAt: item.createdAt,
                  );
                  _receipts = _allItems.where((item) => item.isReceipt).toList();
                  _warranties = _allItems.where((item) => item.isWarranty).toList();
                }
              });
              
              _showSuccessDialog('Pass added to Google Wallet successfully!');
            }
          }
        } else {
          _showErrorDialog('Could not open Google Wallet. This may be due to Demo Mode restrictions.');
        }
      } else {
        _showErrorDialog(response.error ?? 'Failed to generate wallet pass');
      }
    } catch (e) {
      _showErrorDialog('Error adding to wallet: $e');
    } finally {
      setState(() {
        _loadingItemId = null;
      });
    }
  }

  // Check if current user is in the test users list
  bool _isTestUser(String email) {
    final testUsers = [
      'suganthpubg@gmail.com', // Your email
      'sample@gmail.com',
      // Add more test users here
    ];
    return testUsers.contains(email.toLowerCase());
  }

  Future<bool> _showPassAddedConfirmation(bool isTestUser) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTestUser 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTestUser ? Icons.verified_user_rounded : Icons.warning_rounded,
                color: isTestUser 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isTestUser ? 'Test User Access' : 'Demo Mode',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isTestUser 
            ? '✅ You are authorized as a test user!\n\n'
              'You can add passes to your Google Wallet during the demo period.\n\n'
              'Did you successfully add the pass?'
            : '⚠️ Your Google Wallet API is currently in Demo Mode.\n\n'
              '✅ Testing Mode: Pass creation is simulated\n'
              '⏳ Production Access: Being requested from Google\n\n'
              'For now, would you like to simulate adding this pass?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTestUser ? 'Yes, added successfully' : 'Simulate Add'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWalletInfo() {
    final user = AuthService.currentUser;
    final userEmail = user?.email ?? 'Unknown';
    final isTestUser = _isTestUser(userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wallet, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Google Wallet Status'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTestUser ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTestUser ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isTestUser ? Icons.verified_user : Icons.warning,
                      color: isTestUser ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTestUser 
                          ? 'You are a verified test user!'
                          : 'Demo Mode - Limited Access',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isTestUser ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🔧 Current Status: Demo Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (isTestUser) ...[
                const Text(
                  '✅ Your account has test access:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• You can add real passes to Google Wallet'),
                const Text('• Passes will show "[TEST ONLY]" prefix'),
                const Text('• Full functionality during demo period'),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'Your Google Wallet API is currently in Demo Mode:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text('• Only test users can add passes'),
                const Text('• Passes show "[TEST ONLY]" prefix'),
                const Text('• Limited to authorized accounts'),
                const SizedBox(height: 16),
              ],
              const Text(
                '🚀 To Enable for All Users:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('1. Complete Business Profile'),
              const Text('2. Create Pass Classes'),
              const Text('3. Request Publishing Access'),
              const Text('4. Wait for Google approval'),
              const SizedBox(height: 16),
              const Text(
                '⏳ Expected Timeline: 1-2 weeks',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Text(
                'Current user: $userEmail',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open Google Wallet Console
            },
            child: const Text('Open Console'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Success',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text(
              'Wallet',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            pinned: true,
            floating: true,
            actions: [
              // Health Status Indicator
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isHealthy 
                      ? Theme.of(context).colorScheme.primaryContainer 
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isHealthy ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: _isHealthy 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isHealthy ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _isHealthy 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: _showWalletInfo,
                tooltip: 'Wallet Information',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadEligibleItems,
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.receipt_rounded, size: 20),
                      text: 'Receipts (${_receipts.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.shield_rounded, size: 20),
                      text: 'Warranties (${_warranties.length})',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading eligible items...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _loadEligibleItems,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildItemsList(_receipts, 'No receipts available'),
                      _buildItemsList(_warranties, 'No warranties available'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildItemsList(List<WalletEligibleItem> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inbox_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Process some receipts to see eligible items here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add receipts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEligibleItems,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WalletItemCard(
              item: item,
              onAddToWallet: () => _addToWallet(item),
              isLoading: _loadingItemId == item.id,
            ),
          );
        },
      ),
    );
  }
}
