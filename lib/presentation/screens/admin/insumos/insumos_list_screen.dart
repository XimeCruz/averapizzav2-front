// lib/presentation/screens/admin/insumos/insumos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/insumo_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/insumo/ajustar_stock_dialog.dart';
import 'insumo_form_screen.dart';

class InsumosListScreen extends StatefulWidget {
  const InsumosListScreen({super.key});

  @override
  State<InsumosListScreen> createState() => _InsumosListScreenState();
}

class _InsumosListScreenState extends State<InsumosListScreen> {
  String _searchQuery = '';
  bool _showOnlyBajoStock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsumos();
    });
  }

  Future<void> _loadInsumos() async {
    await context.read<InsumoProvider>().loadInsumos();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Insumos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsumos,
          ),
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
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Insumo'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar insumo...',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Solo bajo stock'),
                        selected: _showOnlyBajoStock,
                        onSelected: (value) {
                          setState(() {
                            _showOnlyBajoStock = value;
                          });
                        },
                        avatar: _showOnlyBajoStock
                            ? const Icon(Icons.check, size: 18)
                            : null,
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
                  return const LoadingWidget();
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
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInsumos,
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
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    message: _searchQuery.isNotEmpty
                        ? 'No se encontraron insumos'
                        : 'No hay insumos registrados',
                    actionLabel: 'Agregar Insumo',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InsumoFormScreen(),
                        ),
                      ).then((value) {
                        if (value == true) _loadInsumos();
                      });
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadInsumos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
    );
  }
}

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
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
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock',
                        child: Row(
                          children: [
                            Icon(Icons.inventory, size: 20),
                            SizedBox(width: 8),
                            Text('Ajustar Stock'),
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
                            color: AppColors.textSecondary,
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${insumo.stockMinimo.toStringAsFixed(2)} ${insumo.unidadMedida}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                  backgroundColor: Colors.grey.shade200,
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