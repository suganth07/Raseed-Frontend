import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../screens/graph_visualization_screen.dart';
import '../screens/economix_chat_screen.dart';

class QuickActionsRow extends StatefulWidget {
  final String userId;
  
  const QuickActionsRow({
    required this.userId,
    super.key,
  });

  @override
  State<QuickActionsRow> createState() => _QuickActionsRowState();
}

class _QuickActionsRowState extends State<QuickActionsRow> {

  // Google Colors
  static const Color _googleGreen = Color(0xFF0F9D58);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80, // Increased height for each row
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.analytics_rounded,
                    title: 'Insights',
                    subtitle: 'View trends',
                    gradient: [_googleGreen, _googleGreen.withOpacity(0.7)],
                    onTap: () => _handleQuickAction('insights'),
                  ).animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.3, duration: 400.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.account_tree,
                    title: 'Knowledge Graph',
                    subtitle: 'Explore data',
                    gradient: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.7)],
                    onTap: () => _handleKnowledgeGraph(),
                  ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, duration: 400.ms),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80, // Increased height for each row
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.wallet_giftcard,
                    title: 'GWallet Pass',
                    subtitle: 'Digital pass',
                    gradient: [Colors.purpleAccent, Colors.purpleAccent.withOpacity(0.7)],
                    onTap: () => _handleQuickAction('gwallet'),
                  ).animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3, duration: 400.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'EcoNomix Bot',
                    subtitle: 'AI assistant',
                    gradient: [Colors.tealAccent[400]!, Colors.tealAccent[400]!.withOpacity(0.7)],
                    onTap: () => _handleQuickAction('econobot'),
                  ).animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.3, duration: 400.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    // Handle quick action logic here
    print('Quick action: $action');
    
    // Show different messages based on action
    String message = '';
    switch (action) {
      case 'insights':
        message = 'Insights & Trends feature coming soon!';
        break;
      case 'gwallet':
        message = 'Google Wallet Pass integration coming soon!';
        break;
      case 'econobot':
        // Navigate to Economix Chat Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EconomixChatScreen(
              userId: widget.userId, // Use the consistent user ID instead of creating new one
            ),
          ),
        );
        return;
      case 'scan_qr':
        message = 'QR Code Scanner feature coming soon!';
        break;
      default:
        message = 'Feature coming soon!';
    }
    
    _showToast(message);
  }

  void _handleKnowledgeGraph() {
    HapticFeedback.lightImpact();
    _showToast("Opening Knowledge Graph...");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GraphVisualizationScreen(
          userId: 'flutter_user_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

}
