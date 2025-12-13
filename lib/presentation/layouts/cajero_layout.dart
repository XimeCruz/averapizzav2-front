// lib/presentation/layouts/cajero_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/pedido_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cajero/cajero_dashboard_screen.dart';
import '../screens/cajero/crear_pedido_screen.dart';
import '../screens/cajero/historial_pedidos_screen.dart';
import '../screens/cajero/pedidos_en_cocina_screen.dart';
import '../screens/admin/pedidos/pedidos_list_screen.dart';
import '../screens/cajero/pedidos_listos_screen.dart';
import '../screens/cajero/pedidos_pendientes_screen.dart';
import '../providers/ui_provider.dart';


/// Layout reutilizable para todas las pantallas de cajero
/// Incluye sidebar colapsable para desktop y drawer para mobile
class CajeroLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final String currentRoute;
  final FloatingActionButton? floatingActionButton;

  const CajeroLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<CajeroLayout> createState() => _CajeroLayoutState();
}

class _CajeroLayoutState extends State<CajeroLayout> {
  bool _isSidebarExpanded = false;

  @override
  void initState() {
    super.initState();
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

  void _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
   Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uiProvider = context.watch<UiProvider>(); 
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: !isDesktop ? _buildDrawer(context, authProvider) : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: isDesktop
            ? IconButton(
                icon: Icon(
                  uiProvider.isSidebarExpanded ? Icons.menu_open : Icons.menu,
                  color: Colors.white70,
                ),
                onPressed: () => context.read<UiProvider>().toggleSidebar(),
                tooltip: uiProvider.isSidebarExpanded ? 'Colapsar menú' : 'Expandir menú',
              )
            : null,
        automaticallyImplyLeading: !isDesktop,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: widget.actions ?? [],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          if (isDesktop) _buildCollapsibleSidebar(context, authProvider, uiProvider),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  // Sidebar colapsable
  Widget _buildCollapsibleSidebar(BuildContext context, AuthProvider authProvider,  UiProvider uiProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: uiProvider.isSidebarExpanded ? 280 : 72,
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
            padding: EdgeInsets.all(uiProvider.isSidebarExpanded ? 24 : 16),
            child: Column(
              children: [
                Container(
                  width: uiProvider.isSidebarExpanded ? 60 : 40,
                  height: uiProvider.isSidebarExpanded ? 60 : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(uiProvider.isSidebarExpanded ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: uiProvider.isSidebarExpanded ? 32 : 24,
                  ),
                ),
                if (uiProvider.isSidebarExpanded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'POS Cajero',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A Vera Pizza',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
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
                if (uiProvider.isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MENÚ PRINCIPAL',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  isActive: widget.currentRoute == '/cajero/dashboard',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CajeroDashboardScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.add_shopping_cart,
                  title: 'Nuevo Pedido',
                  isActive: widget.currentRoute == '/cajero/crear-pedido',
                  isExpanded: uiProvider.isSidebarExpanded,
                  isAction: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearPedidoScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                if (uiProvider.isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'PEDIDOS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                Consumer<PedidoProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        _SidebarItem(
                          icon: Icons.pending_actions,
                          title: 'Pendientes',
                          isActive: widget.currentRoute == '/cajero/pendientes',
                          isExpanded: uiProvider.isSidebarExpanded,
                          badge: provider.getCantidadPedidosPendientes(),
                          badgeColor: AppColors.warning,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosPendientesScreen(),
                              ),
                            );
                          },
                        ),
                        _SidebarItem(
                          icon: Icons.restaurant,
                          title: 'En Cocina',
                          isActive: widget.currentRoute == '/cajero/en-cocina',
                          isExpanded: uiProvider.isSidebarExpanded,
                          badge: provider.getCantidadPedidosEnPreparacion(),
                          badgeColor: AppColors.info,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosEnCocinaScreen(),
                              ),
                            );
                          },
                        ),
                        _SidebarItem(
                          icon: Icons.check_circle,
                          title: 'Listos',
                          isActive: widget.currentRoute == '/cajero/listos',
                          isExpanded: uiProvider.isSidebarExpanded,
                          badge: provider.getCantidadPedidosListos(),
                          badgeColor: AppColors.success,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosListosScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),
                if (uiProvider.isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'GESTIÓN',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                _SidebarItem(
                  icon: Icons.history,
                  title: 'Historial',
                  isActive: widget.currentRoute == '/cajero/historial',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistorialPedidosScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.receipt_long,
                  title: 'Todos los Pedidos',
                  isActive: widget.currentRoute == '/cajero/todos',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TodosPedidosScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer con usuario
          if (uiProvider.isSidebarExpanded)
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
                  // Información del usuario
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            (authProvider.userName?.substring(0, 1) ?? 'C').toUpperCase(),
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
                                authProvider.userName ?? 'Cajero',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Cajero',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Actualizar datos
                            context.read<PedidoProvider>().loadPedidosPendientes();
                            context.read<PedidoProvider>().loadPedidosEnPreparacion();
                            context.read<PedidoProvider>().loadPedidosByEstado(EstadoPedido.LISTO);
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Actualizar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0xFF2A2A2A)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.logout, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
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
                      (authProvider.userName?.substring(0, 1) ?? 'C').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                    onPressed: () {
                      context.read<PedidoProvider>().loadPedidosPendientes();
                      context.read<PedidoProvider>().loadPedidosEnPreparacion();
                      context.read<PedidoProvider>().loadPedidosByEstado(EstadoPedido.LISTO);
                    },
                    tooltip: 'Actualizar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
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

  // Drawer para mobile
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, Color(0xFFE65100)],
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
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'POS Cajero',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userName ?? 'Cajero',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  isActive: widget.currentRoute == '/cajero/dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/cajero/dashboard') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CajeroDashboardScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.add_shopping_cart,
                  title: 'Nuevo Pedido',
                  isAction: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearPedidoScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                Consumer<PedidoProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        _DrawerItem(
                          icon: Icons.pending_actions,
                          title: 'Pendientes',
                          badge: provider.getCantidadPedidosPendientes(),
                          isActive: widget.currentRoute == '/cajero/pendientes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosListScreen(
                                  estado: EstadoPedido.PENDIENTE,
                                ),
                              ),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.restaurant,
                          title: 'En Cocina',
                          badge: provider.getCantidadPedidosEnPreparacion(),
                          isActive: widget.currentRoute == '/cajero/en-cocina',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosListScreen(
                                  estado: EstadoPedido.EN_PREPARACION,
                                ),
                              ),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.check_circle,
                          title: 'Listos',
                          badge: provider.getCantidadPedidosListos(),
                          isActive: widget.currentRoute == '/cajero/listos',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PedidosListScreen(
                                  estado: EstadoPedido.LISTO,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                _DrawerItem(
                  icon: Icons.history,
                  title: 'Historial',
                  isActive: widget.currentRoute == '/cajero/historial',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PedidosListScreen(),
                      ),
                    );
                  },
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
}

