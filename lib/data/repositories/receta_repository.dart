// lib/data/repositories/receta_repository.dart

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/receta_model.dart';

class RecetaRepository {
  final ApiClient _apiClient = ApiClient();

  // ========== RECETAS ==========
  Future<List<Receta>> getRecetas() async {
    try {
      final response = await _apiClient.get(ApiConstants.recetas);
      return (response.data as List)
          .map((e) => Receta.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recetas: ${e.toString()}');
    }
  }

  Future<Receta> getRecetaBySabor(int saborId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.recetaByProducto(saborId),
      );
      return Receta.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener receta: ${e.toString()}');
    }
  }

  Future<Receta> createReceta(int saborId, CreateRecetaRequest request) async {
    try {
      // Según el flujo, se envía directamente la lista de insumos
      final response = await _apiClient.post(
        '${ApiConstants.apiVersion}/admin/recetas/$saborId',
        data: request.toJsonList(),
      );
      return Receta.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear receta: ${e.toString()}');
    }
  }

  Future<Receta> updateReceta(int saborId, UpdateRecetaRequest request) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.apiVersion}/admin/recetas/$saborId',
        data: request.toJsonList(),
      );
      return Receta.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar receta: ${e.toString()}');
    }
  }

  Future<void> deleteReceta(int saborId) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.apiVersion}/admin/recetas/$saborId',
      );
    } catch (e) {
      throw Exception('Error al eliminar receta: ${e.toString()}');
    }
  }

  // ========== DETALLES DE RECETA ==========
  Future<List<RecetaDetalle>> getDetallesBySabor(int saborId) async {
    try {
      final receta = await getRecetaBySabor(saborId);
      return receta.detalles;
    } catch (e) {
      throw Exception('Error al obtener detalles de receta: ${e.toString()}');
    }
  }
}