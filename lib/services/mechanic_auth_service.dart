import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/mechanic.dart';
import 'api_service.dart';

class MechanicAuthService extends ChangeNotifier {
  Mechanic? _currentMechanic;
  String? _mechanicToken;
  bool _isLoading = false;
  String? _errorMessage;

  Mechanic? get currentMechanic => _currentMechanic;
  String? get mechanicToken => _mechanicToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentMechanic != null && _mechanicToken != null;

  final ApiService _apiService;

  MechanicAuthService(this._apiService) {
    _loadStoredAuth();
  }

  void _loadStoredAuth() {
    try {
      final token = html.window.localStorage['mechanic_token'];
      final mechanicData = html.window.localStorage['mechanic_data'];

      if (token != null && mechanicData != null) {
        _mechanicToken = token;
        _currentMechanic = Mechanic.fromJson(
          Map<String, dynamic>.from(
            _parseJson(mechanicData),
          ),
        );
        _apiService.setAuthToken(token);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading stored auth: $e');
    }
  }

  dynamic _parseJson(String jsonString) {
    try {
      return html.window.JSON.parse(jsonString);
    } catch (e) {
      return {};
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.loginMechanic(email, password);

      _mechanicToken = response['access_token'] as String;
      _currentMechanic = Mechanic.fromJson(
        response['mechanic'] as Map<String, dynamic>,
      );

      // Store in local storage
      html.window.localStorage['mechanic_token'] = _mechanicToken!;
      html.window.localStorage['mechanic_data'] =
          html.window.JSON.stringify(_currentMechanic!.toJson());

      // Set auth token for API calls
      _apiService.setAuthToken(_mechanicToken!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.registerMechanic(data);

      // After registration, automatically log them in
      _mechanicToken = 'temp_token'; // In production, get from response
      _currentMechanic = Mechanic.fromJson(response);

      // Store in local storage
      html.window.localStorage['mechanic_token'] = _mechanicToken!;
      html.window.localStorage['mechanic_data'] =
          html.window.JSON.stringify(_currentMechanic!.toJson());

      // Set auth token for API calls
      _apiService.setAuthToken(_mechanicToken!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    if (_mechanicToken == null) return;

    try {
      _apiService.setAuthToken(_mechanicToken!);
      final mechanic = await _apiService.getMechanicProfile();

      _currentMechanic = mechanic;

      // Update stored data
      html.window.localStorage['mechanic_data'] =
          html.window.JSON.stringify(mechanic.toJson());

      notifyListeners();
    } catch (e) {
      print('Error refreshing mechanic profile: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_mechanicToken == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _apiService.setAuthToken(_mechanicToken!);
      final updatedMechanic = await _apiService.updateMechanicProfile(data);

      _currentMechanic = updatedMechanic;

      // Update stored data
      html.window.localStorage['mechanic_data'] =
          html.window.JSON.stringify(updatedMechanic.toJson());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    if (_mechanicToken == null) return;

    try {
      _apiService.setAuthToken(_mechanicToken!);
      final updatedMechanic =
          await _apiService.toggleMechanicAvailability(isAvailable);

      _currentMechanic = updatedMechanic;

      // Update stored data
      html.window.localStorage['mechanic_data'] =
          html.window.JSON.stringify(updatedMechanic.toJson());

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void logout() {
    _currentMechanic = null;
    _mechanicToken = null;
    _errorMessage = null;

    // Clear local storage
    html.window.localStorage.remove('mechanic_token');
    html.window.localStorage.remove('mechanic_data');

    // Clear API token
    _apiService.clearAuthToken();

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

