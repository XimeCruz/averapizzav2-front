// lib/presentation/screens/cajero/pedidos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pedido_model.dart';
import '../../providers/pedido_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../layouts/admin_layout.dart';
import 'pedido_detail_dialog.dart';

class PedidosListScreen extends StatefulWidget {
  final EstadoPedido? estado;

  const PedidosListScreen({super.key, this.estado});

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> {
  EstadoPedido? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _selectedEstado = widget.estado;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
    });
  }

  Future<void> _loadPedidos() async {
    final provider = context.read<PedidoProvider>();

    if (_selectedEstado != null) {
      await provider.loadPedidosByEstado(_selectedEstado!);
    } else {
      await provider.loadPedidos();
    }
  }

  String _getTitleByEstado() {
    if (_selectedEstado == null) return 'Todos los Pedidos';

    switch (_selectedEstado!) {
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
    if (_selectedEstado == null) return provider.pedidos;

    switch (_selectedEstado!) {
      case EstadoPedido.PENDIENTE:
        return provider.pedidosPendientes;
      case EstadoPedido.EN_PREPARACION:
        return provider.pedidosEnPreparacion;
      case EstadoPedido.LISTO:
        return provider.pedidosListos;
      default:
        return provider.pedidos.where((p) => p.estado == _selectedEstado).toList();
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
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirmar Entrega',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Marcar este pedido como entregado?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (success) _loadPedidos();
  }

  Future<void> _cancelarPedido(int pedidoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirmar Cancelación',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de cancelar este pedido?',
          style: TextStyle(color: Colors.white70),
        ),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (success) _loadPedidos();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Gestión de Pedidos',
      currentRoute: '/admin/pedidos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPedidos,
          tooltip: 'Refrescar',
        ),
      ],
      child: Column(
        children: [
          // Filtros por estado
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _EstadoChip(
                    label: 'Todos',
                    isSelected: _selectedEstado == null,
                    count: context.watch<PedidoProvider>().pedidos.length,
                    color: AppColors.info,
                    onTap: () {
                      setState(() {
                        _selectedEstado = null;
                      });
                      _loadPedidos();
                    },
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(
                    label: 'Pendientes',
                    isSelected: _selectedEstado == EstadoPedido.PENDIENTE,
                    count: context.watch<PedidoProvider>().pedidosPendientes.length,
                    color: AppColors.warning,
                    onTap: () {
                      setState(() {
                        _selectedEstado = EstadoPedido.PENDIENTE;
                      });
                      _loadPedidos();
                    },
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(
                    label: 'En Preparación',
                    isSelected: _selectedEstado == EstadoPedido.EN_PREPARACION,
                    count: context.watch<PedidoProvider>().pedidosEnPreparacion.length,
                    color: AppColors.accent,
                    onTap: () {
                      setState(() {
                        _selectedEstado = EstadoPedido.EN_PREPARACION;
                      });
                      _loadPedidos();
                    },
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(
                    label: 'Listos',
                    isSelected: _selectedEstado == EstadoPedido.LISTO,
                    count: context.watch<PedidoProvider>().pedidosListos.length,
                    color: AppColors.primary,
                    onTap: () {
                      setState(() {
                        _selectedEstado = EstadoPedido.LISTO;
                      });
                      _loadPedidos();
                    },
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(
                    label: 'Entregados',
                    isSelected: _selectedEstado == EstadoPedido.ENTREGADO,
                    count: context.watch<PedidoProvider>().pedidos
                        .where((p) => p.estado == EstadoPedido.ENTREGADO).length,
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _selectedEstado = EstadoPedido.ENTREGADO;
                      });
                      _loadPedidos();
                    },
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(
                    label: 'Cancelados',
                    isSelected: _selectedEstado == EstadoPedido.CANCELADO,
                    count: context.watch<PedidoProvider>().pedidos
                        .where((p) => p.estado == EstadoPedido.CANCELADO).length,
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _selectedEstado = EstadoPedido.CANCELADO;
                      });
                      _loadPedidos();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Lista de pedidos
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                if (provider.status == PedidoStatus.loading) {
                  return const LoadingWidget(message: 'Cargando pedidos...');
                }

                final pedidos = _getPedidos(provider);

                if (pedidos.isEmpty) {
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
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No hay pedidos en este estado',
                          style: TextStyle(
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
                  onRefresh: _loadPedidos,
                  color: AppColors.secondary,
                  backgroundColor: const Color(0xFF2A2A2A),
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
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _EstadoChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estadoColor.withOpacity(0.5),
                                ),
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

              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
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
                      Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        dateFormat.format(pedido.fechaHora),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (pedido.detalles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pedido.detalles.length} producto(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
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
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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