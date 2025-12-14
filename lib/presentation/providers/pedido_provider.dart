// lib/presentation/providers/pedido_provider.dart

import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/pedido_repository.dart';
import '../../data/models/pedido_model.dart';

enum PedidoStatus { initial, loading, loaded, error }

class PedidoProvider extends ChangeNotifier {
  final PedidoRepository _repository = PedidoRepository();

  PedidoStatus _status = PedidoStatus.initial;
  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosPendientes = [];
  List<Pedido> _pedidosEnPreparacion = [];
  List<Pedido> _pedidosListos = [];
  String? _errorMessage;

  PedidoStatus get status => _status;
  List<Pedido> get pedidos => _pedidos;
  List<Pedido> get pedidosPendientes => _pedidosPendientes;
  List<Pedido> get pedidosEnPreparacion => _pedidosEnPreparacion;
  List<Pedido> get pedidosListos => _pedidosListos;
  String? get errorMessage => _errorMessage;

  // ========== CREAR PEDIDO ==========
  Future<Pedido?> createPedido(CreatePedidoRequest request) async {
    try {
      _status = PedidoStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final pedido = await _repository.createPedido(request);
      _pedidos.insert(0, pedido);
      _pedidosPendientes.insert(0, pedido);

      _status = PedidoStatus.loaded;
      notifyListeners();
      return pedido;
    } catch (e) {
      _status = PedidoStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ========== CARGAR PEDIDOS ==========
  Future<void> loadPedidos() async {
    try {
      _status = PedidoStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _pedidos = await _repository.getPedidos();
      _status = PedidoStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = PedidoStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadPedidosByEstado(EstadoPedido estado) async {
    try {
      _errorMessage = null;
      final pedidos = await _repository.getPedidosByEstado(estado);

      switch (estado) {
        case EstadoPedido.PENDIENTE:
          _pedidosPendientes = pedidos;
          break;
        case EstadoPedido.EN_PREPARACION:
          _pedidosEnPreparacion = pedidos;
          break;
        case EstadoPedido.LISTO:
          _pedidosListos = pedidos;
          break;
        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== COCINA - CARGAR PEDIDOS ==========
  Future<void> loadPedidosPendientes() async {
    try {
      _errorMessage = null;
      _pedidosPendientes = await _repository.getPedidosPendientes();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadPedidosEnPreparacion() async {
    try {
      _errorMessage = null;
      _pedidosEnPreparacion = await _repository.getPedidosEnPreparacion();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== ACCIONES DE PEDIDO ==========
  Future<bool> tomarPedido(int id) async {
    try {
      _errorMessage = null;
      final pedido = await _repository.tomarPedido(id);

      // Remover de pendientes
      _pedidosPendientes.removeWhere((p) => p.id == id);

      // Agregar a en preparación
      _pedidosEnPreparacion.insert(0, pedido);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> marcarListo(int id) async {
    try {
      _errorMessage = null;
      final pedido = await _repository.marcarListo(id);

      // Remover de en preparación
      _pedidosEnPreparacion.removeWhere((p) => p.id == id);

      // Agregar a listos
      _pedidosListos.insert(0, pedido);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> entregarPedido(int id) async {
    try {
      _errorMessage = null;
      await _repository.entregarPedido(id);

      // Remover de listos
      _pedidosListos.removeWhere((p) => p.id == id);

      // Actualizar en la lista general
      final index = _pedidos.indexWhere((p) => p.id == id);
      if (index != -1) {
        final pedido = _pedidos[index];
        _pedidos[index] = Pedido(
          id: pedido.id,
          usuarioId: pedido.usuarioId,
          usuarioNombre: pedido.usuarioNombre,
          estado: EstadoPedido.ENTREGADO,
          tipoServicio: pedido.tipoServicio,
          fechaHora: pedido.fechaHora,
          total: pedido.total,
          detalles: pedido.detalles,
          metodoPago: pedido.metodoPago,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarPedido(int id) async {
    try {
      _errorMessage = null;
      await _repository.cancelarPedido(id);

      // Remover de todas las listas
      _pedidosPendientes.removeWhere((p) => p.id == id);
      _pedidosEnPreparacion.removeWhere((p) => p.id == id);
      _pedidosListos.removeWhere((p) => p.id == id);

      // Actualizar en la lista general
      final index = _pedidos.indexWhere((p) => p.id == id);
      if (index != -1) {
        final pedido = _pedidos[index];
        _pedidos[index] = Pedido(
          id: pedido.id,
          usuarioId: pedido.usuarioId,
          usuarioNombre: pedido.usuarioNombre,
          estado: EstadoPedido.CANCELADO,
          tipoServicio: pedido.tipoServicio,
          fechaHora: pedido.fechaHora,
          total: pedido.total,
          detalles: pedido.detalles,
          metodoPago: pedido.metodoPago,
        );
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
  Pedido? getPedidoById(int id) {
    try {
      return _pedidos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  int getCantidadPedidosPendientes() => _pedidosPendientes.length;
  int getCantidadPedidosEnPreparacion() => _pedidosEnPreparacion.length;
  int getCantidadPedidosListos() => _pedidosListos.length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}