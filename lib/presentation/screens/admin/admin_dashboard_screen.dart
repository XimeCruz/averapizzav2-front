// lib/presentation/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/admin_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/insumo_provider.dart';
import '../../providers/pedido_provider.dart';
import 'insumos/insumos_list_screen.dart';
import 'productos/productos_list_screen.dart';
import 'reportes/reportes_screen.dart';
import '../cajero/pedidos_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final insumoProvider = context.read<InsumoProvider>();
    final pedidoProvider = context.read<PedidoProvider>();

    await Future.wait([
      dashboardProvider.loadDashboard(),
      insumoProvider.loadInsumosBajoStock(),
      pedidoProvider.loadPedidosPendientes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return AdminLayout(
      title: 'Panel de Administración',
      currentRoute: '/admin/dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadData,
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: const Color(0xFF1A1A1A),
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con saludo
              _buildHeader(authProvider),
              const SizedBox(height: 24),

              // Estadísticas principales
              _buildStatsSection(isDesktop, isTablet),

              const SizedBox(height: 24),

              // Estado de transacciones y alertas
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTransactionStatesSection(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildAlertsSection(),
                          const SizedBox(height: 24),
                          _buildQuickActionsSection(isDesktop, isTablet),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildTransactionStatesSection(),
                const SizedBox(height: 24),
                _buildAlertsSection(),
                const SizedBox(height: 24),
                _buildQuickActionsSection(isDesktop, isTablet),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${authProvider.userName?.split(' ').first ?? 'Admin'}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenido al panel de administración de A Vera Pizza',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.status == DashboardStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          );
        }

        if (provider.status == DashboardStatus.error) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              provider.errorMessage ?? 'Error al cargar datos',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final data = provider.dashboardData;
        if (data == null) return const SizedBox.shrink();

        int crossAxisCount;
        if (isDesktop) {
          crossAxisCount = 4;
        } else if (isTablet) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 2;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Generales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen del estado actual del sistema',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.3 : 1.2,
              children: [
                _ModernStatCard(
                  title: 'Total Pedidos',
                  value: '${data.totalVentas}',
                  icon: Icons.pending_actions,
                  color: const Color(0xFF3B82F6),
                  gradientColors: const [
                    Color(0xFF3B82F6),
                    Color(0xFF2563EB),
                  ],
                ),
                _ModernStatCard(
                  title: 'Tasa de Entrega',
                  value: '${((data.totalVentas > 0 ? (data.totalVentas - data.pedidosPendientes) / data.totalVentas : 0) * 100).toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                  gradientColors: const [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                _ModernStatCard(
                  title: 'Total Productos',
                  value: '1',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF8B5CF6),
                  gradientColors: const [
                    Color(0xFF8B5CF6),
                    Color(0xFF7C3AED),
                  ],
                ),
                _ModernStatCard(
                  title: 'Alertas de Stock',
                  value: '${data.insumosBajoStock}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  gradientColors: const [
                    Color(0xFFEF4444),
                    Color(0xFFDC2626),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionStatesSection() {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final data = provider.dashboardData;
        if (data == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del dia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _TransactionStateCard(
                  title: 'Ventas del Dia',
                  value: 'Bs. ${data.montoTotal.toStringAsFixed(2)}',
                  subtitle: '${data.totalVentas} ventas',
                  icon: Icons.attach_money,
                  color: const Color(0xFFF59E0B),
                ),
                _TransactionStateCard(
                  title: 'Pedidos pendientes',
                  value: '${data.pedidosPendientes}',
                  subtitle: 'Por atender',
                  icon: Icons.pending_actions,
                  color: const Color(0xFF3B82F6),
                ),
                _TransactionStateCard(
                  title: 'En Preparación',
                  value: '${data.pedidosEnPreparacion}',
                  subtitle: 'En cocina',
                  icon: Icons.restaurant,
                  color: const Color(0xFF8B5CF6),
                ),
                _TransactionStateCard(
                  title: 'Entregadas',
                  value: '${data.insumosBajoStock}',
                  subtitle: 'Pedidos',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertsSection() {
    return Consumer<InsumoProvider>(
      builder: (context, provider, _) {
        if (provider.insumosBajoStock.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Text(
                  'Alertas de Inventario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${provider.insumosBajoStock.length} insumos necesitan reposición',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF2A2A2A)),
                  const SizedBox(height: 8),
                  ...provider.insumosBajoStock.take(3).map((insumo) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${insumo.nombre}: ${insumo.stockActual} ${insumo.unidadMedida}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                  if (provider.insumosBajoStock.length > 3)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InsumosListScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver todos',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection(bool isDesktop, bool isTablet) {
    int crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 2;
    } else if (isTablet) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 1.3 : (isTablet ? 1.0 : 1.5),
          children: [
            _QuickActionCard(
              title: 'Productos',
              icon: Icons.local_pizza,
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductosListScreen(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              title: 'Insumos',
              icon: Icons.inventory_2,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsumosListScreen(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              title: 'Reportes',
              icon: Icons.assessment,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportesScreen(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              title: 'Pedidos',
              icon: Icons.receipt_long,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PedidosListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Widgets privados
class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
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

class _TransactionStateCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TransactionStateCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
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
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}