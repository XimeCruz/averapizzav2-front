// lib/presentation/screens/admin/predicciones_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../layouts/admin_layout.dart';
import '../../../core/constants/app_colors.dart';

// Modelos
class PrediccionDetalladaDTO {
  final String fecha;
  final List<PrediccionItemDTO> items;
  final int totalPedidos;
  final double confianzaPromedio;

  PrediccionDetalladaDTO({
    required this.fecha,
    required this.items,
    required this.totalPedidos,
    required this.confianzaPromedio,
  });

  factory PrediccionDetalladaDTO.fromJson(Map<String, dynamic> json) {
    return PrediccionDetalladaDTO(
      fecha: json['fecha'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => PrediccionItemDTO.fromJson(item))
          .toList() ?? [],
      totalPedidos: json['totalPedidos'] ?? 0,
      confianzaPromedio: (json['confianzaPromedio'] ?? 0.0).toDouble(),
    );
  }
}

class PrediccionItemDTO {
  final String productoNombre;
  final String saborNombre;
  final String presentacion;
  final int cantidad;
  final double confianza;
  final HistoricoVentasDTO historico;

  PrediccionItemDTO({
    required this.productoNombre,
    required this.saborNombre,
    required this.presentacion,
    required this.cantidad,
    required this.confianza,
    required this.historico,
  });

  factory PrediccionItemDTO.fromJson(Map<String, dynamic> json) {
    return PrediccionItemDTO(
      productoNombre: json['productoNombre'] ?? '',
      saborNombre: json['saborNombre'] ?? '',
      presentacion: json['presentacion'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      confianza: (json['confianza'] ?? 0.0).toDouble(),
      historico: HistoricoVentasDTO.fromJson(json['historico'] ?? {}),
    );
  }
}

class HistoricoVentasDTO {
  final double promedioUltimos7Dias;
  final double promedioUltimos30Dias;
  final int ventasAyer;
  final String tendencia;

  HistoricoVentasDTO({
    required this.promedioUltimos7Dias,
    required this.promedioUltimos30Dias,
    required this.ventasAyer,
    required this.tendencia,
  });

  factory HistoricoVentasDTO.fromJson(Map<String, dynamic> json) {
    return HistoricoVentasDTO(
      promedioUltimos7Dias: (json['promedioUltimos7Dias'] ?? 0.0).toDouble(),
      promedioUltimos30Dias: (json['promedioUltimos30Dias'] ?? 0.0).toDouble(),
      ventasAyer: json['ventasAyer'] ?? 0,
      tendencia: json['tendencia'] ?? 'ESTABLE',
    );
  }
}

class EstadisticasDTO {
  final String fechaInicio;
  final String fechaFin;
  final int totalPedidos;
  final double ventaPromedioDiaria;
  final String productoMasVendido;
  final String saborMasVendido;
  final List<VentaDiariaDTO> ventasPorDia;

  EstadisticasDTO({
    required this.fechaInicio,
    required this.fechaFin,
    required this.totalPedidos,
    required this.ventaPromedioDiaria,
    required this.productoMasVendido,
    required this.saborMasVendido,
    required this.ventasPorDia,
  });

  factory EstadisticasDTO.fromJson(Map<String, dynamic> json) {
    return EstadisticasDTO(
      fechaInicio: json['fechaInicio'] ?? '',
      fechaFin: json['fechaFin'] ?? '',
      totalPedidos: json['totalPedidos'] ?? 0,
      ventaPromedioDiaria: (json['ventaPromedioDiaria'] ?? 0.0).toDouble(),
      productoMasVendido: json['productoMasVendido'] ?? 'N/A',
      saborMasVendido: json['saborMasVendido'] ?? 'N/A',
      ventasPorDia: (json['ventasPorDia'] as List?)
          ?.map((v) => VentaDiariaDTO.fromJson(v))
          .toList() ?? [],
    );
  }
}

class VentaDiariaDTO {
  final String fecha;
  final String diaSemana;
  final int cantidadPedidos;
  final double totalVentas;

  VentaDiariaDTO({
    required this.fecha,
    required this.diaSemana,
    required this.cantidadPedidos,
    required this.totalVentas,
  });

  factory VentaDiariaDTO.fromJson(Map<String, dynamic> json) {
    return VentaDiariaDTO(
      fecha: json['fecha'] ?? '',
      diaSemana: json['diaSemana'] ?? '',
      cantidadPedidos: json['cantidadPedidos'] ?? 0,
      totalVentas: (json['totalVentas'] ?? 0.0).toDouble(),
    );
  }
}

// Pantalla Principal
class PrediccionesScreen extends StatefulWidget {
  const PrediccionesScreen({Key? key}) : super(key: key);

