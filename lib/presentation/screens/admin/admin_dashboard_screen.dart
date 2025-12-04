// lib/presentation/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/insumo_provider.dart';
import '../../providers/pedido_provider.dart';
import '../auth/login_screen.dart';
import '../cajero/pedidos_list_screen.dart';
import 'insumos/insumos_list_screen.dart';
import 'productos/productos_list_screen.dart';
import 'reportes/reportes_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isSidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Expandir sidebar por defecto solo en desktop muy grande
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      if (size.width > 1400) {
        setState(() {
          _isSidebarExpanded = true;
        });
      }
    });
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

  void _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: !isDesktop ? _buildDrawer(context, authProvider) : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: isDesktop
            ? IconButton(
          icon: Icon(
            _isSidebarExpanded ? Icons.menu_open : Icons.menu,
            color: Colors.white70,
          ),
          onPressed: _toggleSidebar,
          tooltip: _isSidebarExpanded ? 'Colapsar menú' : 'Expandir menú',
        )
            : null,
        automaticallyImplyLeading: !isDesktop,
        title: Row(
          children: [
            if (!isDesktop) ...[
              const Icon(Icons.dashboard_outlined, color: Colors.white70),
              const SizedBox(width: 12),
            ],
            const Text(
              'Panel de Administración',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.account_circle, color: Colors.white70),
          //   color: const Color(0xFF1A1A1A),
          //   onSelected: (value) {
          //     if (value == 'logout') _logout();
          //   },
          //   itemBuilder: (context) => [
          //     PopupMenuItem(
          //       enabled: false,
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             authProvider.userName ?? 'Usuario',
          //             style: const TextStyle(
          //               fontWeight: FontWeight.bold,
          //               fontSize: 16,
          //               color: Colors.white,
          //             ),
          //           ),
          //           Text(
          //             authProvider.userEmail ?? '',
          //             style: const TextStyle(
          //               fontSize: 12,
          //               color: Colors.white60,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //     const PopupMenuDivider(),
          //     const PopupMenuItem(
          //       value: 'logout',
          //       child: Row(
          //         children: [
          //           Icon(Icons.logout, color: Colors.redAccent),
          //           SizedBox(width: 8),
          //           Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
          if (isDesktop) const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar para desktop con animación
          if (isDesktop)
            _buildCollapsibleSidebar(context, authProvider),

          // Contenido principal
          Expanded(
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
          ),
        ],
      ),
    );
  }

  // Sidebar colapsable con animación
  Widget _buildCollapsibleSidebar(BuildContext context, AuthProvider authProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarExpanded ? 280 : 72,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          right: BorderSide(
            color: Color(0xFF2A2A2A),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo y título
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(_isSidebarExpanded ? 24 : 16),
            child: Column(
              children: [
                Container(
                  width: _isSidebarExpanded ? 60 : 40,
                  height: _isSidebarExpanded ? 60 : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(_isSidebarExpanded ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.local_pizza,
                    color: Colors.white,
                    size: _isSidebarExpanded ? 32 : 24,
                  ),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'A Vera Pizza',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(color: Color(0xFF2A2A2A)),

          // Menú Principal
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                if (_isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Menú Principal',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isActive: true,
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.local_pizza,
                  title: 'Productos',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.category_outlined,
                  title: 'Categorías',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.person_outline,
                  title: 'Usuarios',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pedidos',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PedidosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Insumos',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InsumosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),

                if (_isSidebarExpanded) const SizedBox(height: 16),
                if (_isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Análisis',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                _SidebarItem(
                  icon: Icons.assessment_outlined,
                  title: 'Reportes',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Usuario info en el footer
          if (_isSidebarExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      (authProvider.userName?.substring(0, 1) ?? 'A').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          authProvider.userName ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Administrador',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.secondary, size: 20),
                    onPressed: _logout,
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),
            )
          else
          // Footer colapsado - solo avatar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    radius: 20,
                    child: Text(
                      (authProvider.userName?.substring(0, 1) ?? 'A').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.secondary, size: 20),
                    onPressed: _logout,
                    tooltip: 'Cerrar Sesión',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Drawer para mobile/tablet
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Header del drawer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF79DE65), Color(0xFF05551C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_pizza,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A Vera Pizza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userName ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menú items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.local_pizza,
                  title: 'Productos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductosListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.category_outlined,
                  title: 'Categorías',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'Usuarios',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PedidosListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Insumos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InsumosListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.assessment_outlined,
                  title: 'Reportes',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportesScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  onTap: () {},
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                _DrawerItem(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© 2025 A Vera Pizza',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
                  subtitle: 'Todos los pedidos',
                  icon: Icons.pending_actions,
                  color: const Color(0xFF3B82F6),
                  gradientColors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF2563EB),
                  ],
                ),
                _ModernStatCard(
                  title: 'Tasa de Éxito',
                  value: '${((data.totalVentas > 0 ? (data.totalVentas - data.pedidosPendientes) / data.totalVentas : 0) * 100).toStringAsFixed(1)}%',
                  subtitle: 'Completadas + Entregadas',
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
                _ModernStatCard(
                  title: 'Total Productos',
                  value: '1',
                  subtitle: 'En catálogo',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF8B5CF6),
                  gradientColors: [
                    const Color(0xFF8B5CF6),
                    const Color(0xFF7C3AED),
                  ],
                ),
                _ModernStatCard(
                  title: 'Alertas de Stock',
                  value: '${data.insumosBajoStock}',
                  subtitle: '0 bajo, 0 agotado',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  gradientColors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
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

// Widget para items del sidebar (Desktop) con soporte para colapsar
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: isExpanded ? '' : title,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 16 : 8,
                  vertical: 12
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.secondary.withOpacity(0.3) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: isExpanded
                  ? Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppColors.secondary : Colors.white60,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? AppColors.secondary : Colors.white70,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
                  : Center(
                child: Icon(
                  icon,
                  color: isActive ? AppColors.secondary : Colors.white60,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para items del drawer (Mobile)
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.redAccent
        : isActive
        ? const Color(0xFF3B82F6)
        : Colors.white70;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: const Color(0xFF3B82F6).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
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