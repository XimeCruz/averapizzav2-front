import 'package:avp_frontend/core/constants/api_constants.dart';
import 'package:avp_frontend/data/models/pedido_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Modelo de item del carrito
class ItemCarrito {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final String categoria;
  final String? observaciones;

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
    required this.cantidad,
    required this.categoria,
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

  /// Subtotal del item (precio * cantidad)
  double get subtotal => precio * cantidad;

  bool get esPizza => categoria == 'Pizza';
  bool get esBebida => categoria == 'Bebida';
  bool get esPizzaPeso => esPizza && pesoKg != null && pesoKg! > 0;

  /// Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
      'observaciones': observaciones,
      'subtotal': subtotal,
    };
  }

  /// Crear desde JSON
  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      categoria: json['categoria'] as String,
      observaciones: json['observaciones'] as String?,
    );
  }

  /// Copiar con modificaciones
  ItemCarrito copyWith({
    int? productoId,
    String? nombre,
    double? precio,
    int? cantidad,
    String? categoria,
    String? observaciones,
  }) {
    return ItemCarrito(
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  String toString() {
    return 'ItemCarrito(productoId: $productoId, nombre: $nombre, precio: $precio, cantidad: $cantidad, categoria: $categoria, observaciones: $observaciones)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ItemCarrito &&
        other.productoId == productoId &&
        other.nombre == nombre &&
        other.precio == precio &&
        other.cantidad == cantidad &&
        other.categoria == categoria &&
        other.observaciones == observaciones;
  }

  @override
  int get hashCode {
    return productoId.hashCode ^
    nombre.hashCode ^
    precio.hashCode ^
    cantidad.hashCode ^
    categoria.hashCode ^
    (observaciones?.hashCode ?? 0);
  }
}



extension TipoEntregaExtension on TipoServicio {
  String get texto {
    switch (this) {
      case TipoServicio.MESA:
        return 'Consumir en el local';
      case TipoServicio.DELIVERY:
        return 'Delivery';
      case TipoServicio.LLEVAR:
        return 'Recoger en Local';
    }
  }

  IconData get icono {
    switch (this) {
      case TipoServicio.MESA:
        return Icons.store;
      case TipoServicio.DELIVERY:
        return Icons.delivery_dining;
      case TipoServicio.LLEVAR:
        return Icons.delivery_dining;
    }
  }
  //
  // String getSaboresTexto() {
  //   final sabores = <String>[];
  //   if (sabor1Nombre != null && sabor1Nombre!.isNotEmpty) {
  //     sabores.add(sabor1Nombre!);
  //   }
  //   if (sabor2Nombre != null && sabor2Nombre!.isNotEmpty) {
  //     sabores.add(sabor2Nombre!);
  //   }
  //   if (sabor3Nombre != null && sabor3Nombre!.isNotEmpty) {
  //     sabores.add(sabor3Nombre!);
  //   }
  //   return sabores.join(' + ');
  // }
  //
  // ItemCarrito copyWith({
  //   int? cantidad,
  // }) {
  //   return ItemCarrito(
  //     productoId: productoId,
  //     nombre: nombre,
  //     precio: precio,
  //     categoria: categoria,
  //     cantidad: cantidad ?? this.cantidad,
  //     observaciones: observaciones,
  //     presentacionId: presentacionId,
  //     presentacionNombre: presentacionNombre,
  //     sabor1Id: sabor1Id,
  //     sabor1Nombre: sabor1Nombre,
  //     sabor2Id: sabor2Id,
  //     sabor2Nombre: sabor2Nombre,
  //     sabor3Id: sabor3Id,
  //     sabor3Nombre: sabor3Nombre,
  //     pesoKg: pesoKg,
  //   );
  // }
  //
  // // Convertir a DetallePedidoRequest para enviar al backend
  // DetallePedidoRequest? toDetallePedidoRequest() {
  //   if (esBebida) {
  //     return DetallePedidoRequest(
  //       productoId: productoId,
  //       presentacionId: presentacionId!,
  //       saborId: sabor1Id ?? 0,
  //       cantidad: cantidad,
  //     );
  //   }
  //   return null; // Las pizzas se manejan con PizzaPedidoItem
  // }
  //
  // // Convertir a PizzaPedidoItem para enviar al backend
  // PizzaPedidoItem? toPizzaPedidoItem() {
  //   if (esPizza) {
  //     return PizzaPedidoItem(
  //       presentacionId: presentacionId!,
  //       sabor1Id: sabor1Id!,
  //       sabor2Id: sabor2Id ?? 0,
  //       sabor3Id: sabor3Id ?? 0,
  //       pesoKg: pesoKg,
  //       cantidad: cantidad,
  //     );
  //   }
  //   return null;
  // }
}