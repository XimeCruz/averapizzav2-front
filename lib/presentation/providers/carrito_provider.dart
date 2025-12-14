// lib/presentation/providers/carrito_provider.dart

import 'package:avp_frontend/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/item_carrito_model.dart';

class CarritoProvider extends ChangeNotifier {
  final List<ItemCarrito> _items = [];
  String _notasEspeciales = '';
  TipoServicio _tipoEntrega = TipoServicio.MESA;
  String? _direccionEntrega;

  // Getters
  List<ItemCarrito> get items => List.unmodifiable(_items);
  String get notasEspeciales => _notasEspeciales;
  TipoServicio get tipoEntrega => _tipoEntrega;
  String? get direccionEntrega => _direccionEntrega;

  /// Cantidad total de items en el carrito
  int get cantidadItems {
    return _items.fold(0, (total, item) => total + item.cantidad);
  }

  /// Cantidad total de productos únicos
  int get cantidadProductos => _items.length;

  /// Subtotal (sin delivery)
  double get subtotal {
    return _items.fold(0.0, (total, item) => total + item.subtotal);
  }

  /// Costo de delivery
  double get costoDelivery {
    if (_tipoEntrega == TipoServicio.DELIVERY) {
      // Envío gratis en compras mayores a $50
      return subtotal >= 50.0 ? 0.0 : 5.0;
    }
    return 0.0;
  }

  /// Total a pagar (subtotal + delivery)
  double get total {
    return subtotal + costoDelivery;
  }

  /// Verificar si el carrito está vacío
  bool get estaVacio => _items.isEmpty;

  // MÉTODOS DE GESTIÓN DE ITEMS

  /// Agregar un producto al carrito
  void agregarItem({
    required int productoId,
    required String nombre,
    required double precio,
    required String categoria,
    String? observaciones,
    int cantidad = 1,
  }) {
    // Buscar si el item ya existe
    final index = _items.indexWhere(
          (item) =>
      item.productoId == productoId &&
          item.observaciones == observaciones,
    );

    if (index >= 0) {
      // Si existe, aumentar cantidad
      _items[index].cantidad += cantidad;
    } else {
      // Si no existe, agregar nuevo
      _items.add(ItemCarrito(
        productoId: productoId,
        nombre: nombre,
        precio: precio,
        cantidad: cantidad,
        categoria: categoria,
        observaciones: observaciones,
      ));
    }

    notifyListeners();
  }

  /// Actualizar cantidad de un item
  void actualizarCantidad(int index, int nuevaCantidad) {
    if (index < 0 || index >= _items.length) return;

    if (nuevaCantidad <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].cantidad = nuevaCantidad;
    }

    notifyListeners();
  }

  /// Incrementar cantidad de un item
  void incrementarCantidad(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].cantidad++;
    notifyListeners();
  }

  /// Decrementar cantidad de un item
  void decrementarCantidad(int index) {
    if (index < 0 || index >= _items.length) return;

    if (_items[index].cantidad > 1) {
      _items[index].cantidad--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  /// Eliminar un item del carrito
  void eliminarItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  /// Vaciar el carrito completo
  void vaciarCarrito() {
    _items.clear();
    _notasEspeciales = '';
    _direccionEntrega = null;
    notifyListeners();
  }

  // MÉTODOS DE CONFIGURACIÓN DE PEDIDO

  /// Establecer notas especiales para el pedido
  void setNotasEspeciales(String notas) {
    _notasEspeciales = notas;
    notifyListeners();
  }

  /// Establecer tipo de entrega
  void setTipoEntrega(TipoServicio tipo) {
    _tipoEntrega = tipo;
    if (tipo == TipoServicio.MESA) {
      _direccionEntrega = null;
    }
    notifyListeners();
  }

  /// Establecer dirección de entrega
  void setDireccionEntrega(String? direccion) {
    _direccionEntrega = direccion;
    notifyListeners();
  }

  // MÉTODOS DE UTILIDAD

  /// Obtener resumen del carrito para enviar al backend
  Map<String, dynamic> obtenerResumenPedido() {
    return {
      'items': _items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'costoDelivery': costoDelivery,
      'total': total,
      'notasEspeciales': _notasEspeciales,
      'tipoEntrega': _tipoEntrega.toString(),
      'direccionEntrega': _direccionEntrega,
      'cantidadItems': cantidadItems,
    };
  }

  /// Verificar si un producto específico está en el carrito
  bool contieneProducto(int productoId) {
    return _items.any((item) => item.productoId == productoId);
  }

  /// Obtener cantidad de un producto específico
  int obtenerCantidadProducto(int productoId) {
    return _items
        .where((item) => item.productoId == productoId)
        .fold(0, (total, item) => total + item.cantidad);
  }

  /// Limpiar carrito después de un pedido exitoso
  void limpiarDespuesDePedido() {
    vaciarCarrito();
    _tipoEntrega = TipoServicio.MESA;
  }
}


