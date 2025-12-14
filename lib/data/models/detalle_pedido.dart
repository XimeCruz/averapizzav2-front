// lib/data/models/detalle_pedido_model.dart

class DetallePedido {
  final int id;
  final String nombre;
  final int cantidad;
  final double precio;

  DetallePedido({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      precio: (json['precio'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
      'precio': precio,
    };
  }
}