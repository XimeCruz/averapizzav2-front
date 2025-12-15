
import '../../core/constants/api_constants.dart';
import 'detalle_pedido_model.dart';

class Pedido {
  final int? id;
  final int usuarioId;
  final String? usuarioNombre;
  final EstadoPedido estado;
  final TipoServicio tipoServicio;
  final MetodoPago metodoPago;
  final DateTime fechaHora;
  final double total;
  final List<DetallePedido> detalles;

  Pedido({
    this.id,
    required this.usuarioId,
    this.usuarioNombre,
    required this.estado,
    required this.tipoServicio,
    required this.fechaHora,
    required this.total,
    this.detalles = const [],
    required this.metodoPago,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['pedidoId'],
      usuarioId: json['idUsuario'] ?? 0,
      usuarioNombre: json['nombreUsuario'],
      estado: _parseEstado(json['estado']),
      tipoServicio: _parseTipoServicio(json['tipoServicio']),
      fechaHora: DateTime.parse(json['fechaHora'] ?? DateTime.now().toIso8601String()),
      metodoPago: _parseMetodoPago(json['metodoPago']),
      total: (json['total'] ?? 0).toDouble(),
      detalles: (json['items'] as List?)
          ?.map((e) => DetallePedido.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'usuarioId': usuarioId,
    'estado': estado.name,
    'tipoServicio': tipoServicio.name,
    'metodoPago': metodoPago.name,
    'fechaHora': fechaHora.toIso8601String(),
    'total': total,
    'detalles': detalles.map((e) => e.toJson()).toList(),
  };

  static EstadoPedido _parseEstado(dynamic value) {
    if (value == null) return EstadoPedido.PENDIENTE;
    final str = value.toString().toUpperCase();
    return EstadoPedido.values.firstWhere(
          (e) => e.name == str,
      orElse: () => EstadoPedido.PENDIENTE,
    );
  }

  static TipoServicio _parseTipoServicio(dynamic value) {
    if (value == null) return TipoServicio.MESA;
    final str = value.toString().toUpperCase();
    return TipoServicio.values.firstWhere(
          (e) => e.name == str,
      orElse: () => TipoServicio.MESA,
    );
  }

  static MetodoPago _parseMetodoPago(dynamic value) {
    if (value == null) return MetodoPago.EFECTIVO;
    final str = value.toString().toUpperCase();
    return MetodoPago.values.firstWhere(
          (e) => e.name == str,
      orElse: () => MetodoPago.EFECTIVO,
    );
  }

  String getEstadoTexto() {
    switch (estado) {
      case EstadoPedido.PENDIENTE:
        return 'Pendiente';
      case EstadoPedido.EN_PREPARACION:
        return 'En Preparación';
      case EstadoPedido.LISTO:
        return 'Listo';
      case EstadoPedido.ENTREGADO:
        return 'Entregado';
      case EstadoPedido.CANCELADO:
        return 'Cancelado';
    }
  }

  String getTipoServicioTexto() {
    switch (tipoServicio) {
      case TipoServicio.MESA:
        return 'En Mesa';
      case TipoServicio.LLEVAR:
        return 'Para Llevar';
      case TipoServicio.DELIVERY:
        return 'Delivery';
    }
  }
}

// Request para crear pedido
class CreatePedidoRequest {
  final int usuarioId;
  final TipoServicio tipoServicio;
  final List<PizzaPedidoItem> pizzas;
  final String metodoPago;
  final List<DetallePedidoRequest> detalles;

  CreatePedidoRequest({
    required this.usuarioId,
    required this.tipoServicio,
    required this.pizzas, required this.metodoPago, required this.detalles,
  });

  Map<String, dynamic> toJson() => {
    'usuarioId': usuarioId,
    'tipoServicio': tipoServicio.name,
    'pizzas': pizzas.map((e) => e.toJson()).toList(),
    'metodoPago': metodoPago,
    'detalles': detalles.map((e) => e.toJson()).toList(),
  };
}

class DetallePedidoRequest {
  final int productoId;
  final int presentacionId;
  final int saborId;
  final int cantidad;

  DetallePedidoRequest({
    required this.productoId,
    required this.presentacionId,
    required this.saborId,
    required this.cantidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'presentacionId': presentacionId,
      'saborId': saborId,
      'cantidad': cantidad,
    };
  }
}

class PizzaPedidoItem {
  final int presentacionId;
  final int sabor1Id;
  final int sabor2Id;
  final int sabor3Id;
  final double? pesoKg;
  final int cantidad;

  PizzaPedidoItem({
    required this.presentacionId,
    required this.sabor1Id,
    this.sabor2Id = 0,
    this.sabor3Id = 0,
    this.pesoKg,
    required this.cantidad,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'presentacionId': presentacionId,
      'sabor1Id': sabor1Id,
      'sabor2Id': sabor2Id,
      'sabor3Id': sabor3Id,
      'cantidad': cantidad,
      'pesoKg': pesoKg ?? 0.0,
    };

    return map;
  }
}