// lib/presentation/providers/menu_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/producto_repository.dart';

class MenuProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();

  MenuResponse? _menu;
  bool _isLoading = false;
  String? _error;

  MenuResponse? get menu => _menu;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, List<ProductoDto>> get pizzasPorPresentacion => _menu?.pizzas ?? {};
  List<ProductoDto> get bebidas => _menu?.bebidas ?? [];

  // Obtener sabores de una presentación específica
  List<ProductoDto> getSaboresByPresentacion(String presentacion) {
    return pizzasPorPresentacion[presentacion] ?? [];
  }

  // Obtener precio de un sabor específico en una presentación
  double? getPrecioPorSaborYPresentacion(String nombreSabor, String presentacion) {
    final sabores = getSaboresByPresentacion(presentacion);
    final sabor = sabores.firstWhere(
          (s) => s.nombre == nombreSabor,
      orElse: () => sabores.first,
    );
    return sabor.precio;
  }

  Future<void> cargarMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menu = await _repository.obtenerMenu();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}