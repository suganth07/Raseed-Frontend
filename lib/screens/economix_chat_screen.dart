import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ecospend_service.dart';

class EconomixChatScreen extends StatefulWidget {
  final String userId;

  const EconomixChatScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<EconomixChatScreen> createState() => _EconomixChatScreenState();
}

class _EconomixChatScreenState extends State<EconomixChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "👋 Hello! I'm Economix, your AI financial assistant. I can help you with:\n\n"
            "💬 Answer financial questions\n"
            "📊 Analyze your spending patterns\n"
            "🧾 Process receipts and documents\n"
            "🍽️ Create recipe shopping lists\n"
            "💡 Provide smart financial insights\n\n"
            "What would you like to know about your finances today?",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: 'welcome',
      ));
    });
  }

  Future<void> _sendMessage(String text, {String messageType = 'text'}) async {
    if (text.trim().isEmpty && messageType == 'text') return;

    setState(() {
      if (messageType == 'text') {
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
          messageType: messageType,
        ));
      }
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      Map<String, dynamic> response;
      
      if (messageType == 'text') {
        response = await EcospendService.chatWithEconomix(
          userId: widget.userId,
          message: text,
          messageType: messageType,
        );
      } else {
        // Handle other message types in the future
        response = {'success': false, 'response': 'Unsupported message type'};
      }

      setState(() {
        _messages.add(ChatMessage(
          text: response['response'] ?? 'Sorry, I encountered an error.',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'response',
          success: response['success'] ?? false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'error',
          success: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        setState(() {
          _messages.add(ChatMessage(
            text: "[Image uploaded] 📷",
            isUser: true,
            timestamp: DateTime.now(),
            messageType: 'image',
          ));
          _isLoading = true;
        });

        _scrollToBottom();

        final response = await EcospendService.chatWithImage(
          userId: widget.userId,
          imageBytes: bytes,
          query: "Please analyze this image",
        );

        setState(() {
          _messages.add(ChatMessage(
            text: response['response'] ?? 'Sorry, I could not process the image.',
            isUser: false,
            timestamp: DateTime.now(),
            messageType: 'response',
            success: response['success'] ?? false,
          ));
          _isLoading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error uploading image. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'error',
          success: false,
        ));
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'csv', 'xlsx'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final bytes = file.bytes!;
        
        setState(() {
          _messages.add(ChatMessage(
            text: "[File uploaded] 📄 ${file.name}",
            isUser: true,
            timestamp: DateTime.now(),
            messageType: 'file',
          ));
          _isLoading = true;
        });

        _scrollToBottom();

        final response = await EcospendService.chatWithFile(
          userId: widget.userId,
          fileBytes: bytes,
          filename: file.name,
          query: "Please analyze this file",
        );

        setState(() {
          _messages.add(ChatMessage(
            text: response['response'] ?? 'Sorry, I could not process the file.',
            isUser: false,
            timestamp: DateTime.now(),
            messageType: 'response',
            success: response['success'] ?? false,
          ));
          _isLoading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error uploading file. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'error',
          success: false,
        ));
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('Economix Bot', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              radius: 16,
              child: const Text('AI', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[700] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isUser ? null : Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[400],
              radius: 16,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[700],
            radius: 16,
            child: const Text('AI', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Thinking...', style: TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: _isLoading ? null : _sendImage,
              tooltip: 'Send Image',
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _isLoading ? null : _sendFile,
              tooltip: 'Send File',
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask me anything about your finances...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _isLoading ? null : _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
              tooltip: 'Send Message',
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Economix Bot'),
          content: const SingleChildScrollView(
            child: Text(
              'Economix is your AI-powered financial assistant that can:\n\n'
              '• Analyze your spending patterns\n'
              '• Process receipts and financial documents\n'
              '• Create smart shopping lists for recipes\n'
              '• Provide personalized financial insights\n'
              '• Answer questions about your finances\n'
              '• Generate Google Wallet passes\n\n'
              'Simply type your question or upload an image/file to get started!',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String messageType;
  final bool success;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.success = true,
  });
}
