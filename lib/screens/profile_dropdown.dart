import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/profile_refresh.dart';

class ProfileDropdown extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const ProfileDropdown({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<ProfileDropdown> createState() => ProfileDropdownState();
}

class ProfileDropdownState extends State<ProfileDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isLoadingData = false;
  Map<String, dynamic>? _userData;

  // Static cache variables
  static Map<String, dynamic>? _cachedUserData;
  static String? _cachedUserId;
  static bool _hasInitialLoad = false;

  @override
  void initState() {
    super.initState();
    ProfileRefresh.addListener(_handleProfileRefresh);
  }

  @override
  void dispose() {
    ProfileRefresh.removeListener(_handleProfileRefresh);
    _closeDropdown();
    super.dispose();
  }

  void _handleProfileRefresh() {
    if (mounted) {
      _clearCache();
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    // Check if we should use cached data
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid;

    if (_cachedUserData != null && _cachedUserId == currentUserId && _hasInitialLoad) {
      setState(() {
        _userData = _cachedUserData;
        _isLoadingData = false;
      });
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      if (user == null) {
        Map<String, dynamic> defaultData = _getDefaultUserData();
        setState(() {
          _userData = defaultData;
          _isLoadingData = false;
          _cachedUserData = defaultData;
          _cachedUserId = null;
          _hasInitialLoad = true;
        });
        return;
      }

      String userEmail = user.email ?? 'Unknown';

      // Get receipt count and total amount from knowledgeGraphs collection
      QuerySnapshot kgSnapshot = await FirebaseFirestore.instance
          .collection('knowledgeGraphs')
          .where('email', isEqualTo: userEmail)
          .get();

      int actualKgCount = kgSnapshot.docs.length;
      double totalSpent = 0.0;
      double thisMonthSpent = 0.0;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in kgSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        if (data['totalAmount'] != null) {
          double amount = (data['totalAmount'] as num).toDouble();
          totalSpent += amount;
          
          // Check if this receipt is from this month
          if (data['date'] != null) {
            try {
              DateTime receiptDate;
              if (data['date'] is Timestamp) {
                receiptDate = (data['date'] as Timestamp).toDate();
              } else if (data['date'] is String) {
                receiptDate = DateTime.parse(data['date']);
              } else {
                continue;
              }
              
              if (receiptDate.isAfter(startOfMonth)) {
                thisMonthSpent += amount;
              }
            } catch (e) {
              // Skip if date parsing fails
              continue;
            }
          }
        }
      }

      // Create user data with actual counts
      Map<String, dynamic> userData = {
        'name': user.displayName ?? 'User',
        'email': userEmail,
        'knowledgeGraphsCount': actualKgCount,
        'receiptsCount': actualKgCount,
        'totalSpent': totalSpent,
        'thisMonthSpent': thisMonthSpent,
      };

      setState(() {
        _userData = userData;
        _isLoadingData = false;
        _cachedUserData = userData;
        _cachedUserId = user.uid;
        _hasInitialLoad = true;
      });
    } catch (e) {
      User? user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> defaultData = _getDefaultUserData();
      if (mounted) {
        setState(() {
          _userData = defaultData;
          _isLoadingData = false;
          _cachedUserData = defaultData;
          _cachedUserId = user?.uid;
          _hasInitialLoad = true;
        });
      }
    }
  }

  void _clearCache() {
    _cachedUserData = null;
    _hasInitialLoad = false;
    _cachedUserId = null;
  }

  Map<String, dynamic> _getDefaultUserData() {
    return {
      'name': 'User',
      'email': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      'knowledgeGraphsCount': 0,
      'receiptsCount': 0,
      'totalSpent': 0.0,
      'thisMonthSpent': 0.0,
    };
  }

  void toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_userData == null && !_isLoadingData) {
      _loadUserData();
    }

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
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 8,
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: _buildDropdownContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserInfo(),
          const SizedBox(height: 16),
          _buildUserStats(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    String displayName = 'User';
    String email = 'Unknown';

    if (_userData?['name'] != null && _userData!['name'].toString().isNotEmpty) {
      displayName = _userData!['name'];
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      }
    }

    if (_userData?['email'] != null && _userData!['email'].toString().isNotEmpty) {
      email = _userData!['email'];
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        email = user!.email!;
      }
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    if (_isLoadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final knowledgeGraphs = (_userData?['knowledgeGraphsCount'] as num?)?.toInt() ?? 0;
    final totalSpent = (_userData?['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final receiptsCount = (_userData?['receiptsCount'] as num?)?.toInt() ?? 0;
    final thisMonthSpent = (_userData?['thisMonthSpent'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Activity',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildStatRow(
                icon: Icons.receipt_long,
                label: 'Receipts Processed',
                value: receiptsCount.toString(),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.analytics,
                label: 'Knowledge Graphs',
                value: knowledgeGraphs.toString(),
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.attach_money,
                label: 'Total Spending',
                value: '\$${totalSpent.toStringAsFixed(2)}',
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.calendar_month,
                label: 'This Month',
                value: '\$${thisMonthSpent.toStringAsFixed(2)}',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh,
                label: 'Refresh',
                onPressed: () async {
                  _clearCache();
                  await _loadUserData();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                label: widget.themeMode == ThemeMode.dark ? 'Light' : 'Dark',
                onPressed: widget.onThemeToggle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: Icons.logout,
            label: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _closeDropdown();
            },
            isDestructive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDestructive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = 'User';
    
    if (_userData?['name'] != null && _userData!['name'].toString().isNotEmpty) {
      displayName = _userData!['name'];
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: toggleDropdown,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160), // Limit maximum width
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _isOpen
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14, // Slightly smaller avatar
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 13, // Slightly smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                _isOpen ? Icons.expand_less : Icons.expand_more,
                size: 18, // Smaller icon
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
