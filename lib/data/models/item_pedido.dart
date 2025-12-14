
// Modelo de Item de Pedido
class ItemPedido {
  final int id;
  final int presentacionId;
  final String uniqueId;
  final String nombre;
  final double precio;
  int cantidad;
  final String categoria;
  final String presentacion;
  final String tipoProducto;

  int? saborId;
  List<int>? saboresIds; // Para pizzas con múltiples sabores
  double? pesoKg; // Para pizzas por peso

  ItemPedido({
    required this.id,
    required this.presentacionId,
    required this.uniqueId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    required this.presentacion,
    required this.tipoProducto,
    this.saborId,
    this.saboresIds,
    this.pesoKg,
  });

  // Para convertir a DetallePedidoRequest (bebidas)
  Map<String, dynamic> toDetalleJson() {
    return {
      'productoId': id,
      'presentacionId': presentacionId,
      'saborId': saborId ?? 0,
      'cantidad': cantidad,
    };
  }

  // Para convertir a PizzaPedidoRequest
  Map<String, dynamic> toPizzaJson() {
    return {
      'presentacionId': presentacionId,
      'sabor1Id': saboresIds != null && saboresIds!.isNotEmpty
          ? saboresIds![0]
          : (saborId ?? id),
      'sabor2Id': saboresIds != null && saboresIds!.length > 1
          ? saboresIds![1]
          : 0,
      'sabor3Id': saboresIds != null && saboresIds!.length > 2
          ? saboresIds![2]
          : 0,
      'pesoKg': pesoKg ?? 0,
      'cantidad': cantidad,
    };
  }

  bool get esPizza => tipoProducto == 'PIZZA';
  bool get esBebida => tipoProducto == 'BEBIDA';
}