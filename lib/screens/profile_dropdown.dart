import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileDropdown extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  const ProfileDropdown({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
  });

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  
  // User data state
  Map<String, dynamic>? _userData;
  bool _isLoadingData = false;
  
  // Static cache to preserve data across theme changes
  static Map<String, dynamic>? _cachedUserData;
  static bool _hasInitialLoad = false;
  static String? _cachedUserId; // Track which user the cache belongs to

  @override
  void initState() {
    super.initState();
    
    // Check if the current user matches the cached user
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserId = currentUser?.uid;
    
    // Clear cache if user has changed or no user
    if (currentUserId != _cachedUserId) {
      print('ProfileDropdown: User changed, clearing cache. Old: $_cachedUserId, New: $currentUserId');
      _clearCache();
    }
    
    // Use cached data if available to avoid reloading on theme changes
    if (_cachedUserData != null && _hasInitialLoad && currentUserId == _cachedUserId) {
      print('ProfileDropdown: Using cached user data');
      _userData = _cachedUserData;
    } else {
      print('ProfileDropdown: Initial load required');
      _loadUserData();
    }
  }
  
  /// Clear the static cache
  static void _clearCache() {
    _cachedUserData = null;
    _hasInitialLoad = false;
    _cachedUserId = null;
  }
  
  /// Public method to clear cache (e.g., when user signs out)
  static void clearCache() {
    _clearCache();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  /// Load user profile data from Firebase
  Future<void> _loadUserData() async {
    if (_isLoadingData) return;
    
    print('ProfileDropdown: Starting to load user data...');
    setState(() {
      _isLoadingData = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('ProfileDropdown: No user found, using default data');
        Map<String, dynamic> defaultData = _getDefaultUserData();
        if (mounted) {
          setState(() {
            _userData = defaultData;
            _isLoadingData = false;
            
            // Update cache with default data (no user ID)
            _cachedUserData = defaultData;
            _cachedUserId = null;
            _hasInitialLoad = true;
          });
        }
        return;
      }

      String userEmail = user.email!;
      print('ProfileDropdown: Loading data for user: $userEmail');
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get user info from users collection
      print('ProfileDropdown: Fetching user document...');
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(userEmail)
          .get();

      Map<String, dynamic> userInfo = {};
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userInfo = userData['_user_info'] ?? {};
        print('ProfileDropdown: User document found with data: $userInfo');
      } else {
        print('ProfileDropdown: User document does not exist');
      }

      // Get knowledge graphs count
      print('ProfileDropdown: Fetching knowledge graphs...');
      QuerySnapshot kgSnapshot = await firestore
          .collection('users')
          .doc(userEmail)
          .collection('knowledge_graphs')
          .get();

      int knowledgeGraphsCount = kgSnapshot.docs.length;
      print('ProfileDropdown: Found $knowledgeGraphsCount knowledge graphs');

      // Calculate total spending and receipts from knowledge graphs
      double totalSpent = 0.0;
      int receiptsCount = 0;
      double thisMonthSpent = 0.0;
      DateTime now = DateTime.now();
      String currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      for (var doc in kgSnapshot.docs) {
        Map<String, dynamic> kgData = doc.data() as Map<String, dynamic>;
        
        // Extract spending from knowledge graph data
        Map<String, dynamic>? data = kgData['data'];
        if (data != null) {
          double amount = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          totalSpent += amount;
          receiptsCount++;

          // Check if this is from current month
          String? createdAt = data['created_at'];
          if (createdAt != null && createdAt.startsWith(currentMonth)) {
            thisMonthSpent += amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _userData = {
            'name': userInfo['name'] ?? userEmail.split('@')[0],
            'email': userEmail,
            'knowledgeGraphsCount': knowledgeGraphsCount,
            'totalSpent': totalSpent,
            'receiptsCount': receiptsCount,
            'thisMonthSpent': thisMonthSpent,
            'receiptsScanned': userInfo['receipts_scanned'] ?? receiptsCount,
            'lastActivity': userInfo['last_activity'],
            'createdAt': userInfo['created_at'],
          };
          _isLoadingData = false;
          
          // Update cache with user ID
          _cachedUserData = _userData;
          _cachedUserId = user.uid;
          _hasInitialLoad = true;
        });
      }
      
      print('ProfileDropdown: Successfully loaded user data: $_userData');
    } catch (e) {
      print('ProfileDropdown: Error loading user data: $e');
      User? user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> defaultData = _getDefaultUserData();
      if (mounted) {
        setState(() {
          _userData = defaultData;
          _isLoadingData = false;
          
          // Update cache with default data and user ID
          _cachedUserData = defaultData;
          _cachedUserId = user?.uid;
          _hasInitialLoad = true;
        });
      }
    }
  }

  /// Get default/fallback user data
  Map<String, dynamic> _getDefaultUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    return {
      'name': user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
      'email': user?.email ?? '',
      'knowledgeGraphsCount': 0,
      'totalSpent': 0.0,
      'receiptsCount': 0,
      'thisMonthSpent': 0.0,
      'receiptsScanned': 0,
      'lastActivity': null,
      'createdAt': null,
    };
  }

  void _toggleDropdown() {
    print('ProfileDropdown: Toggle dropdown called, current state: $_isOpen');
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
      // Only refresh data if we don't have any data yet or if explicitly requested
      if (_userData == null && !_isLoadingData) {
        print('ProfileDropdown: Opening dropdown and loading initial data...');
        _loadUserData();
      }
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to detect outside clicks
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown
          Positioned(
            left: offset.dx - 280 + size.width, // Align to right edge
            top: offset.dy + size.height + 8,
            width: 320,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User Info Section
                    _buildUserSection(),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Statistics Section
                    _buildStatsSection(),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Actions Section
                    _buildActionsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    final user = AuthService.currentUser;
    
    // Use real data if available, with safe fallbacks
    String displayName;
    String email;
    
    if (_userData?['name'] != null && _userData!['name'].toString().isNotEmpty) {
      displayName = _userData!['name'];
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      displayName = user.email!.split('@')[0];
    } else {
      displayName = 'User';
    }
    
    if (_userData?['email'] != null && _userData!['email'].toString().isNotEmpty) {
      email = _userData!['email'];
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      email = user.email!;
    } else {
      email = '';
    }
    
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1A73E8),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    // Show loading or real data
    if (_isLoadingData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    // Get data with safe fallbacks
    final knowledgeGraphs = (_userData?['knowledgeGraphsCount'] as num?)?.toInt() ?? 0;
    final totalSpent = (_userData?['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final receiptsCount = (_userData?['receiptsCount'] as num?)?.toInt() ?? 0;
    final thisMonthSpent = (_userData?['thisMonthSpent'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Summary',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatItem('Knowledge Graphs', knowledgeGraphs.toString(), Icons.hub_outlined)),
            Expanded(child: _buildStatItem('Total Spent', '\$${totalSpent.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatItem('Receipts', receiptsCount.toString(), Icons.receipt_outlined)),
            Expanded(child: _buildStatItem('This Month', '\$${thisMonthSpent.toStringAsFixed(2)}', Icons.calendar_today_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        _buildActionButton(
          'Refresh Data',
          Icons.refresh,
          () async {
            // Force reload by clearing cache and reloading
            _clearCache();
            await _loadUserData();
          },
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'Toggle Theme',
          widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
          widget.onThemeToggle,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'Sign Out',
          Icons.logout,
              () async {
            _closeDropdown();
            await AuthService.signOut();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    
    // Provide safe fallbacks for display name
    String displayName;
    if (_userData?['name'] != null && _userData!['name'].toString().isNotEmpty) {
      displayName = _userData!['name'];
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      displayName = user.email!.split('@')[0];
    } else {
      displayName = 'User';
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A73E8),
            border: Border.all(
              color: _isOpen
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
      ),
    );
  }
}