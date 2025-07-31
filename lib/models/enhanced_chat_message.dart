/// Enhanced Chat Message Model with Question Classification Support
/// 
/// This model supports the new Enhanced Question Classification system
/// from the backend, providing better user experience with intent recognition
/// and conversation context.

class EnhancedChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String messageType;
  final bool success;
  
  // NEW: Enhanced features for question classification
  final String? intentClassified;        // Detected intent from backend
  final double? confidence;              // Classification confidence score
  final List<String> suggestions;        // Follow-up suggestions
  final Map<String, dynamic>? context;   // Conversation context
  final String? timeScope;               // Detected time scope (this month, etc.)
  final String? categoryFilter;          // Detected category (food, transport)
  final String? merchantFilter;          // Detected merchant
  final Map<String, double>? amountFilter; // Detected amount ranges
  final List<String> requiredData;       // What data is needed for this query

  EnhancedChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.success = true,
    
    // Enhanced features
    this.intentClassified,
    this.confidence,
    this.suggestions = const [],
    this.context,
    this.timeScope,
    this.categoryFilter,
    this.merchantFilter,
    this.amountFilter,
    this.requiredData = const [],
  });

  /// Create from backend response
  factory EnhancedChatMessage.fromBackendResponse(
    Map<String, dynamic> response,
    String originalMessage,
  ) {
    return EnhancedChatMessage(
      text: response['response'] ?? 'No response received',
      isUser: false,
      timestamp: DateTime.now(),
      messageType: response['message_type'] ?? 'response',
      success: response['success'] ?? false,
      
      // Enhanced classification data
      intentClassified: response['intent_classified'],
      confidence: response['confidence']?.toDouble(),
      suggestions: List<String>.from(response['suggestions'] ?? []),
      context: response['context'],
      timeScope: response['time_scope'],
      categoryFilter: response['category_filter'],
      merchantFilter: response['merchant_filter'],
      amountFilter: response['amount_filter'] != null 
          ? Map<String, double>.from(response['amount_filter']) 
          : null,
      requiredData: List<String>.from(response['required_data'] ?? []),
    );
  }

  /// Create user message
  factory EnhancedChatMessage.userMessage(String text) {
    return EnhancedChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: 'text',
      success: true,
    );
  }

  /// Create welcome message
  factory EnhancedChatMessage.welcome() {
    return EnhancedChatMessage(
      text: "👋 Hello! I'm Economix, your AI financial assistant.\n\n"
            "🧠 I now have enhanced question understanding!\n"
            "💬 Ask me about your spending patterns\n"
            "📊 Request financial analysis\n"
            "🎯 Get budget advice\n"
            "💡 Receive personalized insights\n\n"
            "I can understand context and provide more targeted help!",
      isUser: false,
      timestamp: DateTime.now(),
      messageType: 'welcome',
      success: true,
      suggestions: [
        "How much did I spend this month?",
        "Analyze my spending patterns",
        "What's my biggest expense category?",
        "Help me create a budget",
      ],
    );
  }

  /// Create error message
  factory EnhancedChatMessage.error(String error) {
    return EnhancedChatMessage(
      text: error,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: 'error',
      success: false,
    );
  }

  /// Check if message has classification data
  bool get hasClassificationData => intentClassified != null && confidence != null;

  /// Get intent display name
  String get intentDisplayName {
    if (intentClassified == null) return '';
    
    switch (intentClassified!) {
      case 'spending_summary':
        return 'Spending Summary';
      case 'spending_analysis':
        return 'Spending Analysis';
      case 'category_analysis':
        return 'Category Analysis';
      case 'budget_inquiry':
        return 'Budget Check';
      case 'budget_advice':
        return 'Budget Advice';
      case 'savings_advice':
        return 'Savings Tips';
      case 'comparative_analysis':
        return 'Comparison';
      case 'trend_analysis':
        return 'Trend Analysis';
      default:
        return intentClassified!.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get confidence level description
  String get confidenceLevel {
    if (confidence == null) return '';
    if (confidence! >= 0.8) return 'High';
    if (confidence! >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get confidence color
  String get confidenceColor {
    if (confidence == null) return '#gray';
    if (confidence! >= 0.8) return '#green';
    if (confidence! >= 0.6) return '#orange';
    return '#red';
  }
}
