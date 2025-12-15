// lib/presentation/providers/cliente_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/cliente_estadisticas_model.dart';
import '../../data/repositories/cliente_repository.dart';
import 'auth_provider.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteRepository _repository;
  final AuthProvider _authProvider;

  ClienteProvider(this._repository,this._authProvider);

  ClienteEstadisticasModel? _estadisticas;
  bool _isLoading = false;
  String? _error;

  ClienteEstadisticasModel? get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _getClienteId() {
    final userId = _authProvider.userId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return userId.toString();
  }

  Future<void> loadEstadisticas(int idCliente) async {
    final clienteId = await _getClienteId();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _estadisticas = await _repository.getEstadisticas(clienteId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _estadisticas = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEstadisticas() {
    _estadisticas = null;
    _error = null;
    notifyListeners();
  }
}