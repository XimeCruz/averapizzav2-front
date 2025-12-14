// lib/presentation/screens/admin/reportes/productos_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

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
  List<Map<String, dynamic>> _saboresMasVendidos = [];
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
      final inicio = DateFormat('yyyy-MM-ddTHH:mm:ss').format(widget.fechaInicio);
      final fin = DateFormat('yyyy-MM-ddTHH:mm:ss').format(widget.fechaFin);

      // Puedes usar cualquiera de los dos endpoints
      final response = await _apiClient.get(ApiConstants.topSabores(inicio, fin));
      // O: final response = await _apiClient.get(ApiConstants.saboresMasVendidos(inicio, fin));

      setState(() {
        _saboresMasVendidos = (response.data as List)
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Productos Más Vendidos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Generando reporte...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadReport,
        color: AppColors.secondary,
        backgroundColor: const Color(0xFF2A2A2A),
        child: _saboresMasVendidos.isEmpty
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
              Text(
                'No hay datos de productos vendidos',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con periodo
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_pizza,
                          color: AppColors.accent,
                          size: 28,
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
                                fontSize: 13,
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

              // Resumen General
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: AppColors.success,
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

              _buildResumenGeneral(),

              const SizedBox(height: 32),

              // Top 3 Sabores
              if (_saboresMasVendidos.length >= 3) ...[
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
                      'Top 3 Sabores',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTopThree(),
                const SizedBox(height: 32),
              ],

              // Ranking Completo
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

              ..._saboresMasVendidos.asMap().entries.map((entry) {
                return _SaborCard(
                  ranking: entry.key + 1,
                  sabor: entry.value,
                );
              }),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    final totalIngresos = _saboresMasVendidos.fold<double>(
      0.0,
          (sum, sabor) => sum + ((sabor['totalVendido'] ?? 0) as num).toDouble(),
    );

    final totalPedidos = _saboresMasVendidos.fold<int>(
      0,
          (sum, sabor) => sum + ((sabor['cantidadPedidos'] ?? 0) as int),
    );

    final promedioPorPedido = totalPedidos > 0 ? totalIngresos / totalPedidos : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Ingresos Totales',
                value: 'Bs. ${totalIngresos.toStringAsFixed(2)}',
                subtitle: 'generados',
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Total Pedidos',
                value: totalPedidos.toString(),
                subtitle: 'pedidos',
                icon: Icons.shopping_bag,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Promedio',
                value: 'Bs. ${promedioPorPedido.toStringAsFixed(2)}',
                subtitle: 'por pedido',
                icon: Icons.analytics,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Sabores',
                value: _saboresMasVendidos.length.toString(),
                subtitle: 'diferentes',
                icon: Icons.local_pizza,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopThree() {
    if (_saboresMasVendidos.length < 3) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Segundo lugar
        Expanded(
          child: _TopCard(
            ranking: 2,
            sabor: _saboresMasVendidos[1],
            height: 180,
            color: const Color(0xFFC0C0C0),
          ),
        ),
        const SizedBox(width: 8),
        // Primer lugar
        Expanded(
          child: _TopCard(
            ranking: 1,
            sabor: _saboresMasVendidos[0],
            height: 220,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 8),
        // Tercer lugar
        Expanded(
          child: _TopCard(
            ranking: 3,
            sabor: _saboresMasVendidos[2],
            height: 160,
            color: const Color(0xFFCD7F32),
          ),
        ),
      ],
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

class _TopCard extends StatelessWidget {
  final int ranking;
  final Map<String, dynamic> sabor;
  final double height;
  final Color color;

  const _TopCard({
    required this.ranking,
    required this.sabor,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = sabor['saborNombre'] ?? '';
    final cantidadPedidos = sabor['cantidadPedidos'] ?? 0;
    final totalVendido = (sabor['totalVendido'] ?? 0).toDouble();

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Column(
              children: [
                Text(
                  '$cantidadPedidos',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'pedidos',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Bs. ${totalVendido.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaborCard extends StatelessWidget {
  final int ranking;
  final Map<String, dynamic> sabor;

  const _SaborCard({
    required this.ranking,
    required this.sabor,
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
    return Icons.local_pizza;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = sabor['saborNombre'] ?? '';
    final cantidadPedidos = sabor['cantidadPedidos'] ?? 0;
    final totalVendido = (sabor['totalVendido'] ?? 0).toDouble();
    final detalles = (sabor['detallesPorPresentacion'] ?? []) as List;
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
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
          title: Text(
            nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$cantidadPedidos pedidos',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bs. ${totalVendido.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ver detalles',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: AppColors.info,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detalles por Presentación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...detalles.map((detalle) {
                    final tipoPresentacion = detalle['tipoPresentacion'] ?? '';
                    final cantidadVendida = (detalle['cantidadVendida'] ?? 0).toDouble();
                    final numeroVentas = detalle['numeroVentas'] ?? 0;
                    final ingresoTotal = (detalle['ingresoTotal'] ?? 0).toDouble();

                    IconData iconPresentacion;
                    Color colorPresentacion;

                    switch (tipoPresentacion) {
                      case 'PESO':
                        iconPresentacion = Icons.scale;
                        colorPresentacion = AppColors.warning;
                        break;
                      case 'REDONDA':
                        iconPresentacion = Icons.circle_outlined;
                        colorPresentacion = AppColors.primary;
                        break;
                      case 'BANDEJA':
                        iconPresentacion = Icons.square_outlined;
                        colorPresentacion = AppColors.accent;
                        break;
                      default:
                        iconPresentacion = Icons.shopping_basket;
                        colorPresentacion = AppColors.secondary;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorPresentacion.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              iconPresentacion,
                              color: colorPresentacion,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipoPresentacion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$numeroVentas ventas • ${cantidadVendida.toStringAsFixed(2)} ${tipoPresentacion == 'PESO' ? 'kg' : 'unid.'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs. ${ingresoTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorPresentacion,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}