class Venta {
  final int id;
  final DateTime fecha;
  final double total;
  final int pedidoId;
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    required this.fecha,
    required this.total,
    required this.pedidoId,
    this.detalles = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] ?? 0,
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      total: (json['total'] ?? 0).toDouble(),
      pedidoId: json['pedidoId'] ?? json['pedido']?['id'] ?? 0,
      detalles: (json['detalles'] as List?)
          ?.map((e) => DetalleVenta.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'total': total,
    'pedidoId': pedidoId,
    'detalles': detalles.map((e) => e.toJson()).toList(),
  };
}

class DetalleVenta {
  final int? id;
  final int ventaId;
  final int productoId;
  final String? productoNombre;
  final int cantidad;
  final double subtotal;

  DetalleVenta({
    this.id,
    required this.ventaId,
    required this.productoId,
    this.productoNombre,
    required this.cantidad,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: json['id'],
      ventaId: json['ventaId'] ?? json['venta']?['id'] ?? 0,
      productoId: json['productoId'] ?? json['producto']?['id'] ?? 0,
      productoNombre: json['producto']?['nombre'],
      cantidad: json['cantidad'] ?? 1,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'ventaId': ventaId,
    'productoId': productoId,
    'cantidad': cantidad,
    'subtotal': subtotal,
  };
}