  @override
  State<PrediccionesScreen> createState() => _PrediccionesScreenState();
}

class _PrediccionesScreenState extends State<PrediccionesScreen> {
  final String baseUrl = 'http://localhost:8089/api/predicciones';

  PrediccionDetalladaDTO? prediccionManana;
  List<PrediccionDetalladaDTO>? prediccionesSemana;
  EstadisticasDTO? estadisticas;

  bool isLoading = false;
  String vistaActual = 'manana'; // 'manana', 'semana', 'estadisticas'

  @override
  void initState() {
    super.initState();
    cargarPrediccionManana();
  }

  Future<void> cargarPrediccionManana() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/manana'));
      if (response.statusCode == 200) {
        setState(() {
          prediccionManana = PrediccionDetalladaDTO.fromJson(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      mostrarError('Error al cargar predicción de mañana');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> cargarPrediccionSemana() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/proxima-semana'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          prediccionesSemana = jsonList
              .map((json) => PrediccionDetalladaDTO.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      mostrarError('Error al cargar predicción de la semana: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> cargarEstadisticas() async {
    setState(() => isLoading = true);
    try {
      // Calcular rango de fechas: últimos 30 días
      final fin = DateTime.now();
      final inicio = fin.subtract(const Duration(days: 30));

      // Formatear fechas en formato ISO (YYYY-MM-DD)
      final inicioStr = '${inicio.year}-${inicio.month.toString().padLeft(2, '0')}-${inicio.day.toString().padLeft(2, '0')}';
      final finStr = '${fin.year}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}';

      final url = '$baseUrl/estadisticas?inicio=$inicioStr&fin=$finStr';
      print('URL: $url'); // Debug

      final response = await http.get(Uri.parse(url));
      print('Status: ${response.statusCode}'); // Debug
      print('Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('JSON parsed: $jsonData'); // Debug

        setState(() {
          estadisticas = EstadisticasDTO.fromJson(jsonData);
        });
      } else {
        mostrarError('Error del servidor: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e'); // Debug
      print('StackTrace: $stackTrace'); // Debug
      mostrarError('Error al cargar estadísticas: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> generarPredicciones() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(Uri.parse('$baseUrl/generar'));
      if (response.statusCode == 200) {
        mostrarExito('Predicciones generadas exitosamente');
        cargarPrediccionManana();
      }
    } catch (e) {
      mostrarError('Error al generar predicciones');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> limpiarPredicciones() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Confirmar',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Deseas limpiar todas las predicciones?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(Uri.parse('$baseUrl/limpiar'));
        if (response.statusCode == 200) {
          mostrarExito('Predicciones limpiadas');
          setState(() {
            prediccionManana = null;
            prediccionesSemana = null;
            estadisticas = null;
          });
        }
      } catch (e) {
        mostrarError('Error al limpiar predicciones');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Predicciones',
      currentRoute: '/admin/predicciones',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: () {
            if (vistaActual == 'manana') cargarPrediccionManana();
            if (vistaActual == 'semana') cargarPrediccionSemana();
            if (vistaActual == 'estadisticas') cargarEstadisticas();
          },
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome, color: AppColors.secondary),
          onPressed: generarPredicciones,
          tooltip: 'Generar Predicciones',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: limpiarPredicciones,
          tooltip: 'Limpiar Predicciones',
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          // Tabs de navegación
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTab('Mañana', 'manana'),
                const SizedBox(width: 12),
                _buildTab('Próxima Semana', 'semana'),
                const SizedBox(width: 12),
                _buildTab('Estadísticas', 'estadisticas'),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              )
                  : _buildContenido(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String titulo, String vista) {
    final activo = vistaActual == vista;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => vistaActual = vista);
          if (vista == 'manana' && prediccionManana == null) {
            cargarPrediccionManana();
          } else if (vista == 'semana' && prediccionesSemana == null) {
            cargarPrediccionSemana();
          } else if (vista == 'estadisticas' && estadisticas == null) {
            cargarEstadisticas();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? AppColors.secondary : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activo ? AppColors.secondary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? Colors.white : Colors.white60,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (vistaActual == 'manana') {
      return _buildPrediccion(prediccionManana);
    } else if (vistaActual == 'semana') {
      return _buildPrediccionesSemana();
    } else {
      return _buildEstadisticas();
    }
  }

  Widget _buildPrediccion(PrediccionDetalladaDTO? prediccion) {
    if (prediccion == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay predicciones disponibles',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: generarPredicciones,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar Predicciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header con resumen
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.white60),
                  const SizedBox(width: 8),
                  Text(
                    prediccion.fecha,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Pedidos',
                      prediccion.totalPedidos.toString(),
                      Icons.shopping_bag_outlined,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Confianza',
                      '${(prediccion.confianzaPromedio * 100).toStringAsFixed(0)}%',
                      Icons.show_chart,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Lista de predicciones
        ...prediccion.items.map((item) => _buildPrediccionCard(item)).toList(),
      ],
    );
  }

  Widget _buildPrediccionesSemana() {
    if (prediccionesSemana == null || prediccionesSemana!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay predicciones de la semana',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: generarPredicciones,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar Predicciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prediccionesSemana!.length,
      itemBuilder: (context, index) {
        final prediccion = prediccionesSemana![index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: Theme(
            data: ThemeData(
              dividerColor: Colors.transparent,
              colorScheme: ColorScheme.dark(
                primary: AppColors.secondary,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(20),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text(
                    prediccion.fecha,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    _buildMiniStatChip(
                      '${prediccion.totalPedidos} pedidos',
                      Icons.shopping_bag_outlined,
                      const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStatChip(
                      '${(prediccion.confianzaPromedio * 100).toStringAsFixed(0)}%',
                      Icons.show_chart,
                      AppColors.secondary,
                    ),
                  ],
                ),
              ),
              children: [
                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                const SizedBox(height: 16),
                ...prediccion.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPrediccionCardCompact(item),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrediccionCardCompact(PrediccionItemDTO item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.productoNombre} - ${item.saborNombre}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.presentacion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.cantidad}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'un.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTendenciaIcon(item.historico.tendencia),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrediccionCard(PrediccionItemDTO item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del producto
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.productoNombre} - ${item.saborNombre}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.presentacion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTendenciaIcon(item.historico.tendencia),
            ],
          ),

          const SizedBox(height: 16),

          // Cantidad predicha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(
                  'Predicción: ${item.cantidad} unidades',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Confianza
          Row(
            children: [
              Text(
                'Confianza: ',
                style: TextStyle(fontSize: 13, color: Colors.white60),
              ),
              Text(
                '${(item.confianza * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.confianza,
                    backgroundColor: const Color(0xFF2A2A2A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.confianza > 0.8 ? AppColors.secondary : const Color(0xFFFF9800),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Histórico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos Históricos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHistoricoItem(
                      'Ayer',
                      item.historico.ventasAyer.toString(),
                    ),
                    _buildHistoricoItem(
                      '7 días',
                      item.historico.promedioUltimos7Dias.toStringAsFixed(1),
                    ),
                    _buildHistoricoItem(
                      '30 días',
                      item.historico.promedioUltimos30Dias.toStringAsFixed(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendenciaIcon(String tendencia) {
    IconData icon;
    Color color;

    switch (tendencia) {
      case 'CRECIENTE':
        icon = Icons.trending_up;
        color = AppColors.secondary;
        break;
      case 'DECRECIENTE':
        icon = Icons.trending_down;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.trending_flat;
        color = const Color(0xFFFF9800);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _buildHistoricoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticas() {
    if (estadisticas == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay estadísticas disponibles',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header con rango de fechas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, size: 20, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text(
                '${estadisticas!.fechaInicio} - ${estadisticas!.fechaFin}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildEstadisticaCard(
                'Total Pedidos',
                estadisticas!.totalPedidos.toString(),
                Icons.shopping_bag_outlined,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEstadisticaCard(
                'Promedio Diario',
                estadisticas!.ventaPromedioDiaria.toStringAsFixed(1),
                Icons.timeline,
                const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildEstadisticaCard(
          'Producto Más Vendido',
          estadisticas!.productoMasVendido,
          Icons.local_pizza,
          AppColors.secondary,
        ),

        const SizedBox(height: 12),

        _buildEstadisticaCard(
          'Sabor Más Vendido',
          estadisticas!.saborMasVendido,
          Icons.star,
          const Color(0xFFFF9800),
        ),

        const SizedBox(height: 20),

        // Título de ventas por día
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Ventas por Día',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Lista de ventas por día
        ...estadisticas!.ventasPorDia.map((venta) => _buildVentaDiariaCard(venta)).toList(),
      ],
    );
  }

  Widget _buildVentaDiariaCard(VentaDiariaDTO venta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          // Fecha y día
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venta.fecha,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venta.diaSemana.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Pedidos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  venta.cantidadPedidos.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                Text(
                  'pedidos',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Total ventas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
            'Bs. ${venta.totalVentas.toStringAsFixed(2)}' ,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(
      String titulo,
      String valor,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}