import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GeminiInputBox extends StatefulWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isRecording;
  final Function(String) onSendMessage;
  final VoidCallback onAttachFile;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const GeminiInputBox({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isRecording,
    required this.onSendMessage,
    required this.onAttachFile,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<GeminiInputBox> createState() => _GeminiInputBoxState();
}

class _GeminiInputBoxState extends State<GeminiInputBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showSendButton = false;

  // Google Colors
  static const Color _googleBlue = Color(0xFF4285F4);
  static const Color _googleRed = Color(0xFFDB4437);
  static const Color _googleYellow = Color(0xFFF4B400);
  static const Color _googleGreen = Color(0xFF0F9D58);
  static const Color _googleSurface = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    widget.textController.addListener(() {
      final hasText = widget.textController.text.trim().isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() {
          _showSendButton = hasText;
        });
        if (hasText) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _googleSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File attach and audio buttons row
            if (widget.focusNode.hasFocus || widget.isRecording)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // File attachment button
                    _buildActionButton(
                      icon: Icons.attach_file_rounded,
                      color: _googleBlue,
                      onTap: widget.onAttachFile,
                      tooltip: 'Attach file',
                    ).animate()
                      .slideX(begin: -0.5, duration: 300.ms)
                      .fadeIn(duration: 300.ms),

                    const SizedBox(width: 12),

                    // Audio recording button
                    _buildActionButton(
                      icon: widget.isRecording 
                          ? Icons.stop_rounded 
                          : Icons.mic_rounded,
                      color: widget.isRecording ? _googleRed : _googleGreen,
                      onTap: widget.isRecording 
                          ? widget.onStopRecording 
                          : widget.onStartRecording,
                      tooltip: widget.isRecording 
                          ? 'Stop recording' 
                          : 'Voice message',
                      isRecording: widget.isRecording,
                    ).animate()
                      .slideX(begin: -0.3, duration: 300.ms)
                      .fadeIn(duration: 300.ms, delay: 100.ms),

                    const Spacer(),

                    // Recording indicator
                    if (widget.isRecording)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _googleRed,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 1000.ms)
                            .then()
                            .fadeOut(duration: 1000.ms),
                          const SizedBox(width: 8),
                          Text(
                            'Recording...',
                            style: TextStyle(
                              color: _googleRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.3),
                  ],
                ),
              ),

            // Main input area
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: widget.focusNode.hasFocus 
                      ? _googleBlue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: widget.textController,
                      focusNode: widget.focusNode,
                      maxLines: 5,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isRecording 
                            ? 'Recording your voice message...' 
                            : 'Ask RASEED anything...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: widget.onSendMessage,
                    ),
                  ),

                  // Send button or Gemini logo
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showSendButton
                        ? _buildSendButton()
                        : _buildGeminiLogo(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool isRecording = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              if (isRecording)
                Positioned.fill(
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ).animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 2000.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      key: const ValueKey('send'),
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSendMessage(widget.textController.text);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _animationController.value),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_googleBlue, _googleBlue.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _googleBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeminiLogo() {
    return Container(
      key: const ValueKey('gemini'),
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _googleBlue,
            _googleRed,
            _googleYellow,
            _googleGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.black87,
            size: 16,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.5))
      .then(delay: 1000.ms);
  }
}
