// lib/presentation/screens/cocina/cocina_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pedido_model.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../auth/login_screen.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
    });

    // Auto-refresh cada 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _loadPedidos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPedidos() async {
    final provider = context.read<PedidoProvider>();
    await Future.wait([
      provider.loadPedidosPendientes(),
      provider.loadPedidosEnPreparacion(),
    ]);
  }

  void _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cocina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPedidos,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.userName ?? 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      authProvider.userEmail ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.pending_actions)),
            Tab(text: 'En Preparación', icon: Icon(Icons.restaurant)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PendientesTab(),
          _EnPreparacionTab(),
        ],
      ),
    );
  }
}

// ========== TAB PENDIENTES ==========
class _PendientesTab extends StatelessWidget {
  const _PendientesTab();

  Future<void> _tomarPedido(BuildContext context, int pedidoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Tomar este pedido para preparar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tomar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<PedidoProvider>();
    final success = await provider.tomarPedido(pedidoId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pedido tomado. ¡A cocinar!'
              : provider.errorMessage ?? 'Error al tomar pedido',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const LoadingWidget(message: 'Cargando pedidos...');
        }

        final pedidos = provider.pedidosPendientes;

        if (pedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.success.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Todo al día!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No hay pedidos pendientes',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadPedidosPendientes();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return _CocinaCard(
                pedido: pedido,
                onAction: () => _tomarPedido(context, pedido.id!),
                actionLabel: 'Tomar Pedido',
                actionIcon: Icons.play_arrow,
                actionColor: AppColors.info,
              );
            },
          ),
        );
      },
    );
  }
}

// ========== TAB EN PREPARACIÓN ==========
class _EnPreparacionTab extends StatelessWidget {
  const _EnPreparacionTab();

  Future<void> _marcarListo(BuildContext context, int pedidoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Marcar este pedido como listo?'),
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
            child: const Text('Marcar Listo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<PedidoProvider>();
    final success = await provider.marcarListo(pedidoId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '¡Pedido listo para entregar!'
              : provider.errorMessage ?? 'Error al marcar listo',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const LoadingWidget(message: 'Cargando pedidos...');
        }

        final pedidos = provider.pedidosEnPreparacion;

        if (pedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin pedidos en preparación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los pedidos tomados aparecerán aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadPedidosEnPreparacion();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return _CocinaCard(
                pedido: pedido,
                onAction: () => _marcarListo(context, pedido.id!),
                actionLabel: 'Marcar Listo',
                actionIcon: Icons.check_circle,
                actionColor: AppColors.success,
              );
            },
          ),
        );
      },
    );
  }
}

// ========== CARD DE COCINA ==========
class _CocinaCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onAction;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;

  const _CocinaCard({
    required this.pedido,
    required this.onAction,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
  });

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

  String _getTiempoTranscurrido() {
    final now = DateTime.now();
    final diferencia = now.difference(pedido.fechaHora);

    if (diferencia.inMinutes < 1) {
      return 'Hace menos de 1 min';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else {
      return 'Hace ${diferencia.inHours}h ${diferencia.inMinutes % 60}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final tiempoTranscurrido = _getTiempoTranscurrido();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconByTipo(pedido.tipoServicio),
                    color: Colors.white,
                    size: 28,
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
                              fontSize: 22,
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
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tiempoTranscurrido,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${pedido.getTipoServicioTexto()} • ${dateFormat.format(pedido.fechaHora)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                ...pedido.detalles.map((detalle) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${detalle.cantidad}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detalle.getDescripcion(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}