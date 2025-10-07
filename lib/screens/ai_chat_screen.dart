import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedBikeModel = ''; // Now required, starts empty
  String _currentLoadingPhrase = '';
  Timer? _phraseTimer;
  List<String> _availableBikeModels = [];
  bool _loadingBikeModels = true;

  final List<String> _loadingPhrases = [
    '🔍 Searching through service manuals...',
    '🧠 Consulting the AI motorcycle expert...',
    '📚 Analyzing repair procedures...',
    '⚙️ Cross-referencing technical specifications...',
    '🔧 Looking up diagnostic steps...',
    '💡 Generating personalized recommendations...',
    '🏍️ Reviewing motorcycle maintenance guides...',
    '📖 Reading through technical documentation...',
    '🎯 Finding the most relevant solutions...',
    '✨ Almost there, finalizing response...',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _loadBikeModels();
  }

  Future<void> _loadBikeModels() async {
    try {
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();

      // Get auth token
      final token = await authService.getIdToken();
      if (token != null) {
        apiService.setAuthToken(token);
        final models = await apiService.getBikeModels();
        setState(() {
          _availableBikeModels = models;
          _loadingBikeModels = false;
          // Set first model as default if available
          if (models.isNotEmpty) {
            _selectedBikeModel = models.first;
          }
        });
      }
    } catch (e) {
      setState(() => _loadingBikeModels = false);
      print('Error loading bike models: $e');
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  void _startLoadingPhrases() {
    int index = 0;
    setState(() => _currentLoadingPhrase = _loadingPhrases[0]);

    _phraseTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          index = (index + 1) % _loadingPhrases.length;
          _currentLoadingPhrase = _loadingPhrases[index];
        });
      }
    });
  }

  void _stopLoadingPhrases() {
    _phraseTimer?.cancel();
    setState(() => _currentLoadingPhrase = '');
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your MotoDocs AI assistant. 🏍️\n\nFirst, select your motorcycle model from the dropdown above. Then ask me anything about maintenance, repairs, or troubleshooting - I'll search through the relevant service manuals to help you!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Validate bike model is selected
    if (_selectedBikeModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a motorcycle model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();
    _startLoadingPhrases();

    try {
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();

      // Get auth token
      final token = await authService.getIdToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      apiService.setAuthToken(token);

      // Send query to AI (bike model is now required)
      final result = await apiService.getSuggestion(
        query: text,
        bikeModel: _selectedBikeModel, // Always has a value now
      );

      // Format structured RAG response
      String formattedResponse = _formatRagResponse(result);

      // Add AI response
      setState(() {
        _messages.add(
          ChatMessage(
            text: formattedResponse,
            isUser: false,
            timestamp: DateTime.now(),
            confidence: result['confidence']?.toDouble(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Sorry, I encountered an error: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      _stopLoadingPhrases();
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  String _formatRagResponse(Map<String, dynamic> result) {
    StringBuffer buffer = StringBuffer();

    // Diagnosis
    if (result.containsKey('diagnosis')) {
      buffer.writeln('📋 DIAGNOSIS:');
      buffer.writeln(result['diagnosis']);
      buffer.writeln();
    }

    // Steps
    if (result.containsKey('steps') && result['steps'] is List) {
      List<dynamic> steps = result['steps'];
      if (steps.isNotEmpty) {
        buffer.writeln('🔧 REPAIR STEPS:');
        for (int i = 0; i < steps.length; i++) {
          buffer.writeln('${i + 1}. ${steps[i]}');
        }
        buffer.writeln();
      }
    }

    // Risks
    if (result.containsKey('risks') && result['risks'] is List) {
      List<dynamic> risks = result['risks'];
      if (risks.isNotEmpty) {
        buffer.writeln('⚠️ SAFETY WARNINGS:');
        for (var risk in risks) {
          buffer.writeln('• $risk');
        }
        buffer.writeln();
      }
    }

    // Parts
    if (result.containsKey('parts') && result['parts'] is List) {
      List<dynamic> parts = result['parts'];
      if (parts.isNotEmpty) {
        buffer.writeln('🔩 REQUIRED PARTS:');
        for (var part in parts) {
          buffer.writeln('• $part');
        }
        buffer.writeln();
      }
    }

    // References
    if (result.containsKey('references') && result['references'] is List) {
      List<dynamic> refs = result['references'];
      if (refs.isNotEmpty) {
        buffer.writeln('📚 REFERENCES:');
        for (var ref in refs) {
          buffer.writeln(
              '• Doc ID: ${ref['doc_id']} (confidence: ${(ref['confidence'] * 100).toStringAsFixed(1)}%)');
        }
      }
    }

    String formatted = buffer.toString().trim();
    return formatted.isNotEmpty
        ? formatted
        : 'Sorry, I couldn\'t process your request.';
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
    return Column(
      children: [
        // Bike Model Filter (Required Dropdown)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              const Icon(Icons.motorcycle, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Motorcycle Model:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Text(
                '(Required)',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _loadingBikeModels
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading models...'),
                        ],
                      )
                    : _availableBikeModels.isEmpty
                        ? const Text(
                            'No bike models available',
                            style: TextStyle(color: Colors.red),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedBikeModel.isEmpty
                                ? null
                                : _selectedBikeModel,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('Select a motorcycle model'),
                            isExpanded: true,
                            items: _availableBikeModels
                                .map((model) => DropdownMenuItem(
                                      value: model,
                                      child: Text(
                                        model,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBikeModel = value ?? '';
                              });
                            },
                          ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end
              if (_isLoading && index == _messages.length) {
                return _buildLoadingIndicator();
              }

              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) {
                    // Send message on Enter key press (without Shift)
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your motorcycle... (Press Enter to send, Shift+Enter for new line)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (message.confidence != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Show "Verified by Service Manual" badge if confidence > 50%
                        if (message.confidence! > 0.5) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green[700]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified by Service Manual',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Confidence indicator
                        Icon(
                          Icons.psychology,
                          size: 12,
                          color: message.isUser
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Confidence: ${(message.confidence! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: message.isUser
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Lottie.asset(
                          'assets/animations/thinking.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLoadingPhrase,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? confidence;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.confidence,
  });
}
