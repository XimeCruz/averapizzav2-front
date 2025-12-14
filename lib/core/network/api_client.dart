import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(ApiInterceptor());

    // Log interceptor (solo en desarrollo)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  // GET
  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST
  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT
  Future<Response> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE
  Future<Response> delete(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        // Intentar extraer el mensaje del backend
        String message = 'Error desconocido';

        if (responseData != null) {
          // Si es un Map, buscar los diferentes campos de mensaje
          if (responseData is Map<String, dynamic>) {
            // Buscar en orden: mensaje (español), message (inglés), error
            message = responseData['mensaje']?.toString() ??
                responseData['message']?.toString() ??
                responseData['error']?.toString() ??
                'Error desconocido';

            // Si el backend envía un error estructurado (como STOCK_INSUFICIENTE)
            // lanzar la excepción con el JSON completo para que el repositorio lo maneje
            if (responseData.containsKey('tipo') && statusCode == 400) {
              return Exception(jsonEncode(responseData));
            }
          }
          // Si es String, usarlo directamente
          else if (responseData is String) {
            message = responseData;
          }
        }

        switch (statusCode) {
          case 400:
            return Exception('Solicitud incorrecta: $message');
          case 401:
            SecureStorage.clearAll();
            return Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
          case 403:
            return Exception('No tienes permisos para realizar esta acción.');
          case 404:
            return Exception('Recurso no encontrado.');
          case 500:
            return Exception('Error del servidor. Intenta más tarde.');
          default:
            return Exception(message);
        }

      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada.');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return Exception('No hay conexión a internet.');
        }
        return Exception('Error desconocido. Por favor, intenta nuevamente.');

      default:
        return Exception('Error de conexión.');
    }
  }
}