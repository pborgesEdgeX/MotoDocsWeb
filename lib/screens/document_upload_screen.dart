import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({Key? key}) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bikeModelsController = TextEditingController();
  final _componentsController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedVisibility = 'public';
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadStatus;

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;

          // Auto-populate document name from filename (without .pdf extension)
          String fileName = _selectedFile!.name;
          if (fileName.toLowerCase().endsWith('.pdf')) {
            fileName = fileName.substring(0, fileName.length - 4);
          }
          _nameController.text = fileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = ApiService();

      // Set the auth token for authenticated uploads
      final token = await authService.auth.currentUser?.getIdToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }

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

      // Convert PlatformFile to html.File for Flutter web
      final htmlFile = html.File(
        [_selectedFile!.bytes!],
        _selectedFile!.name,
        {'type': 'application/pdf'},
      );

      final response = await apiService.uploadDocument(
        file: htmlFile,
        name: _nameController.text,
        bikeModels: bikeModels,
        components: components,
        tags: tags,
        visibility: _selectedVisibility,
      );

      if (mounted) {
        setState(() {
          _uploadStatus =
              'Document uploaded successfully! Doc ID: ${response['id']}';
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _nameController.clear();
        _bikeModelsController.clear();
        _componentsController.clear();
        _tagsController.clear();
        setState(() {
          _selectedFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = 'Error: $e';
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
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
        title: const Text('Upload Document'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Motorcycle Manual',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload PDF documents to be indexed for AI search',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // File Picker
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    size: 40,
                    color: Colors.orange,
                  ),
                  title: Text(
                    _selectedFile?.name ?? 'No file selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: _selectedFile != null
                      ? Text(
                          '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        )
                      : const Text('Click to select PDF file'),
                  trailing: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Document Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Document Name *',
                  hintText: 'e.g., Harley Davidson FXS 1974 Service Manual',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a document name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bike Models
              TextFormField(
                controller: _bikeModelsController,
                decoration: const InputDecoration(
                  labelText: 'Bike Models *',
                  hintText: 'e.g., FXS 1974, Dyna 2010-2019',
                  helperText: 'Separate multiple models with commas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one bike model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Components
              TextFormField(
                controller: _componentsController,
                decoration: const InputDecoration(
                  labelText: 'Components',
                  hintText: 'e.g., Engine, Transmission, Brakes',
                  helperText: 'Separate multiple components with commas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g., service, manual, repair',
                  helperText: 'Separate multiple tags with commas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Visibility
              DropdownButtonFormField<String>(
                value: _selectedVisibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Upload Status
              if (_uploadStatus != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _uploadStatus!.startsWith('Error')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _uploadStatus!,
                    style: TextStyle(
                      color: _uploadStatus!.startsWith('Error')
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || _selectedFile == null
                      ? null
                      : _uploadDocument,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Upload Document',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
