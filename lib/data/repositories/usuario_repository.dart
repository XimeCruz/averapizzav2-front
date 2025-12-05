import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final ApiClient _apiClient = ApiClient();

  // ========== USUARIOS/CLIENTES ==========
  Future<List<Usuario>> getClientes() async {
    try {
      final response = await _apiClient.get('${ApiConstants.apiVersion}/admin/usuarios');
      return (response.data as List)
          .map((e) => Usuario.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: ${e.toString()}');
    }
  }

  Future<Usuario> getUsuarioById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.apiVersion}/admin/usuarios/$id');
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }

  Future<Usuario> createUsuario(CreateUsuarioRequest request) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiVersion}/admin/usuarios',
        data: request.toJson(),
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear usuario: ${e.toString()}');
    }
  }

  Future<Usuario> updateUsuario(int id, UpdateUsuarioRequest request) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.apiVersion}/admin/usuarios/$id',
        data: request.toJson(),
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar usuario: ${e.toString()}');
    }
  }

  Future<void> deleteUsuario(int id) async {
    try {
      await _apiClient.delete('${ApiConstants.apiVersion}/admin/usuarios/$id');
    } catch (e) {
      throw Exception('Error al eliminar usuario: ${e.toString()}');
    }
  }

  Future<Usuario> toggleEstadoCliente(int id) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.apiVersion}/admin/usuarios/$id/toggle-estado',
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cambiar estado del cliente: ${e.toString()}');
    }
  }

  Future<List<Usuario>> getUsuariosByRol(RolNombre rol) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/usuarios/rol/${rol.name}',
      );
      return (response.data as List)
          .map((e) => Usuario.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: ${e.toString()}');
    }
  }

  Future<List<Usuario>> getUsuariosActivos() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiVersion}/admin/usuarios/activos',
      );
      return (response.data as List)
          .map((e) => Usuario.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios activos: ${e.toString()}');
    }
  }
}

// ========== REQUEST MODELS ==========
class CreateUsuarioRequest {
  final String nombre;
  final String correo;
  final String password;
  final List<RolNombre> roles;

  CreateUsuarioRequest({
    required this.nombre,
    required this.correo,
    required this.password,
    required this.roles,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'password': password,
    'roles': roles.map((r) => r.name).toList(),
  };
}

class UpdateUsuarioRequest {
  final String? nombre;
  final String? correo;
  final String? password;
  final List<RolNombre>? roles;
  final bool? activo;

  UpdateUsuarioRequest({
    this.nombre,
    this.correo,
    this.password,
    this.roles,
    this.activo,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (nombre != null) data['nombre'] = nombre;
    if (correo != null) data['correo'] = correo;
    if (password != null) data['password'] = password;
    if (roles != null) data['roles'] = roles!.map((r) => r.name).toList();
    if (activo != null) data['activo'] = activo;
    return data;
  }
}