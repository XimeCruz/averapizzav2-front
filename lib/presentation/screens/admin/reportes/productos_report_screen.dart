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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Productos Más Vendidos',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadReport,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Generando reporte...')
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadReport,
        color: AppColors.secondary,
        backgroundColor: const Color(0xFF2A2A2A),
        child: _topProductos.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_pizza_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay datos de productos vendidos',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              color: const Color(0xFF1A1A1A),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_pizza,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periodo del Reporte',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(widget.fechaInicio)} - ${dateFormat.format(widget.fechaFin)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Top 3
            if (_topProductos.isNotEmpty) _buildTopThree(),

            const SizedBox(height: 32),

            // Lista completa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.format_list_numbered,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ranking Completo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Top 3 Productos',
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Segundo lugar
            Expanded(
              child: _TopCard(
                ranking: 2,
                producto: _topProductos[1],
                height: 160,
                color: const Color(0xFFC0C0C0),
              ),
            ),
            const SizedBox(width: 12),
            // Primer lugar
            Expanded(
              child: _TopCard(
                ranking: 1,
                producto: _topProductos[0],
                height: 200,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 12),
            // Tercer lugar
            Expanded(
              child: _TopCard(
                ranking: 3,
                producto: _topProductos[2],
                height: 140,
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
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '#$ranking',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              children: [
                Text(
                  '$cantidad',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'vendidos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Bs. ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
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
    if (ranking == 2) return const Color(0xFFC0C0C0);
    if (ranking == 3) return const Color(0xFFCD7F32);
    return AppColors.primary;
  }

  IconData _getRankingIcon() {
    if (ranking == 1) return Icons.emoji_events;
    if (ranking == 2) return Icons.workspace_premium;
    if (ranking == 3) return Icons.military_tech;
    return Icons.trending_up;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = producto['nombre'] ?? '';
    final cantidad = producto['cantidad'] ?? 0;
    final total = (producto['total'] ?? 0).toDouble();
    final color = _getRankingColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ranking <= 3
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: ranking <= 3 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: ranking <= 3
                    ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: ranking > 3 ? AppColors.primary.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getRankingIcon(),
                    color: ranking <= 3 ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                  Text(
                    '#$ranking',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ranking <= 3 ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$cantidad unidades vendidas',
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
                  'Bs. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (cantidad > 0 && total > 0)
                      ? 'Bs. ${(total / cantidad).toStringAsFixed(2)} c/u'
                      : 'Bs. 0.00 c/u',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}