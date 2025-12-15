// lib/presentation/screens/cliente/mis_pedidos_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pedido_model.dart';
import '../../layouts/cliente_layout.dart';
import '../../providers/pedido_provider.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
    _startAutoRefresh();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Cargar datos según el tab seleccionado
      if (_tabController.index == 0) {
        _loadPedidosActivos();
      } else {
        _loadPedidosHistorial();
      }
    }
  }

  void _loadInitialData() {
    // Cargar pedidos activos por defecto (primer tab)
    _loadPedidosActivos();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        // Solo refrescar si estamos en el tab de activos
        if (_tabController.index == 0) {
          _loadPedidosActivos();
        }
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadPedidosActivos() async {
    await context.read<PedidoProvider>().loadPedidosHoyClienteHistorial();
  }

  Future<void> _loadPedidosHistorial() async {
    await context.read<PedidoProvider>().loadPedidosClienteHistorial();
  }

  void _verDetalles(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => _PedidoDetalleDialog(pedido: pedido),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClienteLayout(
      title: 'Mis Pedidos',
      currentRoute: '/cliente/mis-pedidos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: () {
            // Refrescar según el tab actual
            if (_tabController.index == 0) {
              _loadPedidosActivos();
            } else {
              _loadPedidosHistorial();
            }
          },
          tooltip: 'Actualizar',
        ),
      ],
      child: Column(
        children: [
          // Tabs
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 8),
                      Text('Activos'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 20),
                      SizedBox(width: 8),
                      Text('Historial'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PedidosActivosTab(
                  onRefresh: _loadPedidosActivos,
                  onVerDetalles: _verDetalles,
                ),
                _PedidosHistorialTab(
                  onRefresh: _loadPedidosHistorial,
                  onVerDetalles: _verDetalles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ============================================================================
// TAB: PEDIDOS ACTIVOS
// ============================================================================

class _PedidosActivosTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final Function(Pedido) onVerDetalles;

  const _PedidosActivosTab({
    required this.onRefresh,
    required this.onVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        if (provider.status == PedidoStatus.error) {
          return _buildErrorState(
            message: provider.errorMessage ?? 'Error al cargar pedidos',
            onRetry: onRefresh,
          );
        }

        // El backend ya trae solo los pedidos activos (de hoy)
        final pedidos = provider.pedidos;

        if (pedidos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No tienes pedidos activos',
            subtitle: 'Tus pedidos en proceso aparecerán aquí',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          backgroundColor: const Color(0xFF1A1A1A),
          color: AppColors.secondary,
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: pedidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return _PedidoActivoCard(
                pedido: pedido,
                onTap: () => onVerDetalles(pedido),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB: HISTORIAL
// ============================================================================

class _PedidosHistorialTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final Function(Pedido) onVerDetalles;

  const _PedidosHistorialTab({
    required this.onRefresh,
    required this.onVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        if (provider.status == PedidoStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.error.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar historial',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          );
        }

        // El backend ya trae solo el historial (entregados/cancelados)
        final pedidos = provider.pedidos;

        if (pedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin historial de pedidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tus pedidos completados aparecerán aquí',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          backgroundColor: const Color(0xFF1A1A1A),
          color: AppColors.secondary,
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: pedidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return _PedidoHistorialCard(
                pedido: pedido,
                onTap: () => onVerDetalles(pedido),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// CARDS DE PEDIDOS
// ============================================================================

class _PedidoActivoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoActivoCard({
    required this.pedido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estadoInfo = _getEstadoInfo(pedido.estado);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estadoInfo['color'], width: 2),
        boxShadow: [
          BoxShadow(
            color: (estadoInfo['color'] as Color).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (estadoInfo['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: estadoInfo['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    estadoInfo['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estadoInfo['texto'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: estadoInfo['color'],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white60,
                  size: 28,
                ),
              ],
            ),
          ),

          // Contenido
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Timeline de estados
                  _buildTimeline(pedido.estado),

                  const SizedBox(height: 20),

                  // Info del pedido
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bs. ${pedido.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pedido.detalles.length} items',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildTimeline(EstadoPedido estadoActual) {
    final estados = [
      {'estado': EstadoPedido.PENDIENTE, 'texto': 'Recibido'},
      {'estado': EstadoPedido.EN_PREPARACION, 'texto': 'En Cocina'},
      {'estado': EstadoPedido.LISTO, 'texto': 'Listo'},
    ];

    int estadoActualIndex = estados.indexWhere(
          (e) => e['estado'] == estadoActual,
    );

    return Row(
      children: List.generate(estados.length * 2 - 1, (index) {
        if (index.isEven) {
          // Es un paso
          int stepIndex = index ~/ 2;
          bool isCompleted = stepIndex <= estadoActualIndex;
          bool isCurrent = stepIndex == estadoActualIndex;

          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.secondary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  estados[stepIndex]['texto'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          // Es una línea conectora
          int stepIndex = index ~/ 2;
          bool isCompleted = stepIndex < estadoActualIndex;

          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 32),
              color: isCompleted
                  ? AppColors.success
                  : const Color(0xFF2A2A2A),
            ),
          );
        }
      }),
    );
  }

  Map<String, dynamic> _getEstadoInfo(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.PENDIENTE:
        return {
          'color': AppColors.warning,
          'icon': Icons.schedule,
          'texto': 'Pendiente',
        };
      case EstadoPedido.EN_PREPARACION:
        return {
          'color': AppColors.info,
          'icon': Icons.restaurant,
          'texto': 'Preparándose',
        };
      case EstadoPedido.LISTO:
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle,
          'texto': 'Listo para Recoger',
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'texto': 'Desconocido',
        };
    }
  }
}

class _PedidoHistorialCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoHistorialCard({
    required this.pedido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esEntregado = pedido.estado == EstadoPedido.ENTREGADO;
    final color = esEntregado ? AppColors.success : AppColors.error;
    final icon = esEntregado ? Icons.done_all : Icons.cancel;
    final texto = esEntregado ? 'Entregado' : 'Cancelado';

    // Formatear fecha
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(pedido.fechaHora);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pedido #${pedido.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              texto,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${pedido.detalles.length} items • $fecha',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bs. ${pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white60,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DIALOG DE DETALLES
// ============================================================================

class _PedidoDetalleDialog extends StatelessWidget {
  final Pedido pedido;

  const _PedidoDetalleDialog({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${pedido.id}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pedido.getEstadoTexto(),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getEstadoColor(pedido.estado),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items
                    Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        children: pedido.detalles.map((detalle) {
                          final nombreProducto = detalle.productoNombre ?? 'Producto';
                          final subtotal = detalle.subtotal;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildDetailRow(
                              '${detalle.cantidad}x',
                              nombreProducto,
                              'Bs. ${subtotal.toStringAsFixed(2)}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Información adicional
                    Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.schedule,
                            'Fecha',
                            DateFormat('dd/MM/yyyy HH:mm').format(pedido.fechaHora),
                          ),
                          const Divider(height: 24, color: Color(0xFF2A2A2A)),
                          _buildInfoRow(
                            Icons.delivery_dining,
                            'Tipo',
                            pedido.getTipoServicioTexto(),
                          ),
                          const Divider(height: 24, color: Color(0xFF2A2A2A)),
                          _buildInfoRow(
                            Icons.payment,
                            'Pago',
                            pedido.metodoPago.name,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withOpacity(0.2),
                            AppColors.secondary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Bs. ${pedido.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String cantidad, String nombre, String precio) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            cantidad,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            nombre,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          precio,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.PENDIENTE:
        return AppColors.warning;
      case EstadoPedido.EN_PREPARACION:
        return AppColors.info;
      case EstadoPedido.LISTO:
        return AppColors.success;
      case EstadoPedido.ENTREGADO:
        return AppColors.success;
      case EstadoPedido.CANCELADO:
        return AppColors.error;
    }
  }
}