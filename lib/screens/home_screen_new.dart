import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'ingestion_screen.dart';
import 'graph_visualization_screen.dart';
import 'wallet_screen.dart';
import 'profile_dropdown.dart';
import 'enhanced_economix_chat_screen.dart';

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
      body: CustomScrollView(
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
                onPressed: widget.onThemeToggle,
                icon: Icon(
                  widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfileDropdown(
                      themeMode: widget.themeMode,
                      onThemeToggle: widget.onThemeToggle,
                    ),
                  );
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
                  _buildQuickActionsGrid(context),
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
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngestionScreen(userId: widget.userId),
            ),
          );
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
                  builder: (context) => WalletScreen(userId: widget.userId),
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
            builder: (context) => WalletScreen(userId: widget.userId),
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
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
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['onColor'] as Color,
                    size: 24,
                  ),
                  const Spacer(),
                  Text(
                    action['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: action['onColor'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action['subtitle'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (action['onColor'] as Color).withOpacity(0.7),
                    ),
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
                      Text(
                        'Receipts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '24',
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
                      Text(
                        'Spending',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$1,234',
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
    final recentItems = [
      {
        'title': 'Grocery Store Receipt',
        'subtitle': '\$45.32 • 2 hours ago',
        'icon': Icons.receipt_long,
      },
      {
        'title': 'Restaurant Bill',
        'subtitle': '\$28.50 • Yesterday',
        'icon': Icons.restaurant,
      },
      {
        'title': 'Gas Station',
        'subtitle': '\$52.00 • 2 days ago',
        'icon': Icons.local_gas_station,
      },
    ];

    return Column(
      children: recentItems.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                item['icon'] as IconData,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              item['subtitle'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // Handle tap
            },
          ),
        );
      }).toList(),
    );
  }
}
