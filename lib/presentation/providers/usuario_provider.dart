
// ========================================================================
// lib/presentation/providers/usuario_provider.dart

import 'package:flutter/material.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/models/usuario_model.dart';

enum UsuarioStatus { initial, loading, loaded, error }

class UsuarioProvider extends ChangeNotifier {
  final UsuarioRepository _repository = UsuarioRepository();

  UsuarioStatus _status = UsuarioStatus.initial;
  List<Usuario> _clientes = [];
  List<Usuario> _empleados = [];
  Usuario? _usuarioSeleccionado;
  String? _errorMessage;

  UsuarioStatus get status => _status;
  List<Usuario> get clientes => _clientes;
  List<Usuario> get empleados => _empleados;
  Usuario? get usuarioSeleccionado => _usuarioSeleccionado;
  String? get errorMessage => _errorMessage;

  // ========== CARGAR CLIENTES ==========
  Future<void> loadClientes() async {
    try {
      _status = UsuarioStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _clientes = await _repository.getClientes();
      // Filtrar solo clientes
      // _clientes = usuarios.where((u) => u.tieneRol(RolNombre.CLIENTE)).toList();

      _status = UsuarioStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = UsuarioStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CARGAR EMPLEADOS ==========
  Future<void> loadEmpleados() async {
    try {
      _status = UsuarioStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final usuarios = await _repository.getClientes();
      // Filtrar solo empleados (admin y cajero)
      _empleados = usuarios.where((u) =>
      u.tieneRol(RolNombre.ADMIN) || u.tieneRol(RolNombre.CAJERO)
      ).toList();

      _status = UsuarioStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = UsuarioStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CARGAR USUARIO POR ID ==========
  Future<void> loadUsuarioById(int id) async {
    try {
      _errorMessage = null;
      _usuarioSeleccionado = await _repository.getUsuarioById(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CREAR USUARIO ==========
  Future<bool> createUsuario(CreateUsuarioRequest request) async {
    try {
      _status = UsuarioStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final newUsuario = await _repository.createUsuario(request);

      // Agregar a la lista correspondiente
      if (newUsuario.tieneRol(RolNombre.CLIENTE)) {
        _clientes.add(newUsuario);
      } else {
        _empleados.add(newUsuario);
      }

      _status = UsuarioStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = UsuarioStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ACTUALIZAR USUARIO ==========
  Future<bool> updateUsuario(int id, UpdateUsuarioRequest request) async {
    try {
      _errorMessage = null;
      final updatedUsuario = await _repository.updateUsuario(id, request);

      // Actualizar en la lista correspondiente
      final indexCliente = _clientes.indexWhere((u) => u.id == id);
      if (indexCliente != -1) {
        _clientes[indexCliente] = updatedUsuario;
      }

      final indexEmpleado = _empleados.indexWhere((u) => u.id == id);
      if (indexEmpleado != -1) {
        _empleados[indexEmpleado] = updatedUsuario;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ELIMINAR USUARIO ==========
  Future<bool> deleteUsuario(int id) async {
    try {
      _errorMessage = null;
      await _repository.deleteUsuario(id);

      _clientes.removeWhere((u) => u.id == id);
      _empleados.removeWhere((u) => u.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== ACTIVAR/DESACTIVAR CLIENTE ==========
  Future<bool> toggleEstadoCliente(int id) async {
    try {
      _errorMessage = null;
      final updatedUsuario = await _repository.toggleEstadoCliente(id);

      final index = _clientes.indexWhere((u) => u.id == id);
      if (index != -1) {
        _clientes[index] = updatedUsuario;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ========== CARGAR POR ROL ==========
  Future<void> loadUsuariosByRol(RolNombre rol) async {
    try {
      _status = UsuarioStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final usuarios = await _repository.getUsuariosByRol(rol);

      if (rol == RolNombre.CLIENTE) {
        _clientes = usuarios;
      } else {
        _empleados = usuarios;
      }

      _status = UsuarioStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = UsuarioStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== CARGAR USUARIOS ACTIVOS ==========
  Future<void> loadUsuariosActivos() async {
    try {
      _errorMessage = null;
      final usuarios = await _repository.getUsuariosActivos();

      _clientes = usuarios.where((u) => u.tieneRol(RolNombre.CLIENTE)).toList();
      _empleados = usuarios.where((u) =>
      u.tieneRol(RolNombre.ADMIN) || u.tieneRol(RolNombre.CAJERO)
      ).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== UTILIDADES ==========
  Usuario? getUsuarioById(int id) {
    try {
      return _clientes.firstWhere((u) => u.id == id);
    } catch (e) {
      try {
        return _empleados.firstWhere((u) => u.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  List<Usuario> getClientesActivosList() {
    return _clientes.where((u) => u.activo).toList();
  }

  List<Usuario> getClientesInactivosList() {
    return _clientes.where((u) => !u.activo).toList();
  }

  int getTotalClientes() => _clientes.length;
  int getCountClientesActivos() => _clientes.where((u) => u.activo).length;
  int getCountClientesInactivos() => _clientes.where((u) => !u.activo).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelection() {
    _usuarioSeleccionado = null;
    notifyListeners();
  }
}