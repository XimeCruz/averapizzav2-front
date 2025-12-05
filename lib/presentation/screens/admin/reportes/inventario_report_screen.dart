// lib/presentation/screens/admin/reportes/inventario_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/insumo_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class InventarioReportScreen extends StatefulWidget {
  const InventarioReportScreen({super.key});

  @override
  State<InventarioReportScreen> createState() => _InventarioReportScreenState();
}

class _InventarioReportScreenState extends State<InventarioReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<InsumoProvider>();
    await Future.wait([
      provider.loadInsumos(),
      provider.loadInsumosBajoStock(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Estado de Inventario',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Consumer<InsumoProvider>(
        builder: (context, provider, _) {
          if (provider.status == InsumoStatus.loading) {
            return const LoadingWidget(message: 'Cargando inventario...');
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.secondary,
            backgroundColor: const Color(0xFF2A2A2A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen general
                  _buildResumenGeneral(provider),

                  const SizedBox(height: 24),

                  // Alertas de stock bajo
                  if (provider.insumosBajoStock.isNotEmpty) ...[
                    _buildAlertasSection(provider),
                    const SizedBox(height: 24),
                  ],

                  // Estado de todos los insumos
                  _buildInventarioCompleto(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenGeneral(InsumoProvider provider) {
    final totalInsumos = provider.insumos.length;
    final bajoStock = provider.insumosBajoStock.length;
    final stockOk = totalInsumos - bajoStock;
    final porcentajeBajo = totalInsumos > 0
        ? (bajoStock / totalInsumos * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
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
                Icons.summarize,
                color: AppColors.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Insumos',
                value: totalInsumos.toString(),
                icon: Icons.inventory_2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Stock OK',
                value: stockOk.toString(),
                icon: Icons.check_circle,
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
                title: 'Bajo Stock',
                value: bajoStock.toString(),
                icon: Icons.warning_amber,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: '% Crítico',
                value: '$porcentajeBajo%',
                icon: Icons.trending_down,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertasSection(InsumoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Alertas de Stock Bajo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${provider.insumosBajoStock.length} insumos necesitan reposición urgente',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...provider.insumosBajoStock.map((insumo) {
          return _InsumoAlertCard(insumo: insumo);
        }),
      ],
    );
  }

  Widget _buildInventarioCompleto(InsumoProvider provider) {
    final insumosOk = provider.insumos
        .where((i) => !i.esBajoStock)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Inventario Completo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (insumosOk.isEmpty)
          Card(
            color: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Todos los insumos están bajo stock',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...insumosOk.map((insumo) {
            return _InsumoCard(insumo: insumo);
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
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
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsumoAlertCard extends StatelessWidget {
  final dynamic insumo;

  const _InsumoAlertCard({required this.insumo});

  @override
  Widget build(BuildContext context) {
    final porcentaje = insumo.porcentajeStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insumo.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock: ${insumo.stockActual} ${insumo.unidadMedida}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'del mínimo',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: porcentaje / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFF2A2A2A),
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mínimo requerido: ${insumo.stockMinimo} ${insumo.unidadMedida}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsumoCard extends StatelessWidget {
  final dynamic insumo;

  const _InsumoCard({required this.insumo});

  @override
  Widget build(BuildContext context) {
    final porcentaje = insumo.porcentajeStock;

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insumo.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(insumo.stockActual).toStringAsFixed(2)} ${insumo.unidadMedida} disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'del mínimo',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: porcentaje / 100 > 1 ? 1 : porcentaje / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFF2A2A2A),
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}