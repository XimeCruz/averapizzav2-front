enum TipoProducto {
  PIZZA,
  BEBIDA,
  OTRO
}

class Producto {
  final int id;
  final String nombre;
  final TipoProducto tipoProducto;
  final bool tieneSabores;

  Producto({
    required this.id,
    required this.nombre,
    required this.tipoProducto,
    required this.tieneSabores,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      tipoProducto: _parseTipoProducto(json['tipoProducto']),
      tieneSabores: json['tieneSabores'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipoProducto': tipoProducto.name,
    'tieneSabores': tieneSabores,
  };

  static TipoProducto _parseTipoProducto(dynamic value) {
    if (value == null) return TipoProducto.OTRO;
    final str = value.toString().toUpperCase();
    return TipoProducto.values.firstWhere(
          (e) => e.name == str,
      orElse: () => TipoProducto.OTRO,
    );
  }
}

class CreateProductoRequest {
  final String nombre;
  final TipoProducto tipoProducto;
  final bool tieneSabores;

  CreateProductoRequest({
    required this.nombre,
    required this.tipoProducto,
    required this.tieneSabores,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'tipoProducto': tipoProducto.name,
    'tieneSabores': tieneSabores,
  };
}

// SaborPizza
class SaborPizza {
  final int id;
  final String nombre;
  final String? descripcion;
  final int productoId;
  final List<PrecioSaborPresentacion>? precios;

  SaborPizza({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.productoId,
    this.precios,
  });

  factory SaborPizza.fromJson(Map<String, dynamic> json) {
    return SaborPizza(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      productoId: json['productoId'] ?? json['producto']?['id'] ?? 0,
      precios: (json['precios'] as List?)
          ?.map((e) => PrecioSaborPresentacion.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'productoId': productoId,
  };
}

class CreateSaborRequest {
  final String nombre;
  final String? descripcion;
  final int productoId;

  CreateSaborRequest({
    required this.nombre,
    this.descripcion,
    required this.productoId,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'nombre': nombre,
      'productoId': productoId,
    };
    if (descripcion != null) map['descripcion'] = descripcion!;
    return map;
  }
}

// PresentacionProducto
enum TipoPresentacion {
  PESO,
  REDONDA,
  BANDEJA
}

class PresentacionProducto {
  final int id;
  final TipoPresentacion tipo;
  final bool usaPeso;
  final int maxSabores;
  final double? precioBase;

  PresentacionProducto({
    required this.id,
    required this.tipo,
    required this.usaPeso,
    required this.maxSabores,
    this.precioBase,
  });

  factory PresentacionProducto.fromJson(Map<String, dynamic> json) {
    return PresentacionProducto(
      id: json['id'] ?? 0,
      tipo: _parseTipoPresentacion(json['tipo']),
      usaPeso: json['usaPeso'] ?? false,
      maxSabores: json['maxSabores'] ?? 1,
      precioBase: json['precioBase'] != null
          ? (json['precioBase'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo.name,
    'usaPeso': usaPeso,
    'maxSabores': maxSabores,
    if (precioBase != null) 'precioBase': precioBase,
  };

  static TipoPresentacion _parseTipoPresentacion(dynamic value) {
    if (value == null) return TipoPresentacion.PESO;
    final str = value.toString().toUpperCase();
    return TipoPresentacion.values.firstWhere(
          (e) => e.name == str,
      orElse: () => TipoPresentacion.PESO,
    );
  }

  String getNombre() {
    switch (tipo) {
      case TipoPresentacion.PESO:
        return 'Al Peso';
      case TipoPresentacion.REDONDA:
        return 'Redonda';
      case TipoPresentacion.BANDEJA:
        return 'Bandeja';
    }
  }
}

class CreatePresentacionRequest {
  final TipoPresentacion tipo;
  final bool usaPeso;
  final int maxSabores;
  final double? precioBase;

  CreatePresentacionRequest({
    required this.tipo,
    required this.usaPeso,
    required this.maxSabores,
    this.precioBase,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'tipo': tipo.name,
      'usaPeso': usaPeso,
      'maxSabores': maxSabores,
    };
    if (precioBase != null) map['precioBase'] = precioBase!;
    return map;
  }
}

// PrecioSaborPresentacion
class PrecioSaborPresentacion {
  final int id;
  final int saborId;
  final int presentacionId;
  final double precio;
  final PresentacionProducto? presentacion;

  PrecioSaborPresentacion({
    required this.id,
    required this.saborId,
    required this.presentacionId,
    required this.precio,
    this.presentacion,
  });

  factory PrecioSaborPresentacion.fromJson(Map<String, dynamic> json) {
    return PrecioSaborPresentacion(
      id: json['id'] ?? 0,
      saborId: json['saborId'] ?? json['sabor']?['id'] ?? 0,
      presentacionId: json['presentacionId'] ?? json['presentacion']?['id'] ?? 0,
      precio: (json['precio'] ?? 0).toDouble(),
      presentacion: json['presentacion'] != null
          ? PresentacionProducto.fromJson(json['presentacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'saborId': saborId,
    'presentacionId': presentacionId,
    'precio': precio,
  };
}

class CreatePrecioRequest {
  final int presentacionId;
  final double precio;

  CreatePrecioRequest({
    required this.presentacionId,
    required this.precio,
  });

  Map<String, dynamic> toJson() => {
    'presentacionId': presentacionId,
    'precio': precio,
  };
}