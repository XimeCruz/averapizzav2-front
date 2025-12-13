// lib/presentation/screens/admin/clientes/clientes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/usuario_model.dart';
import '../../../providers/usuario_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../layouts/admin_layout.dart';
import 'cliente_detail_dialog.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _searchQuery = '';
  bool _soloActivos = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientes();
    });
  }

  Future<void> _loadClientes() async {
    await context.read<UsuarioProvider>().loadClientes();
  }

  void _toggleEstadoCliente(Usuario cliente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          cliente.activo ? 'Desactivar Cliente' : 'Activar Cliente',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          cliente.activo
              ? '¿Desactivar a ${cliente.nombre}? No podrá realizar pedidos.'
              : '¿Activar a ${cliente.nombre}? Podrá realizar pedidos nuevamente.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cliente.activo ? AppColors.error : AppColors.success,
            ),
            child: Text(cliente.activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<UsuarioProvider>();
      final success = await provider.toggleEstadoCliente(cliente.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cliente ${cliente.activo ? 'desactivado' : 'activado'} correctamente'
                : provider.errorMessage ?? 'Error al cambiar estado',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (success) _loadClientes();
    }
  }

  void _showClienteDetail(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => ClienteDetailDialog(cliente: cliente),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Gestión de Clientes',
      currentRoute: '/admin/clientes',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClientes,
          tooltip: 'Refrescar',
        ),
      ],
      child: Column(
        children: [
          // Filtros superiores
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nombre o correo...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Filtro de estado
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          label: 'Activos',
                          isSelected: _soloActivos,
                          onTap: () {
                            setState(() {
                              _soloActivos = true;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _FilterButton(
                          label: 'Todos',
                          isSelected: !_soloActivos,
                          onTap: () {
                            setState(() {
                              _soloActivos = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Estadísticas rápidas
          Consumer<UsuarioProvider>(
            builder: (context, provider, _) {
              final totalClientes = provider.clientes.length;
              final activos = provider.clientes.where((c) => c.activo).length;
              final inactivos = totalClientes - activos;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1A1A1A),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.people,
                      label: 'Total',
                      value: totalClientes.toString(),
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: 'Activos',
                      value: activos.toString(),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.block,
                      label: 'Inactivos',
                      value: inactivos.toString(),
                      color: AppColors.error,
                    ),
                  ],
                ),
              );
            },
          ),

          // Lista de clientes
          Expanded(
            child: Consumer<UsuarioProvider>(
              builder: (context, provider, _) {
                if (provider.status == UsuarioStatus.loading) {
                  return const LoadingWidget(message: 'Cargando clientes...');
                }

                if (provider.status == UsuarioStatus.error) {
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
                          provider.errorMessage ?? 'Error al cargar clientes',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadClientes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                var clientes = provider.clientes;

                // Filtrar solo clientes (excluir admin y cajero)
                //clientes = clientes.where((c) => c.tieneRol(RolNombre.CLIENTE)).toList();

                // Filtrar por estado
                if (_soloActivos) {
                  clientes = clientes.where((c) => c.activo).toList();
                }

                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  clientes = clientes.where((cliente) {
                    final query = _searchQuery.toLowerCase();
                    return cliente.nombre.toLowerCase().contains(query) ||
                        cliente.correo.toLowerCase().contains(query);
                  }).toList();
                }

                if (clientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron clientes'
                              : 'No hay clientes registrados',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadClientes,
                  color: AppColors.secondary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return _ClienteCard(
                        cliente: cliente,
                        onTap: () => _showClienteDetail(cliente),
                        onToggleEstado: () => _toggleEstadoCliente(cliente),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Usuario cliente;
  final VoidCallback onTap;
  final VoidCallback onToggleEstado;

  const _ClienteCard({
    required this.cliente,
    required this.onTap,
    required this.onToggleEstado,
  });

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    cliente.nombre.isNotEmpty
                        ? cliente.nombre[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cliente.correo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Estado y acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cliente.activo
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cliente.activo
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cliente.activo ? Icons.check_circle : Icons.block,
                          size: 12,
                          color: cliente.activo ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cliente.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cliente.activo ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: const Color(0xFF2A2A2A),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onTap();
                          break;
                        case 'toggle':
                          onToggleEstado();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Ver Detalles', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              cliente.activo ? Icons.block : Icons.check_circle,
                              size: 20,
                              color: cliente.activo ? AppColors.error : AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cliente.activo ? 'Desactivar' : 'Activar',
                              style: TextStyle(
                                color: cliente.activo ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}