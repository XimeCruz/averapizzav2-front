// lib/presentation/providers/carrito_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/item_carrito_model.dart';
import '../../data/models/pedido_model.dart';
import '../../data/repositories/pedido_repository.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/api_constants.dart';

enum TipoEntrega {
  LOCAL,
  DELIVERY;

  IconData get icono {
    switch (this) {
      case LOCAL:
        return Icons.store;
      case DELIVERY:
        return Icons.delivery_dining;
    }
  }

  String get texto {
    switch (this) {
      case LOCAL:
        return 'Recoger en local';
      case DELIVERY:
        return 'Delivery';
    }
  }

  // Mapear a TipoServicio del backend
  TipoServicio toTipoServicio() {
    switch (this) {
      case LOCAL:
        return TipoServicio.LLEVAR;
      case DELIVERY:
        return TipoServicio.DELIVERY;
    }
  }
}

class CarritoProvider extends ChangeNotifier {
  final PedidoRepository _pedidoRepository = PedidoRepository();

  List<ItemCarrito> _items = [];
  TipoEntrega _tipoEntrega = TipoEntrega.LOCAL;
  String? _direccionEntrega;
  bool _procesandoPedido = false;

  List<ItemCarrito> get items => _items;
  TipoEntrega get tipoEntrega => _tipoEntrega;
  String? get direccionEntrega => _direccionEntrega;
  bool get procesandoPedido => _procesandoPedido;

  bool get estaVacio => _items.isEmpty;
  int get cantidadItems => _items.length;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get costoDelivery {
    if (_tipoEntrega == TipoEntrega.DELIVERY) {
      return subtotal >= 100 ? 0.0 : 10.0;
    }
    return 0.0;
  }

  double get total => subtotal + costoDelivery;

  void setTipoEntrega(TipoEntrega tipo) {
    _tipoEntrega = tipo;
    notifyListeners();
  }

  void setDireccionEntrega(String direccion) {
    _direccionEntrega = direccion;
    notifyListeners();
  }

  void agregarItem(ItemCarrito item) {
    _items.add(item);
    notifyListeners();
  }

  void eliminarItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void incrementarCantidad(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index] = _items[index].copyWith(
        cantidad: _items[index].cantidad + 1,
      );
      notifyListeners();
    }
  }

  void decrementarCantidad(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].cantidad > 1) {
        _items[index] = _items[index].copyWith(
          cantidad: _items[index].cantidad - 1,
        );
        notifyListeners();
      } else {
        eliminarItem(index);
      }
    }
  }

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  void limpiarDespuesDePedido() {
    _items.clear();
    _tipoEntrega = TipoEntrega.LOCAL;
    _direccionEntrega = null;
    notifyListeners();
  }

  Future<Pedido> confirmarPedido(MetodoPago metodoPago) async {
    _procesandoPedido = true;
    notifyListeners();

    try {
      final userId = await SecureStorage.getUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Separar pizzas y otros productos
      final List<PizzaPedidoItem> pizzas = [];
      final List<DetallePedidoRequest> detalles = [];

      for (var item in _items) {
        if (item.esPizza) {
          final pizzaItem = item.toPizzaPedidoItem();
          if (pizzaItem != null) {
            pizzas.add(pizzaItem);
          }
        } else {
          final detalleItem = item.toDetallePedidoRequest();
          if (detalleItem != null) {
            detalles.add(detalleItem);
          }
        }
      }

      final tipoServicio = _tipoEntrega.toTipoServicio();

      final request = CreatePedidoRequest(
        usuarioId: userId,
        tipoServicio: tipoServicio,
        metodoPago: metodoPago.name,
        pizzas: pizzas,
        detalles: detalles,
      );

      final pedido = await _pedidoRepository.createPedido(request);

      _procesandoPedido = false;
      notifyListeners();

      return pedido;
    } catch (e) {
      _procesandoPedido = false;
      notifyListeners();
      rethrow;
    }
  }
}