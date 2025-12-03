// lib/data/repositories/pedido_repository.dart

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/pedido_model.dart';

class PedidoRepository {
  final ApiClient _apiClient = ApiClient();

  // ========== CAJERO - PEDIDOS ==========
  Future<Pedido> createPedido(CreatePedidoRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.pedidosCajero,
        data: request.toJson(),
      );
      return Pedido.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear pedido: ${e.toString()}');
    }
  }

  Future<List<Pedido>> getPedidos() async {
    try {
      final response = await _apiClient.get(ApiConstants.pedidosCajero);
      return (response.data as List)
          .map((e) => Pedido.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos: ${e.toString()}');
    }
  }

  Future<List<Pedido>> getPedidosByEstado(EstadoPedido estado) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.pedidosByEstado(estado.name),
      );
      return (response.data as List)
          .map((e) => Pedido.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos por estado: ${e.toString()}');
    }
  }

  Future<Pedido> getPedidoById(int id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.pedidosCajero}/$id',
      );
      return Pedido.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener pedido: ${e.toString()}');
    }
  }

  Future<void> entregarPedido(int id) async {
    try {
      await _apiClient.put(ApiConstants.entregarPedido(id));
    } catch (e) {
      throw Exception('Error al entregar pedido: ${e.toString()}');
    }
  }

  Future<void> cancelarPedido(int id) async {
    try {
      await _apiClient.put(ApiConstants.cancelarPedido(id));
    } catch (e) {
      throw Exception('Error al cancelar pedido: ${e.toString()}');
    }
  }

  // ========== COCINA - PEDIDOS ==========
  Future<List<Pedido>> getPedidosPendientes() async {
    try {
      final response = await _apiClient.get(ApiConstants.pedidosPendientes);
      return (response.data as List)
          .map((e) => Pedido.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos pendientes: ${e.toString()}');
    }
  }

  Future<List<Pedido>> getPedidosEnPreparacion() async {
    try {
      final response = await _apiClient.get(ApiConstants.pedidosEnPreparacion);
      return (response.data as List)
          .map((e) => Pedido.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos en preparación: ${e.toString()}');
    }
  }

  Future<Pedido> tomarPedido(int id) async {
    try {
      final response = await _apiClient.put(ApiConstants.tomarPedido(id));
      return Pedido.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al tomar pedido: ${e.toString()}');
    }
  }

  Future<Pedido> marcarListo(int id) async {
    try {
      final response = await _apiClient.put(ApiConstants.marcarListo(id));
      return Pedido.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al marcar pedido como listo: ${e.toString()}');
    }
  }
}