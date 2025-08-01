import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'ingestion_screen.dart';
import 'graph_visualization_screen.dart';
import 'wallet_screen.dart';
import 'enhanced_economix_chat_screen.dart';
import 'warranty_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final ThemeMode? themeMode;
  final VoidCallback? onThemeToggle;

  const HomeScreen({
    required this.userId,
    this.themeMode,
    this.onThemeToggle,
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final user = AuthService.currentUser;
      if (user != null) {
        String userEmail = user.email ?? 'Unknown';
        print('Loading data for user email: $userEmail');

        // Use the same method as Knowledge Graph screen to get user data
        final userKnowledgeGraphs = await AuthService.getUserKnowledgeGraphs();
        
        print('Retrieved ${userKnowledgeGraphs.length} knowledge graphs for user: $userEmail');

        int actualKgCount = userKnowledgeGraphs.length;
        double totalSpent = 0.0;
        double thisMonthSpent = 0.0;
        List<Map<String, dynamic>> recentActivitiesData = [];

        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);

        for (var kgData in userKnowledgeGraphs) {
          var receiptData = kgData['receipt_data'] ?? {};
          
          print('Processing knowledge graph with receipt data: ${receiptData.keys.toList()}');
          
          // Extract data from the transformed structure
          double? amount = (receiptData['total_amount'] as num?)?.toDouble();
          String? dateField = receiptData['created_at'] as String?;
          String? merchantName = receiptData['merchant_name'] as String?;
          String? category = receiptData['business_category'] as String?;
          
          print('Found data: amount=$amount, date=$dateField, merchant=$merchantName, category=$category');
          
          if (amount != null && amount > 0) {
            totalSpent += amount;

            // Check if this receipt is from this month
            if (dateField != null) {
              try {
                DateTime receiptDate;
                if (dateField.contains('-') && dateField.length >= 7) {
                  // Check if it's just YYYY-MM format or full date
                  if (dateField.length == 7) {
                    // YYYY-MM format
                    receiptDate = DateTime.parse('$dateField-01');
                  } else {
                    // Full date format
                    receiptDate = DateTime.parse(dateField);
                  }
                } else {
                  receiptDate = DateTime.now();
                }

                print('Receipt date: $receiptDate');
                if (receiptDate.isAfter(startOfMonth) || receiptDate.isAtSameMomentAs(startOfMonth)) {
                  thisMonthSpent += amount;
                  print('Added to this month spending: $amount');
                }
              } catch (e) {
                print('Error parsing date: $e');
              }
            }
            
            // Add to recent activities if we have merchant info
            if (merchantName != null && merchantName.isNotEmpty) {
              recentActivitiesData.add({
                'amount': amount,
                'merchant': merchantName,
                'category': category ?? 'Other',
                'date': dateField,
                'dateTime': _parseStringDate(dateField),
              });
            }
          } else {
            print('No valid amount found in knowledge graph');
          }
        }
        
        print('Final calculations: receipts=$actualKgCount, total=\$${totalSpent.toStringAsFixed(2)}, thisMonth=\$${thisMonthSpent.toStringAsFixed(2)}');

        // Create recent activities from the most recent receipts
        List<Map<String, dynamic>> recentActivities = [];
        
        // Sort activities by date (most recent first)
        recentActivitiesData.sort((a, b) {
          DateTime aDate = a['dateTime'] ?? DateTime.now();
          DateTime bDate = b['dateTime'] ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        // Take up to 3 most recent receipts
        for (int i = 0; i < recentActivitiesData.length && i < 3; i++) {
          final activityData = recentActivitiesData[i];
          final dateStr = _formatActivityDate(activityData['dateTime']);
          
          recentActivities.add({
            'title': 'Scanned receipt from ${activityData['merchant']}',
            'subtitle': '\$${activityData['amount'].toStringAsFixed(2)} • $dateStr',
            'icon': _getIconForCategory(activityData['category']),
          });
        }

        setState(() {
          _userData = {
            'receiptsCount': actualKgCount,
            'thisMonthSpent': thisMonthSpent,
            'totalSpent': totalSpent,
            'recentActivities': recentActivities,
          };
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userData = {
          'receiptsCount': 0,
          'thisMonthSpent': 0.0,
          'totalSpent': 0.0,
          'recentActivities': <Map<String, dynamic>>[],
        };
        _isLoadingData = false;
      });
    }
  }

  DateTime _parseStringDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    
    try {
      if (dateStr.contains('-') && dateStr.length >= 7) {
        // Check if it's just YYYY-MM format or full date
        if (dateStr.length == 7) {
          // YYYY-MM format
          return DateTime.parse('$dateStr-01');
        } else {
          // Full date format
          return DateTime.parse(dateStr);
        }
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now();
    }
  }

  String _formatActivityDate(dynamic dateData) {
    try {
      DateTime date;
      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else if (dateData is String) {
        date = DateTime.parse(dateData);
      } else {
        return 'Unknown date';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return Icons.restaurant;
      case 'grocery':
      case 'groceries':
        return Icons.local_grocery_store;
      case 'gas':
      case 'fuel':
        return Icons.local_gas_station;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
      case 'medical':
        return Icons.local_hospital;
      case 'transportation':
        return Icons.directions_car;
      default:
        return Icons.receipt_long;
    }
  }

  String _getUserDisplayName() {
    final user = AuthService.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    } else if (user?.email != null) {
      return user!.email!.split('@').first;
    } else {
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
          // Google-style App Bar
          SliverAppBar.large(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_getGreeting()}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _getUserDisplayName(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: widget.onThemeToggle ?? () {
                  // Fallback theme toggle if none provided
                  print('Theme toggle pressed');
                },
                icon: Icon(
                  widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showProfileModal(context);
                },
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildQuickActionsGrid(context, constraints);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Statistics Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewCards(context),
                ],
              ),
            ),
          ),
          
          // Recent Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(context),
                ],
              ),
            ),
          ),
          
          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 84),
          ),
        ],
      ),
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngestionScreen(userId: widget.userId),
            ),
          );
          // Refresh data if a receipt was added
          if (result == true) {
            await _loadUserData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Receipt'),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletScreen(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedEconomixChatScreen(userId: widget.userId),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GraphVisualizationScreen(userId: widget.userId),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  Widget _buildQuickActionsGrid(BuildContext context, [BoxConstraints? constraints]) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determine grid layout based on screen width
    final screenWidth = constraints?.maxWidth ?? MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2; // 4 columns on desktop, 2 on mobile
    final childAspectRatio = screenWidth > 600 ? 2.0 : 1.5; // Different ratios for different screen sizes
    
    final actions = [
      {
        'title': 'Scan Receipt',
        'subtitle': 'Add new expense',
        'icon': Icons.camera_alt,
        'color': colorScheme.primaryContainer,
        'onColor': colorScheme.onPrimaryContainer,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IngestionScreen(userId: widget.userId),
          ),
        ),
      },
      {
        'title': 'View Wallet',
        'subtitle': 'Check balance',
        'icon': Icons.account_balance_wallet,
        'color': colorScheme.secondaryContainer,
        'onColor': colorScheme.onSecondaryContainer,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletScreen(),
          ),
        ),
      },
      {
        'title': 'AI Assistant',
        'subtitle': 'Get help',
        'icon': Icons.smart_toy,
        'color': colorScheme.tertiaryContainer,
        'onColor': colorScheme.onTertiaryContainer,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedEconomixChatScreen(userId: widget.userId),
          ),
        ),
      },
      {
        'title': 'Analytics',
        'subtitle': 'View insights',
        'icon': Icons.bar_chart,
        'color': colorScheme.errorContainer,
        'onColor': colorScheme.onErrorContainer,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GraphVisualizationScreen(userId: widget.userId),
          ),
        ),
      },
      {
        'title': 'Set Reminder',
        'subtitle': 'Warranty & expiry',
        'icon': Icons.schedule_outlined,
        'color': colorScheme.surfaceVariant,
        'onColor': colorScheme.onSurfaceVariant,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WarrantyReminderScreen(userId: widget.userId),
          ),
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 0,
          color: action['color'] as Color,
          child: InkWell(
            onTap: action['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['onColor'] as Color,
                    size: 24,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: action['onColor'] as Color,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action['subtitle'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (action['onColor'] as Color).withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    if (_isLoadingData) {
      return const Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final receiptsCount = _userData?['receiptsCount'] ?? 0;
    final thisMonthSpent = _userData?['thisMonthSpent'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Receipts',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$receiptsCount',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'This month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Spending',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${thisMonthSpent.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'This month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    if (_isLoadingData) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final recentActivities = _userData?['recentActivities'] as List<Map<String, dynamic>>? ?? [];

    if (recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Start by adding your first receipt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentActivities.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                _getIconForCategory(item['category'] ?? ''),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              item['title'] ?? 'Unknown Receipt',
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item['subtitle'] ?? 'No details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // Handle tap to view receipt details
            },
          ),
        );
      }).toList(),
    );
  }

  void _showProfileModal(BuildContext context) {
    final user = AuthService.currentUser;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? 'No email',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stats
                if (_userData != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Receipts',
                          '${_userData!['receiptsCount'] ?? 0}',
                          Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Spent',
                          '\$${(_userData!['thisMonthSpent'] ?? 0.0).toStringAsFixed(2)}',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Actions
                ListTile(
                  leading: Icon(
                    widget.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: Text(
                    widget.themeMode == ThemeMode.dark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onThemeToggle?.call();
                  },
                ),
                
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
