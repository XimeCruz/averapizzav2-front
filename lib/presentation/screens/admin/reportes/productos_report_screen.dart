// lib/presentation/screens/admin/reportes/productos_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../widgets/common/loading_widget.dart';

class ProductosReportScreen extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;

  const ProductosReportScreen({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  State<ProductosReportScreen> createState() => _ProductosReportScreenState();
}

class _ProductosReportScreenState extends State<ProductosReportScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<Map<String, dynamic>> _topProductos = [];
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
      final response = await _apiClient.get(ApiConstants.productosTop);

      setState(() {
        _topProductos = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
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
        title: const Text('Productos Más Vendidos'),
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
        child: _topProductos.isEmpty
            ? const Center(
          child: Text('No hay datos de productos vendidos'),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              color: AppColors.accent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_pizza,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
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

            // Top 3
            if (_topProductos.isNotEmpty)
              _buildTopThree(),

            const SizedBox(height: 24),

            // Lista completa
            const Text(
              'Ranking Completo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._topProductos.asMap().entries.map((entry) {
              return _ProductoRankCard(
                ranking: entry.key + 1,
                producto: entry.value,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThree() {
    if (_topProductos.length < 3) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 3 Productos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Segundo lugar
            Expanded(
              child: _TopCard(
                ranking: 2,
                producto: _topProductos[1],
                height: 140,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
            // Primer lugar
            Expanded(
              child: _TopCard(
                ranking: 1,
                producto: _topProductos[0],
                height: 180,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 8),
            // Tercer lugar
            Expanded(
              child: _TopCard(
                ranking: 3,
                producto: _topProductos[2],
                height: 120,
                color: const Color(0xFFCD7F32),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopCard extends StatelessWidget {
  final int ranking;
  final Map<String, dynamic> producto;
  final double height;
  final Color color;

  const _TopCard({
    required this.ranking,
    required this.producto,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = producto['nombre'] ?? '';
    final cantidad = producto['cantidad'] ?? 0;
    final total = (producto['total'] ?? 0).toDouble();

    return Card(
      elevation: 4,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$ranking',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              children: [
                Text(
                  '$cantidad',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'vendidos',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              'Bs. ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoRankCard extends StatelessWidget {
  final int ranking;
  final Map<String, dynamic> producto;

  const _ProductoRankCard({
    required this.ranking,
    required this.producto,
  });

  Color _getRankingColor() {
    if (ranking == 1) return const Color(0xFFFFD700);
    if (ranking == 2) return Colors.grey.shade400;
    if (ranking == 3) return const Color(0xFFCD7F32);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = producto['nombre'] ?? '';
    final cantidad = producto['cantidad'] ?? 0;
    final total = (producto['total'] ?? 0).toDouble();
    final color = _getRankingColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$ranking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ranking <= 3 ? color : AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$cantidad unidades vendidas'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Bs. ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            Text(
              (cantidad > 0 && total > 0)
                  ? 'Bs. ${(total / cantidad).toStringAsFixed(2)} c/u'
                  : 'Bs. 0.00 c/u',
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