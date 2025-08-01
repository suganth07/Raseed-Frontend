import 'package:flutter/material.dart';
import '../services/enhanced_ecospend_service.dart';
import '../models/enhanced_chat_message.dart';

class EnhancedEconomixChatScreen extends StatefulWidget {
  final String userId;

  const EnhancedEconomixChatScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<EnhancedEconomixChatScreen> createState() => _EnhancedEconomixChatScreenState();
}

class _EnhancedEconomixChatScreenState extends State<EnhancedEconomixChatScreen> {
  final List<EnhancedChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _userDataValidated = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Validate user data first
    await _validateUserData();
    
    // Add welcome message
    _addWelcomeMessage();
    
    // Load suggestions
    await _loadSuggestions();
  }

  Future<void> _validateUserData() async {
    try {
      final validation = await EnhancedEcospendService.validateUserData(
        userId: widget.userId,
      );
      
      setState(() {
        _userDataValidated = validation['has_real_data'] ?? false;
      });

      if (!_userDataValidated) {
        setState(() {
          _messages.add(EnhancedChatMessage(
            text: "⚠️ I notice you don't have any financial data connected yet.\n\n"
                  "To get personalized insights, please:\n"
                  "📄 Upload some receipts\n"
                  "🔗 Connect your financial accounts\n"
                  "💳 Add some transaction data\n\n"
                  "I can still help with general financial advice!",
            isUser: false,
            timestamp: DateTime.now(),
            messageType: 'data_warning',
            suggestions: [
              "How do I upload receipts?",
              "What financial advice can you give?",
              "Help me get started with budgeting",
            ],
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(EnhancedChatMessage.error(
            "Unable to validate your data. You may experience limited functionality.",
          ));
        });
      }
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await EnhancedEcospendService.getConversationSuggestions(
        userId: widget.userId,
      );
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      // Use default suggestions
      setState(() {
        _suggestions = [
          "How much did I spend this month?",
          "Analyze my spending patterns",
          "What's my biggest expense category?",
          "Help me create a budget",
        ];
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(EnhancedChatMessage.welcome());
    });
  }

  Future<void> _sendMessage(String text, {String messageType = 'text'}) async {
    if (text.trim().isEmpty && messageType == 'text') return;

    // Add user message
    setState(() {
      if (messageType == 'text') {
        _messages.add(EnhancedChatMessage.userMessage(text));
      }
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Send to enhanced service
      final response = await EnhancedEcospendService.chatWithEconomixEnhanced(
        userId: widget.userId,
        message: text,
        messageType: messageType,
      );

      setState(() {
        if (response['success'] == true) {
          // Create enhanced message from backend response
          _messages.add(EnhancedChatMessage.fromBackendResponse(response, text));
        } else {
          // Handle different error types
          String errorMessage = response['response'] ?? 'Sorry, I encountered an error.';
          String errorType = response['error_type'] ?? 'unknown_error';
          
          if (errorType == 'auth_error') {
            errorMessage = "🔒 Authentication required. Please log in again.";
          } else if (errorType == 'rate_limit_error') {
            errorMessage = "⏳ Please wait a moment before sending another message.";
          } else if (errorType == 'network_error') {
            errorMessage = "🌐 Network connection issue. Please check your internet.";
          }
          
          _messages.add(EnhancedChatMessage.error(errorMessage));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(EnhancedChatMessage.error(
          'Sorry, I encountered an error. Please try again.',
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(EnhancedChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology_rounded, 
                size: 20, 
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Enhanced message container with classification info
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Theme.of(context).colorScheme.primary
                        : message.success 
                            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
                            : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20.0).copyWith(
                      topLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                      topRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: message.hasClassificationData 
                        ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Classification header (for bot messages with classification)
                      if (!message.isUser && message.hasClassificationData) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology_rounded, 
                                size: 14, 
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${message.intentDisplayName} (${message.confidenceLevel})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Main message text
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser 
                              ? Theme.of(context).colorScheme.onPrimary 
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      
                      // Enhanced context info (time scope, category, etc.)
                      if (!message.isUser && (message.timeScope != null || message.categoryFilter != null)) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (message.timeScope != null)
                              _buildContextChip('📅 ${message.timeScope}', Theme.of(context).colorScheme.secondaryContainer),
                            if (message.categoryFilter != null)
                              _buildContextChip('🏷️ ${message.categoryFilter}', Theme.of(context).colorScheme.tertiaryContainer),
                            if (message.merchantFilter != null)
                              _buildContextChip('🏪 ${message.merchantFilter}', Theme.of(context).colorScheme.primaryContainer),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Suggestions (for bot messages)
                if (!message.isUser && message.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: message.suggestions.take(3).map((suggestion) => 
                      _buildSuggestionChip(suggestion)
                    ).toList(),
                  ),
                ],
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person_rounded, 
                size: 20, 
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextChip(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return InkWell(
      onTap: () => _sendMessage(suggestion),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 8,
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Smart suggestions row
          if (_suggestions.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildSuggestionChip(_suggestions[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _userDataValidated 
                        ? 'Ask about your finances...' 
                        : 'Ask for general financial advice...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, 
                      vertical: 14.0,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _userDataValidated 
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _userDataValidated ? Icons.psychology_rounded : Icons.help_outline_rounded,
                        color: _userDataValidated 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (text) => _sendMessage(text),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12.0),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isLoading ? null : () => _sendMessage(_textController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded, 
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 300;
            
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_rounded, 
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Economix Assistant',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Data status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _userDataValidated 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userDataValidated ? Icons.verified_rounded : Icons.warning_rounded,
                        size: 12,
                        color: _userDataValidated 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 4),
                        Text(
                          _userDataValidated ? 'Real Data' : 'Limited',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _userDataValidated 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Clear conversation
              setState(() {
                _messages.clear();
                EnhancedEcospendService.clearConversationHistory();
              });
              _addWelcomeMessage();
            },
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
