// lib/presentation/screens/admin/insumos/insumos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../layouts/admin_layout.dart';
import '../../../providers/insumo_provider.dart';
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
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Confirmar Eliminación',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar "$nombre"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
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
                  behavior: SnackBarBehavior.floating,
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return AdminLayout(
      title: 'Gestión de Inventario',
      //titleIcon: Icons.inventory_2,
      currentRoute: '/admin/inventario',
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadInsumos,
        ),
      ],
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