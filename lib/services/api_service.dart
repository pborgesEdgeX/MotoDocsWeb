import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import '../models/document.dart';
import '../models/suggestion.dart';
import '../models/mechanic.dart';
import '../models/availability_slot.dart';
import '../models/appointment.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(
          minutes: 5,
        ), // Increased for AI RAG operations
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/healthz');
      return response.data;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  // Get backend version
  Future<Map<String, dynamic>> getBackendVersion() async {
    try {
      final response = await _dio.get('/version');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get backend version: $e');
    }
  }

  // Documents API
  Future<List<Document>> getDocuments() async {
    try {
      final response = await _dio.get('/api/v1/documents/');
      final List<dynamic> documentsJson = response.data['documents'] ?? [];
      return documentsJson.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<List<String>> getBikeModels() async {
    try {
      final response = await _dio.get('/api/v1/documents/bike-models');
      final List<dynamic> modelsJson = response.data ?? [];
      return modelsJson.map((model) => model.toString()).toList();
    } catch (e) {
      throw Exception('Failed to fetch bike models: $e');
    }
  }

  Future<Map<String, dynamic>> getSeparatedBikeModels() async {
    try {
      final response = await _dio.get(
        '/api/v1/documents/bike-models/separated',
      );
      final Map<String, dynamic> data = response.data ?? {};

      final List<dynamic> modelsJson = data['models'] ?? [];
      final List<dynamic> yearsJson = data['years'] ?? [];
      final Map<String, dynamic> modelYearsJson = data['model_years'] ?? {};

      // Convert model_years to proper format
      Map<String, List<String>> modelYears = {};
      modelYearsJson.forEach((model, years) {
        if (years is List) {
          modelYears[model] = years.map((year) => year.toString()).toList();
        }
      });

      return {
        'models': modelsJson.map((model) => model.toString()).toList(),
        'years': yearsJson.map((year) => year.toString()).toList(),
        'model_years': modelYears,
      };
    } catch (e) {
      throw Exception('Failed to fetch separated bike models: $e');
    }
  }

  Future<Document> createDocument({
    required String name,
    required String mimeType,
    required List<String> bikeModels,
    required List<String> components,
    required List<String> tags,
    String visibility = 'public',
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/documents/',
        data: {
          'name': name,
          'mime_type': mimeType,
          'bike_models': bikeModels,
          'components': components,
          'tags': tags,
          'visibility': visibility,
        },
      );
      return Document.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  Future<Document> getDocument(String docId) async {
    try {
      final response = await _dio.get('/api/v1/documents/$docId');
      return Document.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  Future<Map<String, dynamic>> getDocumentStatus(String docId) async {
    try {
      final response = await _dio.get('/api/v1/documents/$docId/status');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch document status: $e');
    }
  }

  // Upload document
  Future<Map<String, dynamic>> uploadDocument({
    required html.File file,
    required String name,
    required List<String> bikeModels,
    required List<String> components,
    required List<String> tags,
    String visibility = 'public',
  }) async {
    print('DEBUG API: uploadDocument() called');
    print('DEBUG API: file: ${file.name}, name: $name');
    print(
      'DEBUG API: bikeModels: $bikeModels, components: $components, tags: $tags, visibility: $visibility',
    );

    try {
      // Use a simpler approach for Flutter web - read file as bytes with timeout
      print('DEBUG API: Reading file bytes with timeout...');
      final fileBytes = await _readFileAsBytesWithTimeout(file);
      print(
        'DEBUG API: File bytes read successfully, size: ${fileBytes.length}',
      );

      print('DEBUG API: Creating FormData...');
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: file.name),
        'name': name,
        'bike_models': bikeModels.join(','),
        'components': components.join(','),
        'tags': tags.join(','),
        'visibility': visibility,
      });

      print('DEBUG API: Sending POST request to /api/v1/documents/upload...');
      final response = await _dio.post(
        '/api/v1/documents/upload',
        data: formData,
      );
      print('DEBUG API: Upload response received: ${response.statusCode}');
      print('DEBUG API: Response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('DEBUG API ERROR: Upload failed: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Helper method to read file as bytes in Flutter web with timeout
  Future<List<int>> _readFileAsBytesWithTimeout(html.File file) async {
    final completer = Completer<List<int>>();
    final reader = html.FileReader();
    bool completed = false;

    // Set a timeout to prevent hanging
    Timer(const Duration(seconds: 10), () {
      if (!completed) {
        completed = true;
        completer.completeError('File read timeout after 10 seconds');
      }
    });

    reader.onLoad.listen((e) {
      if (!completed) {
        completed = true;
        final result = reader.result;
        if (result is List<int>) {
          completer.complete(result);
        } else {
          completer.completeError('Failed to read file as bytes');
        }
      }
    });

    reader.onError.listen((e) {
      if (!completed) {
        completed = true;
        completer.completeError('Error reading file: $e');
      }
    });

    try {
      reader.readAsArrayBuffer(file);
    } catch (e) {
      if (!completed) {
        completed = true;
        completer.completeError('Failed to start reading file: $e');
      }
    }

    return completer.future;
  }

  // RAG Suggestions
  Future<Map<String, dynamic>> getSuggestion({
    required String query,
    String? bikeModel,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/suggest',
        data: {
          'symptom': query,
          'bike_model': bikeModel ?? 'Unknown',
          'top_k': 6,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get suggestion: $e');
    }
  }

  // Delete document
  Future<void> deleteDocument(String docId) async {
    try {
      await _dio.delete('/api/v1/documents/$docId');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Admin functions
  Future<Map<String, dynamic>> ingestDocument(String docId) async {
    try {
      final response = await _dio.post('/api/admin/ingest/$docId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to ingest document: $e');
    }
  }

  // ============================================================================
  // Mechanic Scheduler API Methods
  // ============================================================================

  // Mechanic Authentication
  Future<Map<String, dynamic>> registerMechanic(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/mechanics/register', data: data);
      return response.data;
    } catch (e) {
      throw Exception('Failed to register mechanic: $e');
    }
  }

  Future<Map<String, dynamic>> loginMechanic(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/mechanics/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to login mechanic: $e');
    }
  }

  Future<Mechanic> getMechanicProfile() async {
    try {
      final response = await _dio.get('/api/v1/mechanics/me');
      return Mechanic.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get mechanic profile: $e');
    }
  }

  Future<Mechanic> updateMechanicProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/v1/mechanics/me', data: data);
      return Mechanic.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update mechanic profile: $e');
    }
  }

  Future<Mechanic> toggleMechanicAvailability(bool isAvailable) async {
    try {
      final response = await _dio.patch(
        '/api/v1/mechanics/me/availability',
        data: {'is_available': isAvailable},
      );
      return Mechanic.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Availability Management
  Future<List<AvailabilitySlot>> getAvailabilitySlots({bool activeOnly = true}) async {
    try {
      final response = await _dio.get(
        '/api/v1/mechanics/availability',
        queryParameters: {'active_only': activeOnly},
      );
      final data = response.data as Map<String, dynamic>;
      final slots = data['slots'] as List<dynamic>;
      return slots.map((slot) => AvailabilitySlot.fromJson(slot)).toList();
    } catch (e) {
      throw Exception('Failed to get availability slots: $e');
    }
  }

  Future<AvailabilitySlot> createAvailabilitySlot(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/v1/mechanics/availability',
        data: data,
      );
      return AvailabilitySlot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create availability slot: $e');
    }
  }

  Future<AvailabilitySlot> updateAvailabilitySlot(
    String slotId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/mechanics/availability/$slotId',
        data: data,
      );
      return AvailabilitySlot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update availability slot: $e');
    }
  }

  Future<void> deleteAvailabilitySlot(String slotId) async {
    try {
      await _dio.delete('/api/v1/mechanics/availability/$slotId');
    } catch (e) {
      throw Exception('Failed to delete availability slot: $e');
    }
  }

  // Appointments
  Future<List<MechanicPublicInfo>> getAvailableMechanics({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/appointments/available-mechanics',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = response.data as Map<String, dynamic>;
      final mechanics = data['mechanics'] as List<dynamic>;
      return mechanics.map((m) => MechanicPublicInfo.fromJson(m)).toList();
    } catch (e) {
      throw Exception('Failed to get available mechanics: $e');
    }
  }

  Future<Appointment> scheduleAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/v1/appointments/schedule',
        data: data,
      );
      return Appointment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to schedule appointment: $e');
    }
  }

  Future<List<Appointment>> getMyAppointments({
    String? statusFilter,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/appointments/my-appointments',
        queryParameters: {
          if (statusFilter != null) 'status_filter': statusFilter,
          'page': page,
          'per_page': perPage,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final appointments = data['appointments'] as List<dynamic>;
      return appointments.map((a) => Appointment.fromJson(a)).toList();
    } catch (e) {
      throw Exception('Failed to get my appointments: $e');
    }
  }

  Future<List<Appointment>> getMechanicAppointments({
    String? statusFilter,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/appointments/mechanic-appointments',
        queryParameters: {
          if (statusFilter != null) 'status_filter': statusFilter,
          'page': page,
          'per_page': perPage,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final appointments = data['appointments'] as List<dynamic>;
      return appointments.map((a) => Appointment.fromJson(a)).toList();
    } catch (e) {
      throw Exception('Failed to get mechanic appointments: $e');
    }
  }

  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/v1/appointments/$appointmentId/status',
        data: data,
      );
      return Appointment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Agora Token Generation
  Future<Map<String, dynamic>> generateAgoraToken(
    String appointmentId,
    String userType,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/appointments/agora/token',
        data: {
          'appointment_id': appointmentId,
          'user_type': userType,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to generate Agora token: $e');
    }
  }
}
