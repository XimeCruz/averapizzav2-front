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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sabor.nombre,
              style: const TextStyle(color: Colors.white),
            ),
            if (widget.sabor.descripcion != null)
              Text(
                widget.sabor.descripcion!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white54,
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
              color: AppColors.secondary,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Column(
                children: [
                  // Botón agregar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: const Color(0xFF1A1A1A),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPrecioDialog(context, saborId, null);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Precio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  Expanded(
                    child: precios.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.attach_money,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No hay precios configurados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega un precio para comenzar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showPrecioDialog(context, saborId, null);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Primer Precio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_pizza,
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
                      presentacion?.tipo.name ?? 'Presentación',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presentacion?.getNombre() ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bs. ${precio.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (presentacion?.usaPeso ?? false)
                    Text(
                      'por kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
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
          color: AppColors.secondary,
          backgroundColor: const Color(0xFF2A2A2A),
          child: Column(
            children: [
              // Botón crear/editar receta
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFF1A1A1A),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showRecetaDialog(context, saborId, detalles);
                  },
                  icon: Icon(detalles.isEmpty ? Icons.add : Icons.edit),
                  label: Text(
                    detalles.isEmpty ? 'Crear Receta' : 'Editar Receta',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: detalles.isEmpty ? AppColors.primary : AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              Expanded(
                child: detalles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No hay receta configurada',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega insumos para crear la receta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showRecetaDialog(context, saborId, []);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Receta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detalle.insumoNombre ?? 'Insumo #${detalle.insumoId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${detalle.cantidad} ${detalle.unidadMedida ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}