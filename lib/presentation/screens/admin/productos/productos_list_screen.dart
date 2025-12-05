// lib/presentation/screens/admin/productos/productos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../layouts/admin_layout.dart';
import 'producto_form_screen.dart';
import 'sabores_list_screen.dart';

class ProductosListScreen extends StatefulWidget {
  const ProductosListScreen({super.key});

  @override
  State<ProductosListScreen> createState() => _ProductosListScreenState();
}

class _ProductosListScreenState extends State<ProductosListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductos();
    });
  }

  Future<void> _loadProductos() async {
    await context.read<ProductoProvider>().loadProductos();
  }

  void _deleteProducto(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar "$nombre"?\n\nEsto también eliminará todos sus sabores asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = context.read<ProductoProvider>();
              final success = await provider.deleteProducto(id);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Producto eliminado correctamente'
                        : provider.errorMessage ?? 'Error al eliminar',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );

              if (success) _loadProductos();
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
    return AdminLayout(
      title: 'Gestión de Productos',
      currentRoute: '/admin/productos',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductoFormScreen(),
            ),
          ).then((value) {
            if (value == true) _loadProductos();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
        backgroundColor: AppColors.secondary,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProductos,
          tooltip: 'Refrescar',
        ),
      ],
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
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
                enabledBorder: OutlineInputBorder(
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
          ),

          // Lista de productos
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.status == ProductoStatus.loading) {
                  return const LoadingWidget(message: 'Cargando productos...');
                }

                if (provider.status == ProductoStatus.error) {
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
                          provider.errorMessage ?? 'Error al cargar productos',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProductos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                var productos = provider.productos;

                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  productos = productos.where((producto) {
                    return producto.nombre
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (productos.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.local_pizza,
                    message: _searchQuery.isNotEmpty
                        ? 'No se encontraron productos'
                        : 'No hay productos registrados',
                    actionLabel: 'Agregar Producto',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductoFormScreen(),
                        ),
                      ).then((value) {
                        if (value == true) _loadProductos();
                      });
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadProductos,
                  color: AppColors.secondary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return _ProductoCard(
                        producto: producto,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductoFormScreen(producto: producto),
                            ),
                          ).then((value) {
                            if (value == true) _loadProductos();
                          });
                        },
                        onDelete: () => _deleteProducto(producto.id, producto.nombre),
                        onViewSabores: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SaboresListScreen(producto: producto),
                            ),
                          );
                        },
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

class _ProductoCard extends StatelessWidget {
  final dynamic producto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewSabores;

  const _ProductoCard({
    required this.producto,
    required this.onEdit,
    required this.onDelete,
    required this.onViewSabores,
  });

  IconData _getIconByTipo(TipoProducto tipo) {
    switch (tipo) {
      case TipoProducto.PIZZA:
        return Icons.local_pizza;
      case TipoProducto.BEBIDA:
        return Icons.local_drink;
      case TipoProducto.OTRO:
        return Icons.fastfood;
    }
  }

  Color _getColorByTipo(TipoProducto tipo) {
    switch (tipo) {
      case TipoProducto.PIZZA:
        return AppColors.primary;
      case TipoProducto.BEBIDA:
        return AppColors.info;
      case TipoProducto.OTRO:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorByTipo(producto.tipoProducto);

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
        onTap: producto.tieneSabores ? onViewSabores : onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconByTipo(producto.tipoProducto),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                producto.tipoProducto.toString().split('.').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (producto.tieneSabores) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 12,
                                      color: AppColors.accent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Con Sabores',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                        case 'sabores':
                          onViewSabores();
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
                      if (producto.tieneSabores)
                        const PopupMenuItem(
                          value: 'sabores',
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_menu, size: 20, color: Colors.white70),
                              SizedBox(width: 8),
                              Text('Ver Sabores', style: TextStyle(color: Colors.white)),
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
                            Text('Eliminar', style: TextStyle(color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (producto.tieneSabores) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: onViewSabores,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Gestionar Sabores',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para estado vacío
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}