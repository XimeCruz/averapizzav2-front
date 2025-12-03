import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  int? _userId;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  int? get userId => _userId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    if (_repository.isAuthenticated()) {
      _userName = _repository.getUserName();
      _userRole = _repository.getUserRole();
      _userId = _repository.getUserId();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final request = LoginRequest(
        correo: username,
        password: password,
      );

      final response = await _repository.login(request);

      _userName = response.nombreUsuario;
      _userEmail = response.correo;
      _userRole = response.rol;
      _userId = response.usuarioId;
      _status = AuthStatus.authenticated;

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String role) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final request = RegisterRequest(
        nombre: username,
        correo: email,
        password: password,
      );

      final response = await _repository.register(request, role);

      _userName = response.nombreUsuario;
      _userEmail = response.correo;
      _userRole = response.rol;
      _userId = response.usuarioId;
      _status = AuthStatus.authenticated;

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _userName = null;
    _userRole = null;
    _userEmail = null;
    _userId = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}