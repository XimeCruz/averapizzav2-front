// lib/presentation/screens/admin/reportes/ventas_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/venta_por_tipo.dart';
import '../../../widgets/common/loading_widget.dart';

class VentasReportScreen extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;

  const VentasReportScreen({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  State<VentasReportScreen> createState() => _VentasReportScreenState();
}

class _VentasReportScreenState extends State<VentasReportScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  //Map<String, dynamic>? _reportData;
  List<dynamic> _reportData = [];
  List<VentaPorTipo> _ventasPorTipo = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // final inicio = DateFormat('yyyy-MM-dd').format(widget.fechaInicio);
      // final fin = DateFormat('yyyy-MM-dd').format(widget.fechaFin);
      final inicio = DateFormat('yyyy-MM-ddTHH:mm:ss').format(widget.fechaInicio);
      final fin = DateFormat('yyyy-MM-ddTHH:mm:ss').format(widget.fechaFin);
      // final response = await _apiClient.get(
      //   ApiConstants.ventasEntreFechas(inicio, fin),
      // );

      final results = await Future.wait([
        _apiClient.get(ApiConstants.ventasEntreFechas(inicio, fin)),
        _apiClient.get(ApiConstants.ventasPorTipo(inicio, fin)),
      ]);

      setState(() {
        //_reportData = response.data;
        //_reportData = response.data as List<dynamic>;

        _reportData = results[0].data as List<dynamic>;

        final ventasTipoData = results[1].data as List<dynamic>;
        _ventasPorTipo = ventasTipoData
            .map((json) => VentaPorTipo.fromJson(json as Map<String, dynamic>))
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Ventas'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Generando reporte...')
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReport,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con periodo
              Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Periodo del Reporte',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${dateFormat.format(widget.fechaInicio)} - ${dateFormat.format(widget.fechaFin)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Resumen General
              const Text(
                'Resumen General',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildSummaryCards(),

              const SizedBox(height: 24),

              // Ventas por Día
              const Text(
                'Ventas por Día',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildVentasPorDia(),

              const SizedBox(height: 24),

              // Ventas por Tipo de Servicio
              const Text(
                'Ventas por Tipo de Servicio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildVentasPorTipo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_reportData.isEmpty) return const SizedBox.shrink();

    // Calcular totales desde la lista
    final totalVentas = _reportData.length;
    final totalMonto = _reportData.fold<double>(
      0.0,
          (sum, venta) => sum + ((venta['total'] ?? 0) as num).toDouble(),
    );
    final promedioVenta = totalVentas > 0 ? totalMonto / totalVentas : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Ventas',
                value: totalVentas.toString(),
                subtitle: 'ventas registradas',
                icon: Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Ingresos',
                value: 'Bs. ${totalMonto.toStringAsFixed(2)}',
                subtitle: 'total generado',
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Promedio',
                value: 'Bs. ${promedioVenta.toStringAsFixed(2)}',
                subtitle: 'por venta',
                icon: Icons.analytics,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Pedidos',
                value: totalVentas.toString(),
                subtitle: 'entregados',
                icon: Icons.shopping_bag,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }


  // Widget _buildSummaryCards() {
  //   if (_reportData == null) return const SizedBox.shrink();
  //
  //   final totalVentas = _reportData!['totalVentas'] ?? 0;
  //   final totalMonto = (_reportData!['totalMonto'] ?? 0).toDouble();
  //   final promedioVenta = totalVentas > 0 ? totalMonto / totalVentas : 0.0;
  //   final totalPedidos = _reportData!['totalPedidos'] ?? 0;
  //
  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(
  //             child: _SummaryCard(
  //               title: 'Total Ventas',
  //               value: totalVentas.toString(),
  //               subtitle: 'ventas registradas',
  //               icon: Icons.receipt_long,
  //               color: AppColors.primary,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _SummaryCard(
  //               title: 'Ingresos',
  //               value: 'Bs. ${totalMonto.toStringAsFixed(2)}',
  //               subtitle: 'total generado',
  //               icon: Icons.attach_money,
  //               color: AppColors.success,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: _SummaryCard(
  //               title: 'Promedio',
  //               value: 'Bs. ${promedioVenta.toStringAsFixed(2)}',
  //               subtitle: 'por venta',
  //               icon: Icons.analytics,
  //               color: AppColors.info,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _SummaryCard(
  //               title: 'Pedidos',
  //               value: totalPedidos.toString(),
  //               subtitle: 'entregados',
  //               icon: Icons.shopping_bag,
  //               color: AppColors.accent,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildVentasPorDia() {
    if (_reportData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No hay ventas en este periodo'),
        ),
      );
    }

    // Agrupar ventas por día
    Map<String, List<dynamic>> ventasPorDia = {};
    for (var venta in _reportData) {
      final fecha = DateTime.parse(venta['fecha']);
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);

      if (!ventasPorDia.containsKey(fechaKey)) {
        ventasPorDia[fechaKey] = [];
      }
      ventasPorDia[fechaKey]!.add(venta);
    }

    return Column(
      children: ventasPorDia.entries.map((entry) {
        final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(entry.key));
        final cantidad = entry.value.length;
        final monto = entry.value.fold<double>(
          0.0,
              (sum, venta) => sum + ((venta['total'] ?? 0) as num).toDouble(),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              fecha,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$cantidad ventas'),
            trailing: Text(
              'Bs. ${monto.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget _buildVentasPorDia() {
  //   if (_reportData == null || _reportData!['ventasPorDia'] == null) {
  //     return const Card(
  //       child: Padding(
  //         padding: EdgeInsets.all(20.0),
  //         child: Text('No hay datos disponibles'),
  //       ),
  //     );
  //   }
  //
  //   final ventasPorDia = _reportData!['ventasPorDia'] as List;
  //
  //   if (ventasPorDia.isEmpty) {
  //     return const Card(
  //       child: Padding(
  //         padding: EdgeInsets.all(20.0),
  //         child: Text('No hay ventas en este periodo'),
  //       ),
  //     );
  //   }
  //
  //   return Column(
  //     children: ventasPorDia.map((dia) {
  //       final fecha = DateFormat('dd/MM/yyyy').format(
  //         DateTime.parse(dia['fecha']),
  //       );
  //       final cantidad = dia['cantidad'] ?? 0;
  //       final monto = (dia['monto'] ?? 0).toDouble();
  //
  //       return Card(
  //         margin: const EdgeInsets.only(bottom: 8),
  //         child: ListTile(
  //           leading: Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: AppColors.primary.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: const Icon(
  //               Icons.calendar_today,
  //               color: AppColors.primary,
  //               size: 20,
  //             ),
  //           ),
  //           title: Text(
  //             fecha,
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           subtitle: Text('$cantidad ventas'),
  //           trailing: Text(
  //             'Bs. ${monto.toStringAsFixed(2)}',
  //             style: const TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: AppColors.success,
  //             ),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  Widget _buildVentasPorTipo() {
    if (_ventasPorTipo.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No hay datos por tipo de servicio'),
        ),
      );
    }

    final tipoIcons = {
      'MESA': Icons.table_restaurant,
      'LLEVAR': Icons.shopping_bag,
      'DELIVERY': Icons.delivery_dining,
    };

    final tipoColors = {
      'MESA': AppColors.primary,
      'LLEVAR': AppColors.accent,
      'DELIVERY': AppColors.info,
    };

    return Column(
      children: _ventasPorTipo.map((venta) {
        final icon = tipoIcons[venta.tipoServicio] ?? Icons.help_outline;
        final color = tipoColors[venta.tipoServicio] ?? AppColors.textSecondary;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            title: Text(
              venta.tipoServicio,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${venta.cantidad} pedidos'),
            trailing: Text(
              'Bs. ${venta.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}