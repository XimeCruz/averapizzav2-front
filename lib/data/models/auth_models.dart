class LoginRequest {
  final String correo;
  final String password;

  LoginRequest({
    required this.correo,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'password': password,
  };
}

class RegisterRequest {
  final String nombre;
  final String password;
  final String correo;

  RegisterRequest({
    required this.nombre,
    required this.password,
    required this.correo,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'password': password,
    'correo': correo,
  };
}

class AuthResponse {
  final String token;
  final String nombreUsuario;
  final String correo;
  final int? usuarioId;
  final String rol;

  AuthResponse({
    required this.token,
    required this.nombreUsuario,
    required this.correo,
    this.usuarioId,
    required this.rol,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      nombreUsuario: json['nombreUsuario'] ?? '',
      correo: json['correo'] ?? '',
      usuarioId: json['usuarioId'],
      rol: json['rol'] ?? 'CLIENTE',
    );
  }
}

class Usuario {
  final int id;
  final String nombreUsuario;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombreUsuario: json['nombreUsuario'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombreUsuario': nombreUsuario,
    'email': email,
    'rol': rol,
  };
}