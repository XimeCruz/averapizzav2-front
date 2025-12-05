// lib/presentation/layouts/admin_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/clientes/clientes_screen.dart';
import '../screens/admin/configuracion/configuracion_screen.dart';
import '../screens/admin/recetas/receta_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/insumos/insumos_list_screen.dart';
import '../screens/admin/productos/productos_list_screen.dart';
import '../screens/cajero/pedidos_list_screen.dart';
import '../screens/admin/reportes/reportes_screen.dart';

/// Layout reutilizable para todas las pantallas de administrador
/// Incluye sidebar colapsable para desktop y drawer para mobile
class AdminLayout extends StatefulWidget {
  final Widget child;
  final String title;
  //final IconData? titleIcon;
  final List<Widget>? actions;
  final String currentRoute; // Para saber qué item está activo
  final FloatingActionButton? floatingActionButton;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
    //this.titleIcon,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
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
            // if (widget.titleIcon != null) ...[
            //   Icon(widget.titleIcon, color: Colors.white70),
            //   const SizedBox(width: 12),
            // ],
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: widget.actions ?? [],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          // Sidebar para desktop
          if (isDesktop) _buildCollapsibleSidebar(context, authProvider),

          // Contenido principal
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  // Sidebar colapsable
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
                  isActive: widget.currentRoute == '/admin/dashboard',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventario',
                  isActive: widget.currentRoute == '/admin/inventario',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InsumosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.local_pizza,
                  title: 'Productos',
                  isActive: widget.currentRoute == '/admin/productos',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.category_outlined,
                  title: 'Recetas',
                  isActive: widget.currentRoute == '/admin/recetas',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecetasScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  isActive: widget.currentRoute == '/admin/clientes',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientesScreen(),
                      ),
                    );
                  },
                ),
                // _SidebarItem(
                //   icon: Icons.person_outline,
                //   title: 'Empleados',
                //   isActive: widget.currentRoute == '/admin/empleados',
                //   isExpanded: _isSidebarExpanded,
                //   onTap: () {},
                // ),
                _SidebarItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pedidos',
                  isActive: widget.currentRoute == '/admin/pedidos',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PedidosListScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  isActive: widget.currentRoute == '/admin/configuracion',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracionScreen(),
                      ),
                    );
                  },
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
                  isActive: widget.currentRoute == '/admin/reportes',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
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

          // Footer con usuario
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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isActive: widget.currentRoute == '/admin/dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/admin/dashboard') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventario',
                  isActive: widget.currentRoute == '/admin/inventario',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/admin/inventario') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InsumosListScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_pizza,
                  title: 'Productos',
                  isActive: widget.currentRoute == '/admin/productos',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/admin/productos') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductosListScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pedidos',
                  isActive: widget.currentRoute == '/admin/pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/admin/pedidos') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PedidosListScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.assessment_outlined,
                  title: 'Reportes',
                  isActive: widget.currentRoute == '/admin/reportes',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/admin/reportes') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportesScreen(),
                        ),
                      );
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  isActive: widget.currentRoute == '/admin/configuracion',
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
                  horizontal: isExpanded ? 16 : 8, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.secondary.withOpacity(0.3)
                      : Colors.transparent,
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
                        color:
                        isActive ? AppColors.secondary : Colors.white70,
                        fontSize: 14,
                        fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
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

// Drawer Item
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
        ? AppColors.secondary
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
      selectedTileColor: AppColors.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}