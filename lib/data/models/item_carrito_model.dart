// lib/data/models/item_carrito_model.dart

import 'pedido_model.dart';

class ItemCarrito {
  final int productoId;
  final String nombre;
  final double precio;
  final String categoria;
  final int cantidad;
  final String? observaciones;

  // Campos para pizzas y bebidas
  final int? presentacionId;
  final String? presentacionNombre;
  final int? sabor1Id;
  final String? sabor1Nombre;
  final int? sabor2Id;
  final String? sabor2Nombre;
  final int? sabor3Id;
  final String? sabor3Nombre;
  final double? pesoKg;

  ItemCarrito({
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.cantidad,
    this.observaciones,
    this.presentacionId,
    this.presentacionNombre,
    this.sabor1Id,
    this.sabor1Nombre,
    this.sabor2Id,
    this.sabor2Nombre,
    this.sabor3Id,
    this.sabor3Nombre,
    this.pesoKg,
  });

  double get subtotal => precio * cantidad;

  bool get esPizza => categoria == 'Pizza';
  bool get esBebida => categoria == 'Bebida';
  bool get esPizzaPeso => esPizza && pesoKg != null && pesoKg! > 0;

  String getSaboresTexto() {
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

  ItemCarrito copyWith({
    int? cantidad,
  }) {
    return ItemCarrito(
      productoId: productoId,
      nombre: nombre,
      precio: precio,
      categoria: categoria,
      cantidad: cantidad ?? this.cantidad,
      observaciones: observaciones,
      presentacionId: presentacionId,
      presentacionNombre: presentacionNombre,
      sabor1Id: sabor1Id,
      sabor1Nombre: sabor1Nombre,
      sabor2Id: sabor2Id,
      sabor2Nombre: sabor2Nombre,
      sabor3Id: sabor3Id,
      sabor3Nombre: sabor3Nombre,
      pesoKg: pesoKg,
    );
  }

  // Convertir a DetallePedidoRequest para enviar al backend (BEBIDAS)
  DetallePedidoRequest? toDetallePedidoRequest() {
    if (esBebida && presentacionId != null && sabor1Id != null) {
      return DetallePedidoRequest(
        productoId: productoId,
        presentacionId: presentacionId!,
        saborId: sabor1Id!,
        cantidad: cantidad,
      );
    }
    return null;
  }

  // Convertir a PizzaPedidoItem para enviar al backend (PIZZAS)
  PizzaPedidoItem? toPizzaPedidoItem() {
    if (esPizza && presentacionId != null && sabor1Id != null) {
      // 🔍 AGREGA ESTE PRINT PARA DEBUG
      print('DEBUG: Convirtiendo ItemCarrito a PizzaPedidoItem');
      print('DEBUG: pesoKg del ItemCarrito: $pesoKg');

      return PizzaPedidoItem(
        presentacionId: presentacionId!,
        sabor1Id: sabor1Id!,
        sabor2Id: sabor2Id ?? 0,
        sabor3Id: sabor3Id ?? 0,
        pesoKg: pesoKg,
        cantidad: cantidad,
      );
    }
    return null;
  }
}