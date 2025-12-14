// lib/data/models/venta_por_tipo.dart

class VentaPorTipo {
  final String tipoServicio;  // MESA, LLEVAR, DELIVERY
  final int cantidad;
  final double monto;

  VentaPorTipo({
    required this.tipoServicio,
    required this.cantidad,
    required this.monto,
  });

  factory VentaPorTipo.fromJson(Map<String, dynamic> json) {
    return VentaPorTipo(
      tipoServicio: json['tipoServicio'] ?? '',
      cantidad: json['cantidadVentas'] ?? 0,
      monto: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoServicio': tipoServicio,
      'cantidadVentas': cantidad,
      'totalGenerado': monto,
    };
  }
}