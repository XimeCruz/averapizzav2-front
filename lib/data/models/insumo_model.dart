class Insumo {
  final int id;
  final String nombre;
  final String unidadMedida;
  final double stockActual;
  final double stockMinimo;
  final bool activo;

  Insumo({
    required this.id,
    required this.nombre,
    required this.unidadMedida,
    required this.stockActual,
    required this.stockMinimo,
    this.activo = true,
  });

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      unidadMedida: json['unidadMedida'] ?? '',
      stockActual: (json['stockActual'] ?? 0).toDouble(),
      stockMinimo: (json['stockMinimo'] ?? 0).toDouble(),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'unidadMedida': unidadMedida,
    'stockActual': stockActual,
    'stockMinimo': stockMinimo,
    'activo': activo,
  };

  bool get esBajoStock => stockActual <= stockMinimo;

  double get porcentajeStock {
    if (stockMinimo == 0) return 100;
    return (stockActual / stockMinimo) * 100;
  }
}

class CreateInsumoRequest {
  final String nombre;
  final String unidadMedida;
  final double stockMinimo;
  final double stockActual;

  CreateInsumoRequest({
    required this.nombre,
    required this.unidadMedida,
    required this.stockMinimo,
    required this.stockActual,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'unidadMedida': unidadMedida,
    'stockMinimo': stockMinimo,
    'stockActual': stockActual,
  };
}

class UpdateInsumoRequest {
  final String? nombre;
  final String? unidadMedida;
  final double? stockMinimo;
  final double? stockActual;
  final bool? activo;

  UpdateInsumoRequest({
    this.nombre,
    this.unidadMedida,
    this.stockMinimo,
    this.stockActual,
    this.activo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (nombre != null) map['nombre'] = nombre;
    if (unidadMedida != null) map['unidadMedida'] = unidadMedida;
    if (stockMinimo != null) map['stockMinimo'] = stockMinimo;
    if (stockActual != null) map['stockActual'] = stockActual;
    if (activo != null) map['activo'] = activo;
    return map;
  }
}

// MovimientoInventario
enum TipoMovimiento {
  ENTRADA,
  SALIDA,
  AJUSTE
}

class MovimientoInventario {
  final int id;
  final TipoMovimiento tipoMovimiento;
  final double cantidad;
  final DateTime fechaHora;
  final String? referencia;
  final int insumoId;
  final String? insumoNombre;
  final int usuarioId;
  final String? usuarioNombre;

  MovimientoInventario({
    required this.id,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.fechaHora,
    this.referencia,
    required this.insumoId,
    this.insumoNombre,
    required this.usuarioId,
    this.usuarioNombre,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      id: json['id'] ?? 0,
      tipoMovimiento: _parseTipoMovimiento(json['tipoMovimiento']),
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      fechaHora: DateTime.parse(json['fechaHora'] ?? DateTime.now().toIso8601String()),
      referencia: json['referencia'],
      insumoId: json['insumoId'] ?? json['insumo']?['id'] ?? 0,
      insumoNombre: json['insumo']?['nombre'],
      usuarioId: json['usuarioId'] ?? 0,
      usuarioNombre: json['usuarioNombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipoMovimiento': tipoMovimiento.name,
    'cantidad': cantidad,
    'referencia': referencia,
    'insumoId': insumoId,
    'usuarioId': usuarioId,
  };

  static TipoMovimiento _parseTipoMovimiento(dynamic value) {
    if (value == null) return TipoMovimiento.AJUSTE;
    final str = value.toString().toUpperCase();
    return TipoMovimiento.values.firstWhere(
          (e) => e.name == str,
      orElse: () => TipoMovimiento.AJUSTE,
    );
  }

  String getTipoTexto() {
    switch (tipoMovimiento) {
      case TipoMovimiento.ENTRADA:
        return 'Entrada';
      case TipoMovimiento.SALIDA:
        return 'Salida';
      case TipoMovimiento.AJUSTE:
        return 'Ajuste';
    }
  }
}

class AjustarStockRequest {
  final int insumoId;
  final double cantidad;
  final String tipoMovimiento;
  final String referencia;
  final int usuarioId;

  AjustarStockRequest({
    required this.insumoId,
    required this.cantidad,
    required this.tipoMovimiento,
    required this.referencia,
    required this.usuarioId,
  });

  Map<String, dynamic> toJson() => {
    'insumoId': insumoId,
    'cantidad': cantidad,
    'referencia': referencia,
    'tipoMov': tipoMovimiento,
    'usuarioId': usuarioId,
  };
}