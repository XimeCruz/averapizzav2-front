// lib/presentation/screens/admin/productos/sabores_list_screen.dart

import 'package:avp_frontend/presentation/screens/admin/productos/sabor_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import 'sabor_detail_screen.dart';

class SaboresListScreen extends StatefulWidget {
  final Producto producto;

  const SaboresListScreen({super.key, required this.producto});

  @override
  State<SaboresListScreen> createState() => _SaboresListScreenState();
}

class _SaboresListScreenState extends State<SaboresListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSabores();
    });
  }

  Future<void> _loadSabores() async {
    await context.read<ProductoProvider>().loadSaboresByProducto(widget.producto.id);
  }

  void _deleteSabor(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar el sabor "$nombre"?\n\nEsto también eliminará su receta y precios asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = context.read<ProductoProvider>();
              final success = await provider.deleteSabor(id);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Sabor eliminado correctamente'
                        : provider.errorMessage ?? 'Error al eliminar',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );

              if (success) _loadSabores();
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sabores'),
            Text(
              widget.producto.nombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSabores,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaborFormScreen(producto: widget.producto),
            ),
          ).then((value) {
            if (value == true) _loadSabores();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Sabor'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar sabor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Lista de sabores
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.status == ProductoStatus.loading) {
                  return const LoadingWidget(message: 'Cargando sabores...');
                }

                var sabores = provider.sabores;

                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  sabores = sabores.where((sabor) {
                    return sabor.nombre
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (sabores.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.restaurant_menu,
                    message: _searchQuery.isNotEmpty
                        ? 'No se encontraron sabores'
                        : 'No hay sabores registrados para este producto',
                    actionLabel: 'Agregar Sabor',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaborFormScreen(producto: widget.producto),
                        ),
                      ).then((value) {
                        if (value == true) _loadSabores();
                      });
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadSabores,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sabores.length,
                    itemBuilder: (context, index) {
                      final sabor = sabores[index];
                      return _SaborCard(
                        sabor: sabor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SaborDetailScreen(sabor: sabor),
                            ),
                          ).then((value) {
                            if (value == true) _loadSabores();
                          });
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SaborFormScreen(
                                producto: widget.producto,
                                sabor: sabor,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) _loadSabores();
                          });
                        },
                        onDelete: () => _deleteSabor(sabor.id, sabor.nombre),
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

class _SaborCard extends StatelessWidget {
  final SaborPizza sabor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SaborCard({
    required this.sabor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sabor.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sabor.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            sabor.descripcion!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onTap();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('Ver Detalles'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Toca para ver precios y receta',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}