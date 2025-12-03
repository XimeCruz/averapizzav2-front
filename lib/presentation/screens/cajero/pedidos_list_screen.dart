// lib/presentation/screens/cajero/pedidos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pedido_model.dart';
import '../../providers/pedido_provider.dart';
import '../../widgets/common/loading_widget.dart';
import 'pedido_detail_dialog.dart';

class PedidosListScreen extends StatefulWidget {
  final EstadoPedido? estado;

  const PedidosListScreen({super.key, this.estado});

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
    });
  }

  Future<void> _loadPedidos() async {
    final provider = context.read<PedidoProvider>();

    if (widget.estado != null) {
      await provider.loadPedidosByEstado(widget.estado!);
    } else {
      await provider.loadPedidos();
    }
  }

  String _getTitleByEstado() {
    if (widget.estado == null) return 'Todos los Pedidos';

    switch (widget.estado!) {
      case EstadoPedido.PENDIENTE:
        return 'Pedidos Pendientes';
      case EstadoPedido.EN_PREPARACION:
        return 'En Preparación';
      case EstadoPedido.LISTO:
        return 'Pedidos Listos';
      case EstadoPedido.ENTREGADO:
        return 'Pedidos Entregados';
      case EstadoPedido.CANCELADO:
        return 'Pedidos Cancelados';
    }
  }

  List<Pedido> _getPedidos(PedidoProvider provider) {
    if (widget.estado == null) return provider.pedidos;

    switch (widget.estado!) {
      case EstadoPedido.PENDIENTE:
        return provider.pedidosPendientes;
      case EstadoPedido.EN_PREPARACION:
        return provider.pedidosEnPreparacion;
      case EstadoPedido.LISTO:
        return provider.pedidosListos;
      default:
        return provider.pedidos.where((p) => p.estado == widget.estado).toList();
    }
  }

  void _showPedidoDetail(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => PedidoDetailDialog(pedido: pedido),
    ).then((value) {
      if (value == true) _loadPedidos();
    });
  }

  Future<void> _entregarPedido(int pedidoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: const Text('¿Marcar este pedido como entregado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<PedidoProvider>();
    final success = await provider.entregarPedido(pedidoId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pedido entregado correctamente'
              : provider.errorMessage ?? 'Error al entregar',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) _loadPedidos();
  }

  Future<void> _cancelarPedido(int pedidoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelación'),
        content: const Text('¿Estás seguro de cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<PedidoProvider>();
    final success = await provider.cancelarPedido(pedidoId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pedido cancelado'
              : provider.errorMessage ?? 'Error al cancelar',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) _loadPedidos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleByEstado()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPedidos,
          ),
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, _) {
          if (provider.status == PedidoStatus.loading) {
            return const LoadingWidget(message: 'Cargando pedidos...');
          }

          final pedidos = _getPedidos(provider);

          if (pedidos.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              message: 'No hay pedidos en este estado',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPedidos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                return _PedidoCard(
                  pedido: pedido,
                  onTap: () => _showPedidoDetail(pedido),
                  onEntregar: pedido.estado == EstadoPedido.LISTO
                      ? () => _entregarPedido(pedido.id!)
                      : null,
                  onCancelar: pedido.estado != EstadoPedido.ENTREGADO &&
                      pedido.estado != EstadoPedido.CANCELADO
                      ? () => _cancelarPedido(pedido.id!)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;
  final VoidCallback? onEntregar;
  final VoidCallback? onCancelar;

  const _PedidoCard({
    required this.pedido,
    required this.onTap,
    this.onEntregar,
    this.onCancelar,
  });

  Color _getColorByEstado(EstadoPedido estado) {
    return AppColors.getColorByEstado(estado.name);
  }

  IconData _getIconByTipo(TipoServicio tipo) {
    switch (tipo) {
      case TipoServicio.MESA:
        return Icons.table_restaurant;
      case TipoServicio.LLEVAR:
        return Icons.shopping_bag;
      case TipoServicio.DELIVERY:
        return Icons.delivery_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getColorByEstado(pedido.estado);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconByTipo(pedido.tipoServicio),
                      color: estadoColor,
                      size: 24,
                    ),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pedido.getEstadoTexto(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: estadoColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pedido.getTipoServicioTexto(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Bs. ${pedido.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        dateFormat.format(pedido.fechaHora),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (pedido.detalles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${pedido.detalles.length} producto(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              if (onEntregar != null || onCancelar != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onEntregar != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEntregar,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Entregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    if (onEntregar != null && onCancelar != null)
                      const SizedBox(width: 8),
                    if (onCancelar != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancelar,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}