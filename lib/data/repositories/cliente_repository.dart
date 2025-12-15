// lib/data/repositories/cliente_repository.dart

import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/cliente_estadisticas_model.dart';

class ClienteRepository {

  final ApiClient _apiClient = ApiClient();


  Future<ClienteEstadisticasModel> getEstadisticas(String idCliente) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.clientesEstadisticas(idCliente),
      );

      if (response.statusCode == 200) {
        return ClienteEstadisticasModel.fromJson(response.data);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error del servidor: ${e.response?.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}