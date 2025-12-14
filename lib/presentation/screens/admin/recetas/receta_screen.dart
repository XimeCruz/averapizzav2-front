// lib/presentation/screens/admin/recetas/recetas_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/receta_provider.dart';
import '../../../providers/insumo_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../layouts/admin_layout.dart';
import 'receta_form_dialog.dart';

class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});

  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  String _searchQuery = '';
  int? _selectedProductoId;
  List<Producto> _productos = [];
  List<SaborPizza> _sabores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productoProvider = context.read<ProductoProvider>();
    final insumoProvider = context.read<InsumoProvider>();

    await Future.wait([
      productoProvider.loadProductos(),
      insumoProvider.loadInsumos(),
    ]);

    if (mounted) {
      setState(() {
        _productos = productoProvider.productos
            .where((p) => p.tieneSabores && p.tipoProducto == TipoProducto.PIZZA)
            .toList();

        if (_productos.isNotEmpty && _selectedProductoId == null) {
          _selectedProductoId = _productos.first.id;
          _loadSabores();
        }
      });
    }
  }

  Future<void> _loadSabores() async {
    if (_selectedProductoId == null) return;

    await context.read<ProductoProvider>().loadSaboresByProducto(_selectedProductoId!);

    if (mounted) {
      setState(() {
        _sabores = context.read<ProductoProvider>().sabores;
      });
    }
  }

  void _showRecetaDialog(SaborPizza sabor) async {
    final recetaProvider = context.read<RecetaProvider>();

    // Cargar la receta actual del sabor
    await recetaProvider.loadRecetaBySabor(sabor.id);

    if (!mounted) return;

    final receta = recetaProvider.recetaActual;
    final detalles = receta?.detalles ?? [];

    showDialog(
      context: context,
      builder: (context) => RecetaFormDialog(
        saborId: sabor.id,
        detallesActuales: detalles,
      ),
    ).then((value) {
      if (value == true) {
        // Recargar después de guardar
        _loadSabores();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Gestión de Recetas',
      currentRoute: '/admin/recetas',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
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
                // Selector de producto
                if (_productos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedProductoId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        hint: const Text('Selecciona un producto'),
                        items: _productos.map((producto) {
                          return DropdownMenuItem(
                            value: producto.id,
                            child: Row(
                              children: [
                                const Icon(Icons.local_pizza, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(producto.nombre),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductoId = value;
                            _loadSabores();
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Barra de búsqueda
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar sabor...',
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
              ],
            ),
          ),

          // Lista de sabores
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.status == ProductoStatus.loading) {
                  return const LoadingWidget(message: 'Cargando sabores...');
                }

                if (_productos.isEmpty) {
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
                            Icons.local_pizza,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No hay productos con sabores',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea productos tipo Pizza primero',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var saboresFiltrados = _sabores;

                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  saboresFiltrados = saboresFiltrados.where((sabor) {
                    return sabor.nombre
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (saboresFiltrados.isEmpty) {
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
                            Icons.restaurant_menu,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron sabores'
                              : 'No hay sabores para este producto',
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
                  onRefresh: _loadSabores,
                  color: AppColors.secondary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: saboresFiltrados.length,
                    itemBuilder: (context, index) {
                      final sabor = saboresFiltrados[index];
                      return _SaborRecetaCard(
                        sabor: sabor,
                        onConfigureReceta: () => _showRecetaDialog(sabor),
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

class _SaborRecetaCard extends StatefulWidget {
  final SaborPizza sabor;
  final VoidCallback onConfigureReceta;

  const _SaborRecetaCard({
    required this.sabor,
    required this.onConfigureReceta,
  });

  @override
  State<_SaborRecetaCard> createState() => _SaborRecetaCardState();
}

class _SaborRecetaCardState extends State<_SaborRecetaCard> {
  bool _isLoading = false;
  bool _hasReceta = false;
  int _insumosCount = 0;

  @override
  void initState() {
    super.initState();
    _checkReceta();
  }

  Future<void> _checkReceta() async {
    setState(() => _isLoading = true);

    final recetaProvider = context.read<RecetaProvider>();
    await recetaProvider.loadRecetaBySabor(widget.sabor.id);

    if (mounted) {
      final receta = recetaProvider.recetaActual;
      setState(() {
        _hasReceta = receta != null && receta.detalles.isNotEmpty;
        _insumosCount = receta?.detalles.length ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if(_isLoading){
      return Padding(padding:   const EdgeInsets.only(bottom: 12),
        child: LoadingWidget(message: 'Cargando receta de ${widget.sabor.nombre}...'),
      );
    }

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
        onTap: widget.onConfigureReceta,
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
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sabor.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.sabor.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.sabor.descripcion!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _hasReceta
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _hasReceta
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasReceta ? Icons.check_circle : Icons.warning_amber,
                            size: 14,
                            color: _hasReceta ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _hasReceta ? 'Configurada' : 'Sin receta',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _hasReceta ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (_hasReceta) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_insumosCount ${_insumosCount == 1 ? 'insumo' : 'insumos'} en la receta',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onConfigureReceta,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _hasReceta
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hasReceta
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasReceta ? Icons.edit : Icons.add_circle_outline,
                        size: 18,
                        color: _hasReceta ? AppColors.accent : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasReceta ? 'Editar Receta' : 'Crear Receta',
                        style: TextStyle(
                          fontSize: 13,
                          color: _hasReceta ? AppColors.accent : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}