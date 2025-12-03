// lib/data/models/receta/receta_model.dart

class Receta {
  final int id;
  final int saborId;
  final String? saborNombre;
  final bool activo;
  final List<RecetaDetalle> detalles;

  Receta({
    required this.id,
    required this.saborId,
    this.saborNombre,
    this.activo = true,
    this.detalles = const [],
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] ?? 0,
      saborId: json['saborId'] ?? json['sabor']?['id'] ?? 0,
      saborNombre: json['sabor']?['nombre'],
      activo: json['activo'] ?? true,
      detalles: (json['detalles'] as List?)
          ?.map((e) => RecetaDetalle.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'saborId': saborId,
    'activo': activo,
    'detalles': detalles.map((e) => e.toJson()).toList(),
  };
}

class RecetaDetalle {
  final int? id;
  final int insumoId;
  final String? insumoNombre;
  final String? unidadMedida;
  final double cantidad;
  final int? recetaId;

  RecetaDetalle({
    this.id,
    required this.insumoId,
    this.insumoNombre,
    this.unidadMedida,
    required this.cantidad,
    this.recetaId,
  });

  factory RecetaDetalle.fromJson(Map<String, dynamic> json) {
    return RecetaDetalle(
      id: json['id'],
      insumoId: json['insumoId'] ?? json['insumo']?['id'] ?? 0,
      insumoNombre: json['insumo']?['nombre'],
      unidadMedida: json['insumo']?['unidadMedida'],
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      recetaId: json['recetaId'] ?? json['receta']?['id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'insumoId': insumoId,
    'cantidad': cantidad,
  };

  String getDescripcion() {
    return '$cantidad ${unidadMedida ?? ''} de ${insumoNombre ?? 'Insumo #$insumoId'}';
  }
}

class CreateRecetaRequest {
  final List<RecetaInsumoItem> insumos;

  CreateRecetaRequest({
    required this.insumos,
  });

  Map<String, dynamic> toJson() => {
    'insumos': insumos.map((e) => e.toJson()).toList(),
  };

  // Para enviar como lista directa (según el flujo)
  List<Map<String, dynamic>> toJsonList() {
    return insumos.map((e) => e.toJson()).toList();
  }
}

class RecetaInsumoItem {
  final int insumoId;
  final double cantidad;

  RecetaInsumoItem({
    required this.insumoId,
    required this.cantidad,
  });

  Map<String, dynamic> toJson() => {
    'insumoId': insumoId,
    'cantidad': cantidad,
  };
}

class UpdateRecetaRequest {
  final List<RecetaInsumoItem> insumos;

  UpdateRecetaRequest({
    required this.insumos,
  });

  List<Map<String, dynamic>> toJsonList() {
    return insumos.map((e) => e.toJson()).toList();
  }
}