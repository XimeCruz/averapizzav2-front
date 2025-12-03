// lib/data/repositories/producto_repository.dart

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/producto_model.dart';

class ProductoRepository {
  final ApiClient _apiClient = ApiClient();

  // ========== PRODUCTOS ==========
  Future<List<Producto>> getProductos() async {
    try {
      final response = await _apiClient.get(ApiConstants.productos);
      return (response.data as List)
          .map((e) => Producto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: ${e.toString()}');
    }
  }

  Future<Producto> getProductoById(int id) async {
    try {
      final response = await _apiClient.get(ApiConstants.productoById(id));
      return Producto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener producto: ${e.toString()}');
    }
  }

  Future<Producto> createProducto(CreateProductoRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.productos,
        data: request.toJson(),
      );
      return Producto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear producto: ${e.toString()}');
    }
  }

  Future<Producto> updateProducto(int id, CreateProductoRequest request) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.productoById(id),
        data: request.toJson(),
      );
      return Producto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar producto: ${e.toString()}');
    }
  }

  Future<void> deleteProducto(int id) async {
    try {
      await _apiClient.delete(ApiConstants.productoById(id));
    } catch (e) {
      throw Exception('Error al eliminar producto: ${e.toString()}');
    }
  }

  // ========== SABORES ==========
  Future<List<SaborPizza>> getSabores() async {
    try {
      final response = await _apiClient.get('${ApiConstants.apiVersion}/admin/sabores');
      return (response.data as List)
          .map((e) => SaborPizza.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener sabores: ${e.toString()}');
    }
  }

  Future<List<SaborPizza>> getSaboresByProducto(int productoId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/sabores/producto/$productoId',
      );
      return (response.data as List)
          .map((e) => SaborPizza.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener sabores del producto: ${e.toString()}');
    }
  }

  Future<SaborPizza> getSaborById(int id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/sabores/$id',
      );
      return SaborPizza.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener sabor: ${e.toString()}');
    }
  }

  Future<SaborPizza> createSabor(CreateSaborRequest request) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiVersion}/admin/sabores',
        data: request.toJson(),
      );
      return SaborPizza.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear sabor: ${e.toString()}');
    }
  }

  Future<SaborPizza> updateSabor(int id, CreateSaborRequest request) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.apiVersion}/admin/sabores/$id',
        data: request.toJson(),
      );
      return SaborPizza.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar sabor: ${e.toString()}');
    }
  }

  Future<void> deleteSabor(int id) async {
    try {
      await _apiClient.delete('${ApiConstants.apiVersion}/admin/sabores/$id');
    } catch (e) {
      throw Exception('Error al eliminar sabor: ${e.toString()}');
    }
  }

  // ========== PRESENTACIONES ==========
  Future<List<PresentacionProducto>> getPresentacionesByProducto(int productoId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/cliente/presentaciones/producto/$productoId',
      );
      return (response.data as List)
          .map((e) => PresentacionProducto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener presentaciones: ${e.toString()}');
    }
  }

  Future<List<PresentacionProducto>> getPresentaciones() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/presentaciones',
      );
      return (response.data as List)
          .map((e) => PresentacionProducto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener presentaciones: ${e.toString()}');
    }
  }

  Future<PresentacionProducto> getPresentacionById(int id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/presentaciones/$id',
      );
      return PresentacionProducto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener presentación: ${e.toString()}');
    }
  }

  Future<PresentacionProducto> createPresentacion(CreatePresentacionRequest request) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiVersion}/admin/presentaciones',
        data: request.toJson(),
      );
      return PresentacionProducto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear presentación: ${e.toString()}');
    }
  }

  // ========== PRECIOS ==========
  Future<List<PrecioSaborPresentacion>> getPreciosBySabor(int saborId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/precios/sabor/$saborId',
      );
      return (response.data as List)
          .map((e) => PrecioSaborPresentacion.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener precios: ${e.toString()}');
    }
  }

  Future<PrecioSaborPresentacion> createPrecio(
      int saborId,
      CreatePrecioRequest request,
      ) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiVersion}/admin/precios/$saborId',
        data: request.toJson(),
      );
      return PrecioSaborPresentacion.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear precio: ${e.toString()}');
    }
  }

  Future<PrecioSaborPresentacion> updatePrecio(
      int precioId,
      CreatePrecioRequest request,
      ) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.apiVersion}/admin/precios/$precioId',
        data: request.toJson(),
      );
      return PrecioSaborPresentacion.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar precio: ${e.toString()}');
    }
  }
}