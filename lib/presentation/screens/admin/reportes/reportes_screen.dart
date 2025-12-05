// lib/presentation/screens/admin/reportes/reportes_screen.dart

import 'package:avp_frontend/presentation/screens/admin/reportes/productos_report_screen.dart';
import 'package:avp_frontend/presentation/screens/admin/reportes/ventas_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../layouts/admin_layout.dart';
import 'inventario_report_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReporteDiario();
    });
  }

  Future<void> _loadReporteDiario() async {
    await context.read<DashboardProvider>().getReporteDiario();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: const Color(0xFF000000),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AdminLayout(
      title: 'Reportes y Estadísticas',
      currentRoute: '/admin/reportes',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadReporteDiario,
          tooltip: 'Refrescar',
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadReporteDiario,
        color: AppColors.secondary,
        backgroundColor: const Color(0xFF2A2A2A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de rango de fechas
              Card(
                color: const Color(0xFF1A1A1A),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.date_range,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Rango de Fechas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${dateFormat.format(_fechaInicio)} - ${dateFormat.format(_fechaFin)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Reporte Diario Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reporte del Día',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<DashboardProvider>(
                builder: (context, provider, _) {
                  if (provider.status == DashboardStatus.loading) {
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.secondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cargando datos...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (provider.dashboardData == null) {
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay datos disponibles',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final data = provider.dashboardData!;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Ventas Hoy',
                              value: data.totalVentas.toString(),
                              subtitle: 'ventas',
                              icon: Icons.receipt_long,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Ingresos',
                              value: 'Bs. ${data.montoTotal.toStringAsFixed(2)}',
                              subtitle: 'total',
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
                            child: _StatCard(
                              title: 'Pendientes',
                              value: data.pedidosPendientes.toString(),
                              subtitle: 'pedidos',
                              icon: Icons.pending_actions,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Alertas',
                              value: data.insumosBajoStock.toString(),
                              subtitle: 'insumos',
                              icon: Icons.warning_amber,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Reportes Detallados Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assessment,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reportes Detallados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _ReportCard(
                title: 'Reporte de Ventas',
                description: 'Análisis detallado de ventas por periodo',
                icon: Icons.trending_up,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VentasReportScreen(
                        fechaInicio: _fechaInicio,
                        fechaFin: _fechaFin,
                      ),
                    ),
                  );
                },
              ),

              _ReportCard(
                title: 'Productos Más Vendidos',
                description: 'Top de productos y sabores más solicitados',
                icon: Icons.local_pizza,
                color: AppColors.accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductosReportScreen(
                        fechaInicio: _fechaInicio,
                        fechaFin: _fechaFin,
                      ),
                    ),
                  );
                },
              ),

              _ReportCard(
                title: 'Estado de Inventario',
                description: 'Insumos bajo stock y movimientos',
                icon: Icons.inventory_2,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventarioReportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}