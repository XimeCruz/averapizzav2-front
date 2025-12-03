// lib/presentation/screens/admin/productos/sabor_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/receta_provider.dart';
import '../../../providers/insumo_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import 'precio_dialog.dart';
import '../recetas/receta_form_dialog.dart';

class SaborDetailScreen extends StatefulWidget {
  final SaborPizza sabor;

  const SaborDetailScreen({super.key, required this.sabor});

  @override
  State<SaborDetailScreen> createState() => _SaborDetailScreenState();
}

class _SaborDetailScreenState extends State<SaborDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productoProvider = context.read<ProductoProvider>();
    final recetaProvider = context.read<RecetaProvider>();
    final insumoProvider = context.read<InsumoProvider>();

    await Future.wait([
      productoProvider.loadPresentaciones(),
      productoProvider.loadPreciosBySabor(widget.sabor.id),
      recetaProvider.loadRecetaBySabor(widget.sabor.id),
      insumoProvider.loadInsumos(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sabor.nombre),
            if (widget.sabor.descripcion != null)
              Text(
                widget.sabor.descripcion!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Precios', icon: Icon(Icons.attach_money)),
            Tab(text: 'Receta', icon: Icon(Icons.menu_book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PreciosTab(saborId: widget.sabor.id),
          _RecetaTab(saborId: widget.sabor.id),
        ],
      ),
    );
  }
}

// ========== TAB DE PRECIOS ==========
class _PreciosTab extends StatelessWidget {
  final int saborId;

  const _PreciosTab({required this.saborId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<PrecioSaborPresentacion>>(
          future: provider.loadPreciosBySabor(saborId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: 'Cargando precios...');
            }

            final precios = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadPreciosBySabor(saborId);
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPrecioDialog(context, saborId, null);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Precio'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  Expanded(
                    child: precios.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay precios configurados',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              _showPrecioDialog(context, saborId, null);
                            },
                            child: const Text('Agregar Primer Precio'),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: precios.length,
                      itemBuilder: (context, index) {
                        final precio = precios[index];
                        return _PrecioCard(
                          precio: precio,
                          onEdit: () {
                            _showPrecioDialog(context, saborId, precio);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPrecioDialog(BuildContext context, int saborId, PrecioSaborPresentacion? precio) {
    showDialog(
      context: context,
      builder: (context) => PrecioDialog(
        saborId: saborId,
        precio: precio,
      ),
    ).then((value) {
      if (value == true) {
        context.read<ProductoProvider>().loadPreciosBySabor(saborId);
      }
    });
  }
}

class _PrecioCard extends StatelessWidget {
  final PrecioSaborPresentacion precio;
  final VoidCallback onEdit;

  const _PrecioCard({
    required this.precio,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final presentacion = precio.presentacion;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_pizza,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          presentacion?.tipo.name ?? 'Presentación',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          presentacion?.getNombre() ?? '',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Bs. ${precio.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (presentacion?.usaPeso ?? false)
              const Text(
                'por kg',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

// ========== TAB DE RECETA ==========
class _RecetaTab extends StatelessWidget {
  final int saborId;

  const _RecetaTab({required this.saborId});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecetaProvider>(
      builder: (context, recetaProvider, _) {
        final receta = recetaProvider.recetaActual;
        final detalles = receta?.detalles ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await recetaProvider.loadRecetaBySabor(saborId);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showRecetaDialog(context, saborId, detalles);
                  },
                  icon: Icon(detalles.isEmpty ? Icons.add : Icons.edit),
                  label: Text(
                    detalles.isEmpty ? 'Crear Receta' : 'Editar Receta',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: detalles.isEmpty ? AppColors.primary : AppColors.accent,
                  ),
                ),
              ),
              Expanded(
                child: detalles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay receta configurada',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agrega insumos para crear la receta',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _showRecetaDialog(context, saborId, []);
                        },
                        child: const Text('Crear Receta'),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    return _InsumoRecetaCard(detalle: detalle);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecetaDialog(BuildContext context, int saborId, List<dynamic> detallesActuales) {
    showDialog(
      context: context,
      builder: (context) => RecetaFormDialog(
        saborId: saborId,
        detallesActuales: detallesActuales,
      ),
    ).then((value) {
      if (value == true) {
        context.read<RecetaProvider>().loadRecetaBySabor(saborId);
      }
    });
  }
}

class _InsumoRecetaCard extends StatelessWidget {
  final dynamic detalle;

  const _InsumoRecetaCard({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: AppColors.secondary,
          ),
        ),
        title: Text(
          detalle.insumoNombre ?? 'Insumo #${detalle.insumoId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${detalle.cantidad} ${detalle.unidadMedida ?? ''}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}