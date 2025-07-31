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
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Enhanced message container with classification info
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Colors.blue.shade500 
                        : message.success 
                            ? Colors.grey.shade100 
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: message.hasClassificationData 
                        ? Border.all(color: Colors.green.shade300, width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Classification header (for bot messages with classification)
                      if (!message.isUser && message.hasClassificationData) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology, size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '${message.intentDisplayName} (${message.confidenceLevel})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Main message text
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      
                      // Enhanced context info (time scope, category, etc.)
                      if (!message.isUser && (message.timeScope != null || message.categoryFilter != null)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (message.timeScope != null)
                              _buildContextChip('📅 ${message.timeScope}', Colors.blue.shade100),
                            if (message.categoryFilter != null)
                              _buildContextChip('🏷️ ${message.categoryFilter}', Colors.orange.shade100),
                            if (message.merchantFilter != null)
                              _buildContextChip('🏪 ${message.merchantFilter}', Colors.purple.shade100),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Suggestions (for bot messages)
                if (!message.isUser && message.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: message.suggestions.take(3).map((suggestion) => 
                      _buildSuggestionChip(suggestion)
                    ).toList(),
                  ),
                ],
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextChip(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return InkWell(
      onTap: () => _sendMessage(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.grey.shade300,
          ),
        ],
      ),
      child: Column(
        children: [
          // Smart suggestions row
          if (_suggestions.isNotEmpty) ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSuggestionChip(_suggestions[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, 
                      vertical: 10.0,
                    ),
                    prefixIcon: Icon(
                      _userDataValidated ? Icons.psychology : Icons.help_outline,
                      color: _userDataValidated ? Colors.green : Colors.orange,
                    ),
                  ),
                  onSubmitted: (text) => _sendMessage(text),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade500,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
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
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Enhanced Economix'),
            const Spacer(),
            // Data status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _userDataValidated ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _userDataValidated ? Icons.verified : Icons.warning,
                    size: 14,
                    color: _userDataValidated ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userDataValidated ? 'Real Data' : 'Limited',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _userDataValidated ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
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
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
