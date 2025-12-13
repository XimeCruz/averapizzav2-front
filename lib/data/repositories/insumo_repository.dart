// lib/data/repositories/insumo_repository.dart

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/insumo_model.dart';

class InsumoRepository {
  final ApiClient _apiClient = ApiClient();

  // ========== INSUMOS ==========
  Future<List<Insumo>> getInsumos() async {
    try {
      final response = await _apiClient.get(ApiConstants.insumos);
      return (response.data as List)
          .map((e) => Insumo.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener insumos: ${e.toString()}');
    }
  }

  Future<Insumo> getInsumoById(int id) async {
    try {
      final response = await _apiClient.get(ApiConstants.insumoById(id));
      return Insumo.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener insumo: ${e.toString()}');
    }
  }

  Future<Insumo> createInsumo(CreateInsumoRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.insumos,
        data: request.toJson(),
      );
      return Insumo.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear insumo: ${e.toString()}');
    }
  }

  Future<Insumo> updateInsumo(int id, UpdateInsumoRequest request) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.insumoById(id),
        data: request.toJson(),
      );
      return Insumo.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar insumo: ${e.toString()}');
    }
  }

  Future<void> deleteInsumo(int id) async {
    try {
      await _apiClient.delete(ApiConstants.insumoById(id));
    } catch (e) {
      throw Exception('Error al eliminar insumo: ${e.toString()}');
    }
  }

  Future<List<Insumo>> getInsumosBajoStock() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/insumos/bajo-stock',
      );
      return (response.data as List)
          .map((e) => Insumo.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener insumos bajo stock: ${e.toString()}');
    }
  }

  // ========== INVENTARIO ==========
  Future<void> ajustarStock(AjustarStockRequest request) async {
    try {
      await _apiClient.post(
        ApiConstants.ajustarStock,
        data: request.toJson(),
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
    } catch (e) {
      throw Exception('Error al ajustar stock: ${e.toString()}');
    }
  }

  Future<bool> verificarStock(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verificarStock,
        data: items,
      );
      return response.data['disponible'] ?? false;
    } catch (e) {
      throw Exception('Error al verificar stock: ${e.toString()}');
    }
  }

  Future<List<MovimientoInventario>> getMovimientos() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/inventario/movimientos',
      );
      return (response.data as List)
          .map((e) => MovimientoInventario.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos: ${e.toString()}');
    }
  }

  Future<List<MovimientoInventario>> getMovimientosByInsumo(int insumoId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/inventario/movimientos/insumo/$insumoId',
      );
      return (response.data as List)
          .map((e) => MovimientoInventario.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos del insumo: ${e.toString()}');
    }
  }
}