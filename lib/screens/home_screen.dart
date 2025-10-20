import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/sse_service.dart';
import '../models/document.dart';
import 'document_upload_screen.dart';
import 'ai_chat_screen.dart';

// Frontend version tracking
const String FRONTEND_VERSION = '1.1.0-sse-real-time';

class HomeScreen extends StatefulWidget {
  final bool showBottomNavigation;

  const HomeScreen({super.key, this.showBottomNavigation = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Document> _documents = [];
  bool _isLoading = false;
  bool _isDeleting = false;
  final SSEService _sseService = SSEService();
  final ApiService _apiService = ApiService();
  StreamSubscription<DocumentStatusEvent>? _sseSubscription;
  String _backendVersion = 'Loading...';
  bool _versionLoaded = false;

  // Track documents being fetched to prevent duplicates
  final Set<String> _fetchingDocIds = {};

  @override
  void initState() {
    super.initState();

    // SECURITY CHECK: Verify user is authenticated before proceeding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      print('DEBUG: HomeScreen - No authenticated user, redirecting to auth');
      // Navigate back to auth screen
      Navigator.of(context).pushReplacementNamed('/auth');
      return;
    }

    print('DEBUG: HomeScreen - User authenticated: ${currentUser.email}');

    // Proceed with normal initialization
    _loadDocuments();
    _loadBackendVersion();
    _connectSSE();
  }

  void _connectSSE() {
    _sseService.connect(ApiService.baseUrl);

    _sseSubscription = _sseService.statusStream.listen((event) {
      print(
        'DEBUG SSE: Received status update for ${event.docId}: ${event.status} (${event.progress}%)',
      );
      _handleSSEUpdate(event);
    });
  }

  void _handleSSEUpdate(DocumentStatusEvent event) {
    if (!mounted) return;

    // Find the document in our list and update it
    final index = _documents.indexWhere((doc) => doc.id == event.docId);

    if (index != -1) {
      // Update existing document
      setState(() {
        final updatedDoc = Document(
          id: _documents[index].id,
          name: _documents[index].name,
          status: event.status,
          mimeType: _documents[index].mimeType,
          sourceUri: _documents[index].sourceUri,
          bikeModels: _documents[index].bikeModels,
          components: _documents[index].components,
          tags: _documents[index].tags,
          visibility: _documents[index].visibility,
          createdAt: _documents[index].createdAt,
          updatedAt: DateTime.now(),
          error: event.error.isNotEmpty ? event.error : _documents[index].error,
        );
        _documents[index] = updatedDoc;
      });
    } else {
      // Document not in list - fetch it from API and add it
      _fetchAndAddDocument(event.docId);
    }
  }

  Future<void> _fetchAndAddDocument(String docId) async {
    // Prevent duplicate fetches
    if (_fetchingDocIds.contains(docId)) {
      print(
        'DEBUG: Already fetching document $docId, skipping duplicate fetch',
      );
      return;
    }

    // Check if document already exists in list (race condition protection)
    if (_documents.any((doc) => doc.id == docId)) {
      print('DEBUG: Document $docId already in list, skipping fetch');
      return;
    }

    _fetchingDocIds.add(docId);

    try {
      final apiService = context.read<ApiService>();
      final document = await apiService.getDocument(docId);

      if (mounted) {
        setState(() {
          // Double-check it wasn't added while we were fetching
          if (!_documents.any((doc) => doc.id == docId)) {
            // Add new document at the beginning of the list
            _documents.insert(0, document);
            print('DEBUG: Added new document $docId to list');
          } else {
            print('DEBUG: Document $docId was added while fetching, skipping');
          }
        });
      }
    } catch (e) {
      print('Error fetching document $docId: $e');
    } finally {
      _fetchingDocIds.remove(docId);
    }
  }

  Future<void> _loadBackendVersion() async {
    if (_versionLoaded) return;

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.getBackendVersion();
      if (mounted) {
        setState(() {
          _backendVersion = response['backend_version'] ?? 'Unknown';
          _versionLoaded = true;
        });
      }
    } catch (e) {
      print('DEBUG: Failed to load backend version: $e');
      if (mounted) {
        setState(() {
          _backendVersion = 'Unknown';
          _versionLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _sseService.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;

    // Prevent multiple simultaneous loads
    if (_isLoading) {
      print('DEBUG: _loadDocuments already in progress, skipping');
      return;
    }

    print('DEBUG: Starting _loadDocuments');
    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();

      // Get auth token
      final token = await authService.getIdToken();

      if (token == null || token.isEmpty) {
        print('DEBUG: No auth token available, cannot load documents');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to view documents'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        if (mounted) setState(() => _documents = []);
        return;
      }

      print('DEBUG: Setting auth token for API requests');
      _apiService.setAuthToken(token);

      print('DEBUG: Fetching documents from API');
      final documents = await _apiService.getDocuments();

      print('DEBUG: Documents loaded successfully: ${documents.length}');
      if (mounted) {
        setState(() {
          // Merge new documents with existing ones to preserve SSE status updates
          // Create maps for quick lookup
          final Map<String, Document> existingDocs = {
            for (var doc in _documents) doc.id: doc,
          };
          final Map<String, Document> apiDocs = {
            for (var doc in documents) doc.id: doc,
          };

          print(
            'DEBUG: Before merge - existing docs: ${existingDocs.length}, new docs from API: ${documents.length}',
          );

          // Merge strategy:
          // 1. Keep existing documents that have SSE updates (prefer local state over API)
          // 2. Add new documents from API that we don't have yet
          // 3. KEEP documents in existing list that aren't in API yet (just uploaded via SSE)
          final List<Document> merged = [];

          // First, add all existing documents (preserves SSE updates AND just-uploaded docs)
          for (var existingDoc in _documents) {
            if (apiDocs.containsKey(existingDoc.id)) {
              // Document exists in API - keep our version (has SSE updates)
              print(
                'DEBUG: Keeping existing doc ${existingDoc.id} with status ${existingDoc.status}',
              );
              merged.add(existingDoc);
            } else {
              // Document NOT in API yet (just uploaded, API hasn't returned it yet)
              print(
                'DEBUG: Keeping just-uploaded doc ${existingDoc.id} with status ${existingDoc.status} (not in API yet)',
              );
              merged.add(existingDoc);
            }
          }

          // Then, add new documents from API that we don't have locally
          for (var newDoc in documents) {
            if (!existingDocs.containsKey(newDoc.id)) {
              print(
                'DEBUG: Adding new doc from API ${newDoc.id} with status ${newDoc.status}',
              );
              merged.add(newDoc);
            }
          }

          print('DEBUG: After merge - total docs: ${merged.length}');
          _documents = merged;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading documents: $e');
      if (mounted) {
        String errorMessage = 'Failed to load documents';
        if (e.toString().contains('401')) {
          errorMessage =
              'Authentication failed. Please sign out and sign in again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDocuments,
            ),
          ),
        );
      }
    } finally {
      print('DEBUG: _loadDocuments completed, setting _isLoading = false');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    print('═' * 80);
    print('🚪 SIGN OUT INITIATED');
    print('═' * 80);

    // Show a visual indicator that sign out was triggered
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚪 Signing out...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }

    try {
      final authService = context.read<AuthService>();
      print('✅ Got AuthService');

      // Disconnect SSE before signing out
      print('📡 Cancelling SSE subscription...');
      _sseSubscription?.cancel();
      print('📡 Disposing SSE service...');
      _sseService.dispose();
      print('✅ SSE cleaned up');

      print('🔓 Calling authService.signOut()...');
      await authService.signOut();
      print('✅ authService.signOut() completed');

      // Force navigation to auth screen
      print('🚀 Forcing navigation to /auth...');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
        print('✅ Navigated to /auth');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signed out successfully'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('═' * 80);
      print('❌ SIGN OUT ERROR: $e');
      print('═' * 80);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoDocs AI'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              print('🔘 PopupMenu item selected: $value');
              if (value == 'signout') {
                print('🔘 Sign out menu item matched, calling _signOut()');
                _signOut();
              } else {
                print('⚠️  Unknown menu value: $value');
              }
            },
            itemBuilder: (context) {
              print('📋 Building popup menu items');
              return [
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [_buildDocumentsTab(), const AIChatScreen()],
            ),
          ),
          // Version info bar at bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Frontend: $FRONTEND_VERSION',
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Container(height: 12, width: 1, color: Colors.grey[400]),
                const SizedBox(width: 16),
                Text(
                  'Backend: $_backendVersion',
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: 'Documents',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'AI Chat',
                ),
              ],
            )
          : null,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final uploadedDocument = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentUploadScreen(),
                  ),
                );

                // If a document was uploaded, immediately add it to the list
                // SSE will automatically update statuses in real-time
                print('DEBUG HOME: Upload result: $uploadedDocument');
                print(
                  'DEBUG HOME: Upload result type: ${uploadedDocument.runtimeType}',
                );

                if (uploadedDocument != null && uploadedDocument is Document) {
                  print(
                    'DEBUG HOME: Adding document to list: ${uploadedDocument.id}',
                  );
                  setState(() {
                    // Add new document at the beginning of the list
                    _documents.insert(0, uploadedDocument);
                  });
                  print(
                    'DEBUG HOME: Document added, total documents: ${_documents.length}',
                  );

                  // DON'T reload immediately - SSE will handle status updates
                  // The document is already in the list and SSE is connected
                  print(
                    'DEBUG HOME: Document added to UI, SSE will handle updates',
                  );
                } else {
                  print('DEBUG HOME: No document returned from upload');
                }
              },
              child: const Icon(Icons.upload),
            )
          : null,
    );
  }

  Widget _buildDocumentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Upload your first motorcycle manual to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        // Show progress bar for any processing status (PROCESSING, PARSING, CHUNKING, EMBEDDING)
        final isProcessing = [
          'PROCESSING',
          'PARSING',
          'CHUNKING',
          'EMBEDDING',
          'UPLOADED',
        ].contains(document.status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: Text(document.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${document.status}'),
                    if (document.bikeModels.isNotEmpty)
                      Text('Bikes: ${document.bikeModels.join(', ')}'),
                    if (document.components.isNotEmpty)
                      Text('Components: ${document.components.join(', ')}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(document.status),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(document),
                      tooltip: 'Delete document',
                    ),
                  ],
                ),
                onTap: () {
                  // Show document details
                  _showDocumentDetails(document);
                },
              ),
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildProcessingSteps(document.status),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'uploaded':
        color = Colors.orange;
        break;
      case 'processing':
      case 'parsing':
      case 'chunking':
      case 'embedding':
        color = Colors.blue;
        break;
      case 'indexed':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildProcessingSteps(String currentStatus) {
    final steps = [
      {'name': 'UPLOADED', 'icon': Icons.upload_file},
      {'name': 'PROCESSING', 'icon': Icons.settings},
      {'name': 'PARSING', 'icon': Icons.description},
      {'name': 'CHUNKING', 'icon': Icons.splitscreen},
      {'name': 'EMBEDDING', 'icon': Icons.generating_tokens},
      {'name': 'INDEXED', 'icon': Icons.check_circle},
    ];

    int currentStepIndex = steps.indexWhere(
      (step) => step['name'] == currentStatus.toUpperCase(),
    );
    if (currentStepIndex == -1) currentStepIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Processing Pipeline',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index < currentStepIndex;
            final isCurrent = index == currentStepIndex;
            final isPending = index > currentStepIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                      Icon(
                        step['icon'] as IconData,
                        size: 24,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                            ? Colors.blue
                            : Colors.grey[400],
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['name'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                          ? Colors.blue
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
        if (currentStepIndex < steps.length - 1) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ],
    );
  }

  Future<void> _deleteDocument(Document document) async {
    // Prevent multiple delete operations
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final apiService = context.read<ApiService>();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Deleting document...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _apiService.deleteDocument(document.id);

      if (mounted) {
        // Clear loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();

        // Immediately remove document from UI
        setState(() {
          _documents.removeWhere((doc) => doc.id == document.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );

        // No need to reload - document is already removed from UI
      }
    } catch (e) {
      if (mounted) {
        // Clear loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();

        // Handle 404 as success since document was already deleted
        if (e.toString().contains('404')) {
          // Immediately remove document from UI
          setState(() {
            _documents.removeWhere((doc) => doc.id == document.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted successfully')),
          );
          // No need to reload - document is already removed from UI
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete document: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDocumentDetails(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(document.name)),
            _buildStatusChip(document.status),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Document Information', [
                  _buildDetailRow('Document ID', document.id),
                  _buildDetailRow('Name', document.name),
                  _buildDetailRow('Status', document.status),
                  _buildDetailRow(
                    'Visibility',
                    document.visibility.toUpperCase(),
                  ),
                  _buildDetailRow('MIME Type', document.mimeType),
                ]),
                const Divider(height: 24),
                _buildDetailSection('Metadata', [
                  _buildDetailRow(
                    'Bike Models',
                    document.bikeModels.join(', '),
                  ),
                  _buildDetailRow('Components', document.components.join(', ')),
                  _buildDetailRow('Tags', document.tags.join(', ')),
                ]),
                const Divider(height: 24),
                _buildDetailSection('Storage', [
                  _buildDetailRow('Source URI', document.sourceUri),
                ]),
                const Divider(height: 24),
                _buildDetailSection('Timestamps', [
                  _buildDetailRow(
                    'Created',
                    _formatDateTime(document.createdAt),
                  ),
                  _buildDetailRow(
                    'Updated',
                    _formatDateTime(document.updatedAt),
                  ),
                ]),
                if (document.error != null) ...[
                  const Divider(height: 24),
                  _buildDetailSection('Error Details', [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.pop(context);
                    _deleteDocument(document);
                  },
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete, color: Colors.red),
            label: Text(
              _isDeleting ? 'Deleting...' : 'Delete',
              style: TextStyle(color: _isDeleting ? Colors.grey : Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(Document document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Text(
            'Are you sure you want to delete "${document.name}"?\n\n'
            'This will permanently remove the document and all its data from the system.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDocument(document);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
