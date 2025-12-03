// lib/data/models/usuario/usuario_model.dart

enum RolNombre {
  ADMIN,
  CAJERO,
  CLIENTE
}

class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final bool activo;
  final List<Rol> roles;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.activo = true,
    this.roles = const [],
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      activo: json['activo'] ?? true,
      roles: (json['roles'] as List?)
          ?.map((e) => Rol.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'activo': activo,
    'roles': roles.map((e) => e.toJson()).toList(),
  };

  String getRolPrincipal() {
    if (roles.isEmpty) return 'CLIENTE';
    return roles.first.nombre.name;
  }

  bool tieneRol(RolNombre rol) {
    return roles.any((r) => r.nombre == rol);
  }
}

class Rol {
  final int id;
  final RolNombre nombre;

  Rol({
    required this.id,
    required this.nombre,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id'] ?? 0,
      nombre: _parseRolNombre(json['nombre']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre.name,
  };

  static RolNombre _parseRolNombre(dynamic value) {
    if (value == null) return RolNombre.CLIENTE;
    final str = value.toString().toUpperCase();
    return RolNombre.values.firstWhere(
          (e) => e.name == str,
      orElse: () => RolNombre.CLIENTE,
    );
  }

  String getTexto() {
    switch (nombre) {
      case RolNombre.ADMIN:
        return 'Administrador';
      case RolNombre.CAJERO:
        return 'Cajero';
      case RolNombre.CLIENTE:
        return 'Cliente';
    }
  }
}