// lib/presentation/layouts/cliente_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cliente/cliente_home_screen.dart';
import '../screens/cliente/carrito_screen.dart';
import '../screens/cliente/mis_pedidos_screen.dart';
import '../screens/cliente/perfil_screen.dart';
import '../providers/ui_provider.dart';

/// Layout reutilizable para todas las pantallas de cliente
/// Incluye sidebar colapsable para desktop y drawer para mobile
class ClienteLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final String currentRoute;
  final FloatingActionButton? floatingActionButton;
  final bool showCartButton;

  const ClienteLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
    this.showCartButton = true,
  });

  @override
  State<ClienteLayout> createState() => _ClienteLayoutState();
}

class _ClienteLayoutState extends State<ClienteLayout> {
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
    final size = MediaQuery.of(context).size;
    final uiProvider = context.watch<UiProvider>();
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
        actions: [
          ...?widget.actions,
          if (widget.showCartButton)
            Consumer<CarritoProvider>(
              builder: (context, carritoProvider, _) {
                final itemCount = carritoProvider.cantidadItems;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CarritoScreen(),
                          ),
                        );
                      },
                      tooltip: 'Carrito',
                    ),
                    if (itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            itemCount > 9 ? '9+' : '$itemCount',
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
                );
              },
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          // Sidebar para desktop
          if (isDesktop) _buildCollapsibleSidebar(context, authProvider, uiProvider),

          // Contenido principal
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  // Sidebar colapsable
  Widget _buildCollapsibleSidebar(BuildContext context, AuthProvider authProvider, UiProvider uiProvider) {
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
                    Icons.local_pizza,
                    color: Colors.white,
                    size: uiProvider.isSidebarExpanded ? 32 : 24,
                  ),
                ),
                if (uiProvider.isSidebarExpanded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'A Vera Pizza',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¡Bienvenido!',
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
                      'MENÚ',
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
                  isActive: widget.currentRoute == '/cliente/home',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClienteHomeScreen(),
                      ),
                    );
                  },
                ),
                // _SidebarItem(
                //   icon: Icons.local_pizza,
                //   title: 'Pizzas por Peso',
                //   isActive: widget.currentRoute == '/cliente/pizzas-peso',
                //   isExpanded: _isSidebarExpanded,
                //   onTap: () {
                //     // TODO: Navegar a pizzas por peso
                //   },
                // ),
                // _SidebarItem(
                //   icon: Icons.local_pizza_outlined,
                //   title: 'Pizzas Redondas',
                //   isActive: widget.currentRoute == '/cliente/pizzas-redondas',
                //   isExpanded: _isSidebarExpanded,
                //   onTap: () {
                //     // TODO: Navegar a pizzas redondas
                //   },
                // ),
                // _SidebarItem(
                //   icon: Icons.restaurant,
                //   title: 'Pizzas en Bandeja',
                //   isActive: widget.currentRoute == '/cliente/pizzas-bandeja',
                //   isExpanded: _isSidebarExpanded,
                //   onTap: () {
                //     // TODO: Navegar a pizzas en bandeja
                //   },
                // ),
                // _SidebarItem(
                //   icon: Icons.local_drink,
                //   title: 'Bebidas',
                //   isActive: widget.currentRoute == '/cliente/bebidas',
                //   isExpanded: _isSidebarExpanded,
                //   onTap: () {
                //     // TODO: Navegar a bebidas
                //   },
                // ),

                const SizedBox(height: 8),
                if (uiProvider.isSidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MI CUENTA',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                Consumer<CarritoProvider>(
                  builder: (context, carritoProvider, _) {
                    return _SidebarItem(
                      icon: Icons.shopping_cart,
                      title: 'Carrito',
                      isActive: widget.currentRoute == '/cliente/carrito',
                      isExpanded: uiProvider.isSidebarExpanded,
                      badge: carritoProvider.cantidadItems,
                      badgeColor: AppColors.secondary,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CarritoScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.receipt_long,
                  title: 'Mis Pedidos',
                  isActive: widget.currentRoute == '/cliente/mis-pedidos',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisPedidosScreen(),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.person,
                  title: 'Mi Perfil',
                  isActive: widget.currentRoute == '/cliente/perfil',
                  isExpanded: uiProvider.isSidebarExpanded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerfilScreen(),
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
                            (authProvider.userName?.substring(0, 1) ?? 'U').toUpperCase(),
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
                                'Cliente',
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

                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cerrar Sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
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
                      (authProvider.userName?.substring(0, 1) ?? 'U').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  isActive: widget.currentRoute == '/cliente/home',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != '/cliente/home') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClienteHomeScreen(),
                        ),
                      );
                    }
                  },
                ),
                // const Divider(color: Color(0xFF2A2A2A)),
                // _DrawerItem(
                //   icon: Icons.local_pizza,
                //   title: 'Pizzas por Peso',
                //   isActive: widget.currentRoute == '/cliente/pizzas-peso',
                //   onTap: () {
                //     Navigator.pop(context);
                //     // TODO: Navegar a pizzas por peso
                //   },
                // ),
                // _DrawerItem(
                //   icon: Icons.local_pizza_outlined,
                //   title: 'Pizzas Redondas',
                //   isActive: widget.currentRoute == '/cliente/pizzas-redondas',
                //   onTap: () {
                //     Navigator.pop(context);
                //     // TODO: Navegar a pizzas redondas
                //   },
                // ),
                // _DrawerItem(
                //   icon: Icons.restaurant,
                //   title: 'Pizzas en Bandeja',
                //   isActive: widget.currentRoute == '/cliente/pizzas-bandeja',
                //   onTap: () {
                //     Navigator.pop(context);
                //     // TODO: Navegar a pizzas en bandeja
                //   },
                // ),
                // _DrawerItem(
                //   icon: Icons.local_drink,
                //   title: 'Bebidas',
                //   isActive: widget.currentRoute == '/cliente/bebidas',
                //   onTap: () {
                //     Navigator.pop(context);
                //     // TODO: Navegar a bebidas
                //   },
                // ),
                const Divider(color: Color(0xFF2A2A2A)),
                Consumer<CarritoProvider>(
                  builder: (context, carritoProvider, _) {
                    return _DrawerItem(
                      icon: Icons.shopping_cart,
                      title: 'Carrito',
                      badge: carritoProvider.cantidadItems,
                      isActive: widget.currentRoute == '/cliente/carrito',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CarritoScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Mis Pedidos',
                  isActive: widget.currentRoute == '/cliente/mis-pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisPedidosScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.person,
                  title: 'Mi Perfil',
                  isActive: widget.currentRoute == '/cliente/perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerfilScreen(),
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
  final int? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.isExpanded,
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
                        color: isActive ? AppColors.secondary : Colors.white70,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              )
                  : Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      icon,
                      color: isActive ? AppColors.secondary : Colors.white60,
                      size: 24,
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -4,
                      top: -4,
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
  final int? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.isDestructive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isActive
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
                  color: AppColors.secondary,
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