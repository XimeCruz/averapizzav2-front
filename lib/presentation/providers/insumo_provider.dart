// lib/presentation/providers/insumo_provider.dart

import 'package:flutter/material.dart';
import '../../data/repositories/insumo_repository.dart';
import '../../data/models/insumo_model.dart';

enum InsumoStatus { initial, loading, loaded, error }

class InsumoProvider extends ChangeNotifier {
  final InsumoRepository _repository = InsumoRepository();

  InsumoStatus _status = InsumoStatus.initial;
  List<Insumo> _insumos = [];
  List<Insumo> _insumosBajoStock = [];
  List<MovimientoInventario> _movimientos = [];
  String? _errorMessage;

  InsumoStatus get status => _status;
  List<Insumo> get insumos => _insumos;
  List<Insumo> get insumosBajoStock => _insumosBajoStock;
  List<MovimientoInventario> get movimientos => _movimientos;
  String? get errorMessage => _errorMessage;

  // ========== CARGAR INSUMOS ==========
  Future<void> loadInsumos() async {
    try {
      _status = InsumoStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _insumos = await _repository.getInsumos();
      _status = InsumoStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = InsumoStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CARGAR INSUMOS BAJO STOCK ==========
  Future<void> loadInsumosBajoStock() async {
    try {
      _insumosBajoStock = await _repository.getInsumosBajoStock();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CREAR INSUMO ==========
  Future<bool> createInsumo(CreateInsumoRequest request) async {
    try {
      _status = InsumoStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final newInsumo = await _repository.createInsumo(request);
      _insumos.add(newInsumo);

      _status = InsumoStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = InsumoStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ACTUALIZAR INSUMO ==========
  Future<bool> updateInsumo(int id, UpdateInsumoRequest request) async {
    try {
      _errorMessage = null;
      final updatedInsumo = await _repository.updateInsumo(id, request);

      final index = _insumos.indexWhere((i) => i.id == id);
      if (index != -1) {
        _insumos[index] = updatedInsumo;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ELIMINAR INSUMO ==========
  Future<bool> deleteInsumo(int id) async {
    try {
      _errorMessage = null;
      await _repository.deleteInsumo(id);
      _insumos.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== AJUSTAR STOCK ==========
  Future<bool> ajustarStock(AjustarStockRequest request) async {
    try {
      _errorMessage = null;
      await _repository.ajustarStock(request);

      // Recargar el insumo actualizado
      final insumo = await _repository.getInsumoById(request.insumoId);
      final index = _insumos.indexWhere((i) => i.id == request.insumoId);
      if (index != -1) {
        _insumos[index] = insumo;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== VERIFICAR STOCK ==========
  Future<bool> verificarStock(List<Map<String, dynamic>> items) async {
    try {
      return await _repository.verificarStock(items);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== CARGAR MOVIMIENTOS ==========
  Future<void> loadMovimientos() async {
    try {
      _movimientos = await _repository.getMovimientos();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadMovimientosByInsumo(int insumoId) async {
    try {
      _movimientos = await _repository.getMovimientosByInsumo(insumoId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== UTILIDADES ==========
  Insumo? getInsumoById(int id) {
    try {
      return _insumos.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}