// lib/data/models/venta_reporte.dart

class VentaReporte {
  final int id;
  final DateTime fecha;
  final double total;

  VentaReporte({
    required this.id,
    required this.fecha,
    required this.total,
  });

  factory VentaReporte.fromJson(Map<String, dynamic> json) {
    return VentaReporte(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'total': total,
    };
  }
}