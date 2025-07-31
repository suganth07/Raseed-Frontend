import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'ingestion_screen.dart';
import 'graph_visualization_screen.dart';
import 'wallet_screen.dart';
import 'profile_dropdown.dart';
import 'warranty_reminder_screen.dart';
import 'economix_chat_screen.dart';
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
  bool animationEnded = false;

  Color _getPrimaryColor(bool isDark) {
    return isDark ? const Color(0xFF4285F4) : const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/raseed_logo.jpg',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Raseed',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ProfileDropdown(
              onThemeToggle: widget.onThemeToggle ?? () {},
              themeMode: widget.themeMode ?? ThemeMode.system,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use LayoutBuilder to make text responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth - 32; // Account for padding
                      return Container(
                        width: availableWidth,
                        child: Text(
                          'Welcome ${AuthService.currentUser?.displayName ?? 'User'}!',
                          style: TextStyle(
                            fontSize: availableWidth > 400 ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Spend smarter, live greener, let your wallet reflect your values.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // Use responsive layout based on screen width
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        double childAspectRatio = 2.2;
                        
                        if (constraints.maxWidth > 600) {
                          crossAxisCount = 3;
                          childAspectRatio = 2.5;
                        }
                        if (constraints.maxWidth > 900) {
                          crossAxisCount = 4;
                          childAspectRatio = 2.8;
                        }
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _buildQuickActionCard(
                              context: context,
                              title: "Scan Receipt",
                              subtitle: "Add new receipt",
                              icon: Icons.document_scanner,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IngestionScreen(userId: widget.userId),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              context: context,
                              title: "GWallet Pass",
                              subtitle: "Digital wallet",
                              icon: Icons.wallet,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WalletScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              context: context,
                              title: "Analytics",
                              subtitle: "Knowledge Graph",
                              icon: Icons.analytics,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GraphVisualizationScreen(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              context: context,
                              title: "Economix Bot",
                              subtitle: "AI Financial Assistant",
                              icon: Icons.smart_toy,
                              isDark: isDark,
                              onTap: () {
                                // Show options dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Choose Economix Mode'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Select your preferred chat experience:'),
                                          SizedBox(height: 16),
                                          ListTile(
                                            leading: Icon(Icons.auto_awesome),
                                            title: Text('Enhanced'),
                                            subtitle: Text('Smart suggestions & context'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EnhancedEconomixChatScreen(
                                                    userId: widget.userId,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.chat),
                                            title: Text('Standard'),
                                            subtitle: Text('Simple chat interface'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EconomixChatScreen(
                                                    userId: widget.userId,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Warranty reminder button
                    _buildQuickActionCard(
                      context: context,
                      title: "Warranty Reminders",
                      subtitle: "Set reminders for warranty expiry",
                      icon: Icons.schedule_outlined,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WarrantyReminderScreen(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFooterItem(
                  icon: Icons.home,
                  label: "Home",
                  isActive: true,
                  isDark: isDark,
                  onTap: () {},
                ),
                _buildFooterItem(
                  icon: Icons.analytics,
                  label: "Analytics",
                  isActive: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GraphVisualizationScreen(
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
                _buildFooterItem(
                  icon: Icons.qr_code_scanner,
                  label: "Scanner",
                  isActive: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IngestionScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildFooterItem(
                  icon: Icons.smart_toy,
                  label: "Economix",
                  isActive: false,
                  isDark: isDark,
                  onTap: () {
                    // Show options dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Choose Economix Mode'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Select your preferred chat experience:'),
                              SizedBox(height: 16),
                              ListTile(
                                leading: Icon(Icons.auto_awesome),
                                title: Text('Enhanced'),
                                subtitle: Text('Smart suggestions & context'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EnhancedEconomixChatScreen(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.chat),
                                title: Text('Standard'),
                                subtitle: Text('Simple chat interface'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EconomixChatScreen(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryColor = _getPrimaryColor(isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 56, // Fixed height for consistency
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey[800]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.grey[700]!
                : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = _getPrimaryColor(isDark);
    final inactiveColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
