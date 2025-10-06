import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/document.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bikeModelsController = TextEditingController();
  final _componentsController = TextEditingController();
  final _tagsController = TextEditingController();

  html.File? _selectedFile;
  String? _selectedVisibility;
  bool _isUploading = false;

  final List<String> _visibilityOptions = ['public', 'internal'];

  @override
  void dispose() {
    _nameController.dispose();
    _bikeModelsController.dispose();
    _componentsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // Create file input element for Flutter web
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
        ..accept = '.pdf'
        ..multiple = false;

      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          if (file.name.toLowerCase().endsWith('.pdf')) {
            setState(() {
              _selectedFile = file;
              // Auto-fill document name from PDF filename (without .pdf extension)
              if (_nameController.text.isEmpty) {
                final fileNameWithoutExtension = file.name.substring(
                  0,
                  file.name.length - 4,
                );
                _nameController.text = fileNameWithoutExtension;
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a PDF file')),
            );
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadDocument() async {
    print('DEBUG UPLOAD: _uploadDocument() called');

    if (!_formKey.currentState!.validate()) {
      print('DEBUG UPLOAD: Form validation failed');
      return;
    }

    if (_selectedFile == null) {
      print('DEBUG UPLOAD: No file selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
      );
      return;
    }

    print(
      'DEBUG UPLOAD: Form validated, file selected: ${_selectedFile!.name}',
    );
    setState(() => _isUploading = true);

    final apiService = context.read<ApiService>();
    final authService = context.read<AuthService>();

    // Get auth token
    print('DEBUG UPLOAD: Getting auth token...');
    final token = await authService.getIdToken();
    if (token == null) {
      print('DEBUG UPLOAD: No auth token available');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      }
      return;
    }

    print('DEBUG UPLOAD: Auth token obtained, length: ${token.length}');
    apiService.setAuthToken(token);

    // Parse bike models, components, and tags
    final bikeModels = _bikeModelsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final components = _componentsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    print(
      'DEBUG UPLOAD: Parsed - bikeModels: $bikeModels, components: $components, tags: $tags',
    );
    print('DEBUG UPLOAD: Starting upload...');

    try {
      // Upload document and get immediate response (document created)
      // Processing happens in background, SSE will handle progress updates
      final result = await apiService.uploadDocument(
        file: _selectedFile!,
        name: _nameController.text.trim(),
        bikeModels: bikeModels,
        components: components,
        tags: tags,
        visibility: _selectedVisibility ?? 'public',
      );

      print('DEBUG UPLOAD: Document created successfully: $result');
      print('DEBUG UPLOAD: Result type: ${result.runtimeType}');
      print('DEBUG UPLOAD: Result keys: ${result.keys}');

      // Create Document object from upload result
      final uploadedDocument = Document.fromJson(result);
      print('DEBUG UPLOAD: Document object created: ${uploadedDocument.id}');

      // Navigate back immediately - SSE will handle progress updates
      if (mounted) {
        print(
          'DEBUG UPLOAD: Returning to home screen with document: ${uploadedDocument.id}',
        );
        Navigator.pop(context, uploadedDocument);
        print('DEBUG UPLOAD: Navigator.pop() completed');
      }
    } catch (e) {
      print('DEBUG UPLOAD ERROR: Upload failed: $e');
      print('DEBUG UPLOAD ERROR: Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _selectedFile != null
                              ? 'File Selected'
                              : 'Choose PDF File',
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_selectedFile!.name}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Document Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Document Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter document name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bikeModelsController,
                        decoration: const InputDecoration(
                          labelText: 'Bike Models (comma-separated)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.motorcycle),
                          hintText: 'e.g., Honda CBR600RR, Yamaha R1',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter at least one bike model';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _componentsController,
                        decoration: const InputDecoration(
                          labelText: 'Components (comma-separated)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build),
                          hintText: 'e.g., Engine, Transmission, Brakes',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter at least one component';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'e.g., manual, service, repair',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibility',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.visibility),
                        ),
                        items: _visibilityOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedVisibility = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select visibility';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadDocument,
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
