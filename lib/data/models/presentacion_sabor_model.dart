// lib/data/models/producto/presentacion_sabor_model.dart

class PresentacionSabor {
  final int id;
  final int presentacionId;
  final int saborId;
  final int orden;
  final String? presentacionNombre;
  final String? saborNombre;

  PresentacionSabor({
    required this.id,
    required this.presentacionId,
    required this.saborId,
    required this.orden,
    this.presentacionNombre,
    this.saborNombre,
  });

  factory PresentacionSabor.fromJson(Map<String, dynamic> json) {
    return PresentacionSabor(
      id: json['id'] ?? 0,
      presentacionId: json['presentacionId'] ?? json['presentacion']?['id'] ?? 0,
      saborId: json['saborId'] ?? json['sabor']?['id'] ?? 0,
      orden: json['orden'] ?? 1,
      presentacionNombre: json['presentacion']?['tipo'],
      saborNombre: json['sabor']?['nombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'presentacionId': presentacionId,
    'saborId': saborId,
    'orden': orden,
  };
}