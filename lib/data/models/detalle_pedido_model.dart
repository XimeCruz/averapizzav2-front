class DetallePedido {
  final int? id;
  final int? pedidoId;
  final int productoId;
  final int cantidad;
  final double subtotal;
  final double precioUnitario;
  final int presentacionId;
  final int sabor1Id;
  final int? sabor2Id;
  final int? sabor3Id;
  final double? pesoKg;

  final String? productoNombre;
  final String? presentacionNombre;
  final String? sabor1Nombre;
  final String? sabor2Nombre;
  final String? sabor3Nombre;

  DetallePedido({
    this.id,
    this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.subtotal,
    required this.precioUnitario,
    required this.presentacionId,
    required this.sabor1Id,
    this.sabor2Id,
    this.sabor3Id,
    this.pesoKg,
    this.productoNombre,
    this.presentacionNombre,
    this.sabor1Nombre,
    this.sabor2Nombre,
    this.sabor3Nombre,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'],
      pedidoId: json['pedidoId'],
      productoId: json['productoId'] ?? json['producto']?['id'] ?? 0,
      cantidad: json['cantidad'] ?? 1,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      precioUnitario: (json['precioUnitario'] ?? 0).toDouble(),
      presentacionId: json['presentacionId'] ?? 0,
      sabor1Id: json['sabor1Id'] ?? 0,
      sabor2Id: json['sabor2Id'],
      sabor3Id: json['sabor3Id'],
      pesoKg: json['pesoKg'] != null ? (json['pesoKg'] as num).toDouble() : null,

      productoNombre: json['productoNombre'] ?? json['producto']?['nombre'],
      presentacionNombre: json['presentacionNombre'] ?? json['presentacion'],
      sabor1Nombre: json['sabor1'],
      sabor2Nombre: json['sabor2'],
      sabor3Nombre: json['sabor3'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'productoId': productoId,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'precioUnitario': precioUnitario,
      'presentacion': presentacionNombre,
      'sabor1Id': sabor1Id,
    };

    if (id != null) map['id'] = id!;
    if (pedidoId != null) map['pedidoId'] = pedidoId!;
    if (sabor2Id != null) map['sabor2Id'] = sabor2Id!;
    if (sabor3Id != null) map['sabor3Id'] = sabor3Id!;
    if (pesoKg != null) map['pesoKg'] = pesoKg!;

    return map;
  }

  String getSaboresText() {
    final sabores = <String>[];
    if (sabor1Nombre != null && sabor1Nombre!.isNotEmpty) {
      sabores.add(sabor1Nombre!);
    }
    if (sabor2Nombre != null && sabor2Nombre!.isNotEmpty) {
      sabores.add(sabor2Nombre!);
    }
    if (sabor3Nombre != null && sabor3Nombre!.isNotEmpty) {
      sabores.add(sabor3Nombre!);
    }
    return sabores.join(' + ');
  }

}