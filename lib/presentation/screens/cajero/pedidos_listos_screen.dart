
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cajero_layout.dart';
import '../../providers/pedido_provider.dart';
import 'crear_pedido_screen.dart';

class PedidosListosScreen extends StatefulWidget {
  const PedidosListosScreen({super.key});

  @override
  State<PedidosListosScreen> createState() => _PedidosListosScreenState();
}

class _PedidosListosScreenState extends State<PedidosListosScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<PedidoProvider>().loadPedidosByEstado(EstadoPedido.LISTO);
  }

  void _verDetalles(dynamic pedido) {
    showDialog(
      context: context,
      builder: (context) => _PedidoDetalleDialog(pedido: pedido),
    );
  }

  void _entregar(dynamic pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Entregar Pedido',
        message: '¿Marcar el pedido #${pedido.id} como entregado?',
        confirmText: 'Entregar',
        icon: Icons.done_all,
        color: AppColors.success,
      ),
    );

    if (confirmed != true || !mounted) return;

    // Aquí iría la lógica para cambiar el estado
    // await context.read<PedidoProvider>().cambiarEstado(pedido.id, EstadoPedido.ENTREGADO);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${pedido.id} entregado'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _loadData();
  }

  void _reimprimirTicket(dynamic pedido) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reimprimiendo ticket del pedido #${pedido.id}'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CajeroLayout(
      title: 'Pedidos Listos',
      currentRoute: '/cajero/listos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadData,
          tooltip: 'Actualizar',
        ),
      ],
      child: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Lista de pedidos
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                if (provider.status == PedidoStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.success),
                  );
                }

                final pedidos = provider.pedidos
                    .where((p) => p.estado == EstadoPedido.LISTO)
                    .where((p) => _searchQuery.isEmpty ||
                    p.id.toString().contains(_searchQuery))
                    .toList();

                if (pedidos.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  backgroundColor: const Color(0xFF1A1A1A),
                  color: AppColors.success,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: pedidos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return _PedidoCard(
                        pedido: pedido,
                        statusColor: AppColors.success,
                        statusIcon: Icons.check_circle,
                        statusText: 'Listo',
                        showPulse: true,
                        onVerDetalles: () => _verDetalles(pedido),
                        actions: [
                          _PedidoAction(
                            icon: Icons.done_all,
                            label: 'Entregar',
                            color: AppColors.success,
                            isPrimary: true,
                            onTap: () => _entregar(pedido),
                          ),
                          _PedidoAction(
                            icon: Icons.print,
                            label: 'Reimprimir',
                            color: AppColors.info,
                            onTap: () => _reimprimirTicket(pedido),
                          ),
                        ],
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por número de pedido...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white60),
            onPressed: () {
              setState(() => _searchQuery = '');
            },
          )
              : null,
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.success, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos listos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos terminados aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}


class _PedidoCard extends StatelessWidget {
  final dynamic pedido;
  final Color statusColor;
  final IconData statusIcon;
  final String statusText;
  final bool showTimer;
  final bool showPulse;
  final VoidCallback onVerDetalles;
  final List<_PedidoAction> actions;

  const _PedidoCard({
    required this.pedido,
    required this.statusColor,
    required this.statusIcon,
    required this.statusText,
    this.showTimer = false,
    this.showPulse = false,
    required this.onVerDetalles,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showPulse ? statusColor : const Color(0xFF2A2A2A),
          width: showPulse ? 2 : 1,
        ),
        boxShadow: showPulse
            ? [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Column(
        children: [
          // Header del pedido
          InkWell(
            onTap: onVerDetalles,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Indicador de estado
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info del pedido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pedido #${pedido.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 16, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${pedido.items?.length ?? 0} items',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              showTimer ? '15 min' : TimeOfDay.now().format(context),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${pedido.total?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Separador
          Divider(
            height: 1,
            color: const Color(0xFF2A2A2A),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: actions
                  .map((action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: action.isPrimary
                      ? ElevatedButton.icon(
                    onPressed: action.onTap,
                    icon: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                      : OutlinedButton.icon(
                    onPressed: action.onTap,
                    icon: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(
                        color: action.color.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoAction {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PedidoAction({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });
}

// Dialog de confirmación
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final IconData icon;
  final Color color;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog de detalles del pedido
class _PedidoDetalleDialog extends StatelessWidget {
  final dynamic pedido;

  const _PedidoDetalleDialog({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    child: Text(
                      'Pedido #${pedido.id}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                      'Items del Pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Aquí irían los items del pedido
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Text(
                        'Pizza Muzzarella x2\nCoca Cola 500ml x1',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
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
                            '\$${pedido.total?.toStringAsFixed(2) ?? '0.00'}',
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
}