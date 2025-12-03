import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Tema italiano
  static const Color primary = Color(0xFFD32F2F); // Rojo italiano
  static const Color primaryDark = Color(0xFF9A0007);
  static const Color primaryLight = Color(0xFFFF6659);

  static const Color secondary = Color(0xFF388E3C); // Verde italiano
  static const Color secondaryDark = Color(0xFF00600F);
  static const Color secondaryLight = Color(0xFF6ABF69);

  static const Color accent = Color(0xFFFFA726); // Naranja cálido

  // Fondos
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1A1A1A);

  // Textos
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Estados de pedidos
  static const Color pendiente = Color(0xFFFFA726); // Naranja
  static const Color enPreparacion = Color(0xFF42A5F5); // Azul
  static const Color listo = Color(0xFF66BB6A); // Verde
  static const Color entregado = Color(0xFF26A69A); // Verde azulado
  static const Color cancelado = Color(0xFFEF5350); // Rojo

  // Utilidades
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Método para obtener color por estado
  static Color getColorByEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return pendiente;
      case 'EN_PREPARACION':
        return enPreparacion;
      case 'LISTO':
        return listo;
      case 'ENTREGADO':
        return entregado;
      case 'CANCELADO':
        return cancelado;
      default:
        return textSecondary;
    }
  }
}