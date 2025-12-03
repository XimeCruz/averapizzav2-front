// lib/presentation/providers/receta_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/receta_model.dart';
import '../../data/repositories/receta_repository.dart';

enum RecetaStatus { initial, loading, loaded, error }

class RecetaProvider extends ChangeNotifier {
  final RecetaRepository _repository = RecetaRepository();

  RecetaStatus _status = RecetaStatus.initial;
  List<Receta> _recetas = [];
  Receta? _recetaActual;
  String? _errorMessage;

  RecetaStatus get status => _status;
  List<Receta> get recetas => _recetas;
  Receta? get recetaActual => _recetaActual;
  String? get errorMessage => _errorMessage;

  // ========== CARGAR RECETAS ==========
  Future<void> loadRecetas() async {
    try {
      _status = RecetaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _recetas = await _repository.getRecetas();
      _status = RecetaStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = RecetaStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CARGAR RECETA POR SABOR ==========
  Future<void> loadRecetaBySabor(int saborId) async {
    try {
      _status = RecetaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _recetaActual = await _repository.getRecetaBySabor(saborId);
      _status = RecetaStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = RecetaStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _recetaActual = null;
      notifyListeners();
    }
  }

  // ========== CREAR RECETA ==========
  Future<bool> createReceta(int saborId, CreateRecetaRequest request) async {
    try {
      _status = RecetaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final receta = await _repository.createReceta(saborId, request);
      _recetas.add(receta);
      _recetaActual = receta;

      _status = RecetaStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = RecetaStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ACTUALIZAR RECETA ==========
  Future<bool> updateReceta(int saborId, UpdateRecetaRequest request) async {
    try {
      _errorMessage = null;
      final receta = await _repository.updateReceta(saborId, request);

      final index = _recetas.indexWhere((r) => r.saborId == saborId);
      if (index != -1) {
        _recetas[index] = receta;
      }
      _recetaActual = receta;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ELIMINAR RECETA ==========
  Future<bool> deleteReceta(int saborId) async {
    try {
      _errorMessage = null;
      await _repository.deleteReceta(saborId);
      _recetas.removeWhere((r) => r.saborId == saborId);

      if (_recetaActual?.saborId == saborId) {
        _recetaActual = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== UTILIDADES ==========
  Receta? getRecetaBySaborId(int saborId) {
    try {
      return _recetas.firstWhere((r) => r.saborId == saborId);
    } catch (e) {
      return null;
    }
  }

  void clearRecetaActual() {
    _recetaActual = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}