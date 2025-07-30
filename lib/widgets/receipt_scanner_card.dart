import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReceiptScannerCard extends StatefulWidget {
  const ReceiptScannerCard({super.key});

  @override
  State<ReceiptScannerCard> createState() => _ReceiptScannerCardState();
}

class _ReceiptScannerCardState extends State<ReceiptScannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  bool _isScanning = false;

  // Google Colors
  static const Color _googleBlue = Color(0xFF4285F4);
  static const Color _googleRed = Color(0xFFDB4437);
  static const Color _googleYellow = Color(0xFFF4B400);
  static const Color _googleGreen = Color(0xFF0F9D58);
  static const Color _googleSurface = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _googleSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _googleBlue.withOpacity(0.1), // formerly green
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _handleScanReceipt,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_googleBlue, _googleBlue.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _googleBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          if (_isScanning)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                                  .fadeIn(duration: 1000.ms)
                                  .then()
                                  .fadeOut(duration: 1000.ms),
                            ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(delay: 200.ms)
                        .scale(begin: const Offset(0.5, 0.5)),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receipt Scanner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ).animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: -0.3),

                          const SizedBox(height: 4),

                          Text(
                            _isScanning
                                ? 'Processing receipt...'
                                : 'Capture & track expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ).animate()
                              .fadeIn(delay: 600.ms)
                              .slideX(begin: -0.3),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _googleBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: _googleBlue,
                        size: 20,
                      ),
                    ).animate()
                        .fadeIn(delay: 800.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                  ],
                ),

                const SizedBox(height: 24),

                // Scanning area mockup
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _googleBlue.withOpacity(0.2),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              _googleBlue.withOpacity(0.05),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Corner brackets
                      ...List.generate(4, (index) => _buildCornerBracket(index)),

                      // Center content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _googleBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isScanning
                                    ? Icons.hourglass_empty_rounded
                                    : Icons.add_a_photo_rounded,
                                color: _googleBlue,
                                size: 32,
                              ),
                            ).animate(
                              onPlay: (controller) => _isScanning
                                  ? controller.repeat()
                                  : controller.stop(),
                            )
                                .rotate(duration: 2000.ms),

                            const SizedBox(height: 16),

                            Text(
                              _isScanning
                                  ? 'Scanning receipt...'
                                  : 'Tap to scan receipt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _googleBlue,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              _isScanning
                                  ? 'Please wait while we process your receipt'
                                  : 'Automatically extract expense data',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scanning line animation
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _scanAnimationController,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (140 * _scanAnimationController.value),
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _googleBlue,
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ).animate()
                    .fadeIn(delay: 1000.ms)
                    .slideY(begin: 0.3, duration: 600.ms),

                const SizedBox(height: 20),

                // Recent scans
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent: Grocery Store - ₹245',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '2h ago',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 1200.ms)
                    .slideX(begin: -0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBracket(int index) {
    double top = index < 2 ? 16 : double.infinity;
    double bottom = index >= 2 ? 16 : double.infinity;
    double left = index % 2 == 0 ? 16 : double.infinity;
    double right = index % 2 == 1 ? 16 : double.infinity;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2
                ? BorderSide(color: _googleBlue, width: 2)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(color: _googleBlue, width: 2)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(color: _googleBlue, width: 2)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(color: _googleBlue, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 1400 + (index * 100)))
        .scale(begin: const Offset(0.5, 0.5));
  }

  Future<void> _handleScanReceipt() async {
    HapticFeedback.mediumImpact();

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _googleSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan Receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _googleBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: _googleBlue),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture receipt with camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _googleBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: _googleBlue),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _isScanning = true;
      });

      _scanAnimationController.repeat();

      // Simulate scanning process
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isScanning = false;
        });

        _scanAnimationController.stop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: _googleBlue),
                const SizedBox(width: 12),
                const Text('Receipt scanned successfully!'),
              ],
            ),
            backgroundColor: _googleSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
