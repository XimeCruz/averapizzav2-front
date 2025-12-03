import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Guardar token y datos del usuario
      await SecureStorage.saveToken(authResponse.token);
      await SecureStorage.saveUserInfo(
        role: authResponse.rol,
        userId: authResponse.usuarioId ?? 0,
        userName: authResponse.nombreUsuario,
      );

      return authResponse;
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  Future<AuthResponse> register(RegisterRequest request, String role) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register(role),
        data: request.toJson(),
      );

      print('✅ Registro exitoso');

      final authResponse = AuthResponse.fromJson(response.data);

      await SecureStorage.saveToken(authResponse.token);
      await SecureStorage.saveUserInfo(
        role: authResponse.rol,
        userId: authResponse.usuarioId ?? 0,
        userName: authResponse.nombreUsuario,
      );

      return authResponse;
    } catch (e) {
      throw Exception('Error al registrar usuario: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  bool isAuthenticated() {
    return SecureStorage.isAuthenticated();
  }

  String? getUserRole() {
    return SecureStorage.getUserRole();
  }

  String? getUserName() {
    return SecureStorage.getUserName();
  }

  int? getUserId() {
    return SecureStorage.getUserId();
  }
}