// Sidebar Item
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isExpanded;
  final bool isAction;
  final int? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.isExpanded,
    this.isAction = false,
    this.badge,
    this.badgeColor,
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
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isAction
                    ? AppColors.secondary.withOpacity(0.15)
                    : isActive
                    ? AppColors.secondary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAction
                      ? AppColors.secondary.withOpacity(0.4)
                      : isActive
                      ? AppColors.secondary.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: 
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showText = isExpanded && constraints.maxWidth > 180;

                    return(
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                icon,
                                color: isAction
                                    ? AppColors.secondary
                                    : isActive
                                    ? AppColors.secondary
                                    : Colors.white70,
                                size: 24,
                              ),
                              if (badge != null && badge! > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: badgeColor ?? AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      badge! > 9 ? '9+' : badge.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (showText) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: isAction
                                      ? AppColors.secondary
                                      : isActive
                                      ? AppColors.secondary
                                      : Colors.white70,
                                  fontWeight: isAction || isActive ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    );
                      
                  }
                )
              
              
              
              
              
              
            ),
          ),
        ),
      ),
    );
  }
}

// Drawer Item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isAction;
  final bool isDestructive;
  final int? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.isAction = false,
    this.isDestructive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isAction || isActive
        ? AppColors.secondary
        : Colors.white70;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color),
          if (badge != null && badge! > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badge! > 9 ? '9+' : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isActive || isAction ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}