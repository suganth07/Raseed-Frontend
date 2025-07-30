import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import '../models/wallet_models.dart';
import '../widgets/wallet_item_card.dart';

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

      final response = await WalletService.generatePass(
        itemId: item.id,
        passType: item.itemType,
        userId: kgUserId,
      );

      if (response.success && response.walletUrl != null) {
        final uri = Uri.parse(response.walletUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

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
              _receipts =
                  _allItems.where((item) => item.isReceipt).toList();
              _warranties =
                  _allItems.where((item) => item.isWarranty).toList();
            }
          });

          _showSuccessDialog('Pass added to Google Wallet successfully!');
        } else {
          _showErrorDialog('Could not open Google Wallet');
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
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
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Google Wallet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2), // <-- GOOGLE BLUE
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isHealthy ? Icons.cloud_done : Icons.cloud_off,
                  color: _isHealthy ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _isHealthy ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEligibleItems,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt),
              text: 'Receipts (${_receipts.length})',
            ),
            Tab(
              icon: const Icon(Icons.shield),
              text: 'Warranties (${_warranties.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)), // <-- GOOGLE BLUE
            ),
            SizedBox(height: 16),
            Text(
              'Loading eligible items...',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFE53E3E),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEligibleItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2), // <-- GOOGLE BLUE
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // Receipts Tab
          _buildItemsList(_receipts, 'No receipts available'),
          // Warranties Tab
          _buildItemsList(_warranties, 'No warranties available'),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<WalletEligibleItem> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 64,
              color: Color(0xFFA0AEC0),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Process some receipts to see eligible items here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEligibleItems,
      color: const Color(0xFF1976D2), // <-- GOOGLE BLUE
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return WalletItemCard(
            item: item,
            onAddToWallet: () => _addToWallet(item),
            isLoading: _loadingItemId == item.id,
          );
        },
      ),
    );
  }
}
