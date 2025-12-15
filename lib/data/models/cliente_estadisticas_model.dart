// lib/data/models/cliente_estadisticas_model.dart

class ClienteEstadisticasModel {
  final int totalPedidos;
  final double totalGastado;
  final double promedioGasto;
  final String pizzaFavorita;

  ClienteEstadisticasModel({
    required this.totalPedidos,
    required this.totalGastado,
    required this.promedioGasto,
    required this.pizzaFavorita,
  });

  factory ClienteEstadisticasModel.fromJson(Map<String, dynamic> json) {
    return ClienteEstadisticasModel(
      totalPedidos: json['totalPedidos'] ?? 0,
      totalGastado: (json['totalGastado'] ?? 0.0).toDouble(),
      promedioGasto: (json['promedioGasto'] ?? 0.0).toDouble(),
      pizzaFavorita: json['pizzaFavorita'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPedidos': totalPedidos,
      'totalGastado': totalGastado,
      'promedioGasto': promedioGasto,
      'pizzaFavorita': pizzaFavorita,
    };
  }
}