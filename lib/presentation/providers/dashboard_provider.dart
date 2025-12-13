// lib/presentation/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardData {
  final int totalVentas;
  final double tasaEntrega;
  final int totalProductos;
  final int insumosBajoStock;

  final double montoTotal;
  final int pedidosPendientes;
  final int pedidosEnPreparacion;
  final int pedidosEntregados;

  final List<ProductoMasVendido> productosMasVendidos;

  DashboardData({
    required this.totalVentas,
    required this.montoTotal,
    required this.pedidosPendientes,
    required this.pedidosEnPreparacion,
    required this.insumosBajoStock,
    this.productosMasVendidos = const [],
    required this.tasaEntrega,
    required this.totalProductos,
    required this.pedidosEntregados,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalVentas: json['totalPedidos'] ?? 0,
      tasaEntrega: (json['tasaEntrega'] ?? 0).toDouble(),
      totalProductos: json['totalProductos'],
      insumosBajoStock: json['alertasStock'] ?? 0,

      montoTotal: (json['metricasDia']?['totalVentas'] ?? 0).toDouble(),
      pedidosPendientes: json['metricasDia']?['pedidosPendientes'] ?? 0,
      pedidosEnPreparacion:  json['metricasDia']?['pedidosEnPreparacion'] ?? 0,
      pedidosEntregados: json['metricasDia']?['pedidosEntregados'] ?? 0,

      productosMasVendidos: (json['productosMasVendidos'] as List?)
          ?.map((e) => ProductoMasVendido.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ProductoMasVendido {
  final String nombre;
  final int cantidad;
  final double total;

  ProductoMasVendido({
    required this.nombre,
    required this.cantidad,
    required this.total,
  });

  factory ProductoMasVendido.fromJson(Map<String, dynamic> json) {
    return ProductoMasVendido(
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  DashboardStatus _status = DashboardStatus.initial;
  DashboardData? _dashboardData;
  String? _errorMessage;

  DashboardStatus get status => _status;
  DashboardData? get dashboardData => _dashboardData;
  String? get errorMessage => _errorMessage;

  // ========== CARGAR DASHBOARD ==========
  Future<void> loadDashboard() async {
    try {
      _status = DashboardStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiClient.get(ApiConstants.dashboard);
      _dashboardData = DashboardData.fromJson(response.data);

      _status = DashboardStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ========== REPORTE DIARIO ==========
  Future<Map<String, dynamic>?> getReporteDiario() async {
    try {
      _errorMessage = null;
      final response = await _apiClient.get(ApiConstants.reporteDiario);
      return response.data;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}