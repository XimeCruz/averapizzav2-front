// lib/presentation/providers/producto_provider.dart

import 'package:flutter/material.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/models/producto_model.dart';

enum ProductoStatus { initial, loading, loaded, error }

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();

  ProductoStatus _status = ProductoStatus.initial;
  List<Producto> _productos = [];
  List<SaborPizza> _sabores = [];
  List<PresentacionProducto> _presentaciones = [];
  String? _errorMessage;

  ProductoStatus get status => _status;
  List<Producto> get productos => _productos;
  List<SaborPizza> get sabores => _sabores;
  List<PresentacionProducto> get presentaciones => _presentaciones;
  String? get errorMessage => _errorMessage;

  // ========== PRODUCTOS ==========
  Future<void> loadProductos() async {
    try {
      _status = ProductoStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _productos = await _repository.getProductos();
      _status = ProductoStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = ProductoStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createProducto(CreateProductoRequest request) async {
    try {
      _errorMessage = null;
      final newProducto = await _repository.createProducto(request);
      _productos.add(newProducto);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProducto(int id, CreateProductoRequest request) async {
    try {
      _errorMessage = null;
      final updatedProducto = await _repository.updateProducto(id, request);

      final index = _productos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _productos[index] = updatedProducto;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProducto(int id) async {
    try {
      _errorMessage = null;
      await _repository.deleteProducto(id);
      _productos.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== SABORES ==========
  Future<void> loadSabores() async {
    try {
      _errorMessage = null;
      _sabores = await _repository.getSabores();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadSaboresByProducto(int productoId) async {
    try {
      _errorMessage = null;
      _sabores = await _repository.getSaboresByProducto(productoId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createSabor(CreateSaborRequest request) async {
    try {
      _errorMessage = null;
      final newSabor = await _repository.createSabor(request);
      _sabores.add(newSabor);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSabor(int id, CreateSaborRequest request) async {
    try {
      _errorMessage = null;
      final updatedSabor = await _repository.updateSabor(id, request);

      final index = _sabores.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sabores[index] = updatedSabor;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSabor(int id) async {
    try {
      _errorMessage = null;
      await _repository.deleteSabor(id);
      _sabores.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== PRESENTACIONES ==========
  Future<void> loadPresentacionesByProducto(int productoId) async {
    try {
      _errorMessage = null;
      _presentaciones = await _repository.getPresentacionesByProducto(productoId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _presentaciones = [];
      notifyListeners();
    }
  }

  Future<void> loadPresentaciones() async {
    try {
      _errorMessage = null;
      _presentaciones = await _repository.getPresentaciones();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createPresentacion(CreatePresentacionRequest request) async {
    try {
      _errorMessage = null;
      final newPresentacion = await _repository.createPresentacion(request);
      _presentaciones.add(newPresentacion);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== PRECIOS ==========
  Future<List<PrecioSaborPresentacion>> loadPreciosBySabor(int saborId) async {
    try {
      _errorMessage = null;
      return await _repository.getPreciosBySabor(saborId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  Future<bool> createPrecio(int saborId, CreatePrecioRequest request) async {
    try {
      _errorMessage = null;
      await _repository.createPrecio(saborId, request);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePrecio(int precioId, CreatePrecioRequest request) async {
    try {
      _errorMessage = null;
      await _repository.updatePrecio(precioId, request);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== UTILIDADES ==========
  Producto? getProductoById(int id) {
    try {
      return _productos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  SaborPizza? getSaborById(int id) {
    try {
      return _sabores.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  PresentacionProducto? getPresentacionById(int id) {
    try {
      return _presentaciones.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}