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
  String _selectedBikeYear = ''; // Now required, starts empty
  String _currentLoadingPhrase = '';
  Timer? _phraseTimer;
  List<String> _availableBikeModels = [];
  List<String> _availableBikeYears = [];
  Map<String, List<String>> _modelYearsMap = {};
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
        final separatedData = await apiService.getSeparatedBikeModels();
        setState(() {
          _availableBikeModels = List<String>.from(
            separatedData['models'] ?? [],
          );
          _availableBikeYears = List<String>.from(separatedData['years'] ?? []);
          _modelYearsMap = Map<String, List<String>>.from(
            separatedData['model_years'] ?? {},
          );
          _loadingBikeModels = false;

          // Set first model and its first available year as default if available
          if (_availableBikeModels.isNotEmpty) {
            _selectedBikeModel = _availableBikeModels.first;
            // Get years for the selected model
            final modelYears = _modelYearsMap[_selectedBikeModel] ?? [];
            if (modelYears.isNotEmpty) {
              _selectedBikeYear = modelYears.first;
            }
          }
        });

        print(
          'Loaded ${_availableBikeModels.length} bike models, ${_availableBikeYears.length} total years, and ${_modelYearsMap.length} model-year relationships',
        );
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
            "Hello! I'm your MotoDocs AI assistant. 🏍️\n\nFirst, select your motorcycle model and year from the dropdowns above. Then ask me anything about maintenance, repairs, or troubleshooting - I'll search through the relevant service manuals to help you!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Validate bike model and year are selected
    if (_selectedBikeModel.isEmpty || _selectedBikeYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both motorcycle model and year first'),
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

      // Send query to AI (bike model and year are now required)
      final combinedBikeModel = '$_selectedBikeModel $_selectedBikeYear';
      final result = await apiService.getSuggestion(
        query: text,
        bikeModel: combinedBikeModel,
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
            bikeModel:
                combinedBikeModel, // Include the combined bike model and year
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

    // Motorcycle Model (always shown at top)
    if (_selectedBikeModel.isNotEmpty) {
      final motorcycleDisplay = _selectedBikeYear.isNotEmpty
          ? '$_selectedBikeModel $_selectedBikeYear'
          : _selectedBikeModel;
      buffer.writeln('🏍️ MOTORCYCLE: $motorcycleDisplay');
      buffer.writeln();
    }

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
          final docName =
              ref['doc_name'] ?? ref['doc_id'] ?? 'Unknown Document';
          final confidence = (ref['confidence'] * 100).toStringAsFixed(1);
          buffer.writeln('• $docName (confidence: ${confidence}%)');
        }
      }
    }

    String formatted = buffer.toString().trim();
    return formatted.isNotEmpty
        ? formatted
        : 'Sorry, I couldn\'t process your request.';
  }

  List<String> _getAvailableYearsForModel(String model) {
    return _modelYearsMap[model] ?? [];
  }

  void _onModelChanged(String? newModel) {
    if (newModel != null) {
      setState(() {
        _selectedBikeModel = newModel;
        // Reset year selection and get available years for the new model
        final availableYears = _getAvailableYearsForModel(newModel);
        if (availableYears.isNotEmpty) {
          _selectedBikeYear = availableYears.first;
        } else {
          _selectedBikeYear = '';
        }
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
    return Column(
      children: [
        // Bike Model and Year Filters (Required Dropdowns)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.motorcycle, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Motorcycle Selection:',
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Model Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Model:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        _loadingBikeModels
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading...'),
                                ],
                              )
                            : _availableBikeModels.isEmpty
                            ? const Text(
                                'No models available',
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
                                hint: const Text('Select model'),
                                isExpanded: true,
                                items: _availableBikeModels
                                    .map(
                                      (model) => DropdownMenuItem(
                                        value: model,
                                        child: Text(
                                          model,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onModelChanged,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Year Dropdown
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Year:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        _loadingBikeModels
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading...'),
                                ],
                              )
                            : _getAvailableYearsForModel(
                                _selectedBikeModel,
                              ).isEmpty
                            ? Text(
                                _selectedBikeModel.isEmpty
                                    ? 'Select a model first'
                                    : 'No years available for $_selectedBikeModel',
                                style: const TextStyle(color: Colors.orange),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedBikeYear.isEmpty
                                    ? null
                                    : _selectedBikeYear,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                hint: const Text('Select year'),
                                isExpanded: true,
                                items:
                                    _getAvailableYearsForModel(
                                          _selectedBikeModel,
                                        )
                                        .map(
                                          (year) => DropdownMenuItem(
                                            value: year,
                                            child: Text(
                                              year,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBikeYear = value ?? '';
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                ],
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
                      hintText:
                          'Ask about your motorcycle... (Press Enter to send, Shift+Enter for new line)',
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
  final String? bikeModel;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.confidence,
    this.bikeModel,
  });
}
