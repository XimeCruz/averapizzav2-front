// lib/presentation/screens/admin/insumos/insumos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/insumo_provider.dart';
import '../../../widgets/insumo/ajustar_stock_dialog.dart';
import '../../auth/login_screen.dart';
import '../admin_dashboard_screen.dart';
import '../../cajero/pedidos_list_screen.dart';
import '../productos/productos_list_screen.dart';
import '../reportes/reportes_screen.dart';
import 'insumo_form_screen.dart';

class InsumosListScreen extends StatefulWidget {
  const InsumosListScreen({super.key});

  @override
  State<InsumosListScreen> createState() => _InsumosListScreenState();
}

class _InsumosListScreenState extends State<InsumosListScreen> {
  String _searchQuery = '';
  bool _showOnlyBajoStock = false;
  bool _isSidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsumos();
      final size = MediaQuery.of(context).size;
      if (size.width > 1400) {
        setState(() {
          _isSidebarExpanded = true;
        });
      }
    });
  }

  Future<void> _loadInsumos() async {
    await context.read<InsumoProvider>().loadInsumos();
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

  void _showAjustarStockDialog(int insumoId, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AjustarStockDialog(
        insumoId: insumoId,
        nombreInsumo: nombre,
      ),
    ).then((value) {
      if (value == true) {
        _loadInsumos();
      }
    });
  }

  void _deleteInsumo(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = context.read<InsumoProvider>();
              final success = await provider.deleteInsumo(id);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Insumo eliminado correctamente'
                        : provider.errorMessage ?? 'Error al eliminar',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );

              if (success) _loadInsumos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
        title: const Row(
          children: [
            Text(
              'Gestión de Inventario',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadInsumos,
          ),
          if (isDesktop) const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InsumoFormScreen(),
            ),
          ).then((value) {
            if (value == true) _loadInsumos();
          });
        },
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Insumo'),
      ),
      body: Row(
        children: [
          // Sidebar para desktop
          if (isDesktop) _buildCollapsibleSidebar(context, authProvider),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Barra de búsqueda y filtros
                Container(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF2A2A2A),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar insumo...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white60),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Solo bajo stock'),
                            selected: _showOnlyBajoStock,
                            onSelected: (value) {
                              setState(() {
                                _showOnlyBajoStock = value;
                              });
                            },
                            backgroundColor: const Color(0xFF2A2A2A),
                            selectedColor: AppColors.error.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _showOnlyBajoStock ? AppColors.error : Colors.white70,
                            ),
                            checkmarkColor: AppColors.error,
                            side: BorderSide(
                              color: _showOnlyBajoStock
                                  ? AppColors.error
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de insumos
                Expanded(
                  child: Consumer<InsumoProvider>(
                    builder: (context, provider, _) {
                      if (provider.status == InsumoStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white70),
                        );
                      }

                      if (provider.status == InsumoStatus.error) {
                        return Center(
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
                                provider.errorMessage ?? 'Error al cargar insumos',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadInsumos,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      var insumos = provider.insumos;

                      // Filtrar por búsqueda
                      if (_searchQuery.isNotEmpty) {
                        insumos = insumos.where((insumo) {
                          return insumo.nombre
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      // Filtrar por bajo stock
                      if (_showOnlyBajoStock) {
                        insumos = insumos.where((insumo) => insumo.esBajoStock).toList();
                      }

                      if (insumos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No se encontraron insumos'
                                    : 'No hay insumos registrados',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _loadInsumos,
                        backgroundColor: const Color(0xFF1A1A1A),
                        color: Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.all(isDesktop ? 24 : 16),
                          itemCount: insumos.length,
                          itemBuilder: (context, index) {
                            final insumo = insumos[index];
                            return _InsumoCard(
                              insumo: insumo,
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InsumoFormScreen(insumo: insumo),
                                  ),
                                ).then((value) {
                                  if (value == true) _loadInsumos();
                                });
                              },
                              onDelete: () => _deleteInsumo(insumo.id, insumo.nombre),
                              onAjustarStock: () => _showAjustarStockDialog(
                                insumo.id,
                                insumo.nombre,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                  isActive: false,
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
                  isActive: true,
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.local_pizza,
                  title: 'Productos',
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
                  title: 'Empleados',
                  isExpanded: _isSidebarExpanded,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pedidos',
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventario',
                  isActive: true,
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
                  title: 'Recetas',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'Empleados',
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

// Card de Insumo
class _InsumoCard extends StatelessWidget {
  final dynamic insumo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAjustarStock;

  const _InsumoCard({
    required this.insumo,
    required this.onEdit,
    required this.onDelete,
    required this.onAjustarStock,
  });

  @override
  Widget build(BuildContext context) {
    final esBajoStock = insumo.esBajoStock;
    final porcentaje = insumo.porcentajeStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insumo.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (esBajoStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Bajo Stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unidad: ${insumo.unidadMedida}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: const Color(0xFF2A2A2A),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'stock':
                          onAjustarStock();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Editar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock',
                        child: Row(
                          children: [
                            Icon(Icons.inventory, size: 20, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Ajustar Stock',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Actual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          '${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: esBajoStock ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Mínimo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          '${insumo.stockMinimo.toStringAsFixed(2)} ${insumo.unidadMedida}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: porcentaje / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2A2A2A),
                  color: esBajoStock ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}