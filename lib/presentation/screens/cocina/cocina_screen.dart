// lib/presentation/screens/cocina/cocina_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPedidos();

    // Auto-refresh cada 15 segundos
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _loadPedidos();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadPedidos() async {
    final provider = context.read<PedidoProvider>();
    await Future.wait([
      provider.loadPedidosPendientes(),
      provider.loadPedidosEnPreparacion(),
      provider.loadPedidosByEstado(EstadoPedido.LISTO),
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cocina',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadPedidos,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white70),
            color: const Color(0xFF2A2A2A),
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
                      authProvider.userName ?? 'Cocinero',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      authProvider.userEmail ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
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
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                final count = provider.getCantidadPedidosPendientes();
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_actions, size: 20),
                      const SizedBox(width: 8),
                      const Text('Nuevas'),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                final count = provider.getCantidadPedidosEnPreparacion();
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 20),
                      const SizedBox(width: 8),
                      const Text('En Cocina'),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdenesNuevasTab(onRefresh: _loadPedidos),
          _EnPreparacionTab(onRefresh: _loadPedidos),
          _HistorialTab(
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
            },
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
// TAB: ÓRDENES NUEVAS
// ============================================================================

class _OrdenesNuevasTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const _OrdenesNuevasTab({required this.onRefresh});

  Future<void> _tomarPedido(BuildContext context, dynamic pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Tomar Pedido',
        message: '¿Comenzar a preparar el pedido #${pedido.id}?',
        confirmText: 'Comenzar',
        icon: Icons.play_arrow,
        color: AppColors.info,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Aquí iría la lógica para cambiar el estado
    // await context.read<PedidoProvider>().tomarPedido(pedido.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${pedido.id} en preparación'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        final pedidos = provider.pedidos
            .where((p) => p.estado == EstadoPedido.PENDIENTE)
            .toList();

        pedidos.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        if (pedidos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: '¡Todo al día!',
            subtitle: 'No hay órdenes nuevas',
            color: AppColors.success,
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
              final esRetrasado = _esPedidoRetrasado(pedido);

              return _OrdenCard(
                pedido: pedido,
                esRetrasado: esRetrasado,
                onTomar: () => _tomarPedido(context, pedido),
              );
            },
          ),
        );
      },
    );
  }

  bool _esPedidoRetrasado(dynamic pedido) {
    // Considerar retrasado si tiene más de 15 minutos
    final now = DateTime.now();
    // En producción usarías: pedido.fechaCreacion
    final tiempoTranscurrido = now.difference(DateTime.now().subtract(const Duration(minutes: 20)));
    return tiempoTranscurrido.inMinutes > 15;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.5)),
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
}

// ============================================================================
// TAB: EN PREPARACIÓN
// ============================================================================

class _EnPreparacionTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EnPreparacionTab({required this.onRefresh});

  Future<void> _marcarListo(BuildContext context, dynamic pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Marcar como Listo',
        message: '¿El pedido #${pedido.id} está terminado?',
        confirmText: 'Marcar Listo',
        icon: Icons.check_circle,
        color: AppColors.success,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Aquí iría la lógica para cambiar el estado
    // await context.read<PedidoProvider>().marcarListo(pedido.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Pedido #${pedido.id} listo para entregar!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Notificar',
          textColor: Colors.white,
          onPressed: () {
            // Notificar al cajero
          },
        ),
      ),
    );

    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        if (provider.status == PedidoStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }

        final pedidos = provider.pedidos
            .where((p) => p.estado == EstadoPedido.EN_PREPARACION)
            .toList();

        if (pedidos.isEmpty) {
          return _buildEmptyState();
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
              return _EnPreparacionCard(
                pedido: pedido,
                onMarcarListo: () => _marcarListo(context, pedido),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin pedidos en cocina',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos tomados aparecerán aquí',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
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

class _HistorialTab extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _HistorialTab({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(20),
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
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white60),
                onPressed: () => onSearchChanged(''),
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
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),

        // Lista
        Expanded(
          child: Consumer<PedidoProvider>(
            builder: (context, provider, _) {
              var pedidos = provider.pedidos
                  .where((p) =>
              p.estado == EstadoPedido.LISTO ||
                  p.estado == EstadoPedido.ENTREGADO)
                  .toList();

              if (searchQuery.isNotEmpty) {
                pedidos = pedidos
                    .where((p) => p.id.toString().contains(searchQuery))
                    .toList();
              }

              pedidos.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

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
                      Text(
                        searchQuery.isNotEmpty
                            ? 'No se encontraron pedidos'
                            : 'Sin pedidos finalizados',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pedidos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return _HistorialCard(pedido: pedido);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGETS DE TARJETAS
// ============================================================================

class _OrdenCard extends StatefulWidget {
  final dynamic pedido;
  final bool esRetrasado;
  final VoidCallback onTomar;

  const _OrdenCard({
    required this.pedido,
    required this.esRetrasado,
    required this.onTomar,
  });

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.esRetrasado) {
      _controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..repeat(reverse: true);
    } else {
      _controller = AnimationController(vsync: this);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.esRetrasado
                  ? AppColors.error.withOpacity(0.3 + (_controller.value * 0.7))
                  : const Color(0xFF2A2A2A),
              width: widget.esRetrasado ? 2 : 1,
            ),
            boxShadow: widget.esRetrasado
                ? [
              BoxShadow(
                color: AppColors.error.withOpacity(_controller.value * 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.esRetrasado
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.esRetrasado ? AppColors.error : AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
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
                                'Pedido #${widget.pedido.id}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (widget.esRetrasado) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'URGENTE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${TimeOfDay.now().format(context)} • ${widget.pedido.items?.length ?? 0} items',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items del pedido
                    Text(
                      'Productos a Preparar:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aquí irían los items reales del pedido
                    _buildItemPedido(
                      cantidad: 2,
                      nombre: 'Pizza Muzzarella',
                      tipo: 'REDONDA',
                      observaciones: 'Sin cebolla',
                    ),
                    _buildItemPedido(
                      cantidad: 1,
                      nombre: 'Pizza Napolitana',
                      tipo: 'PESO',
                      observaciones: null,
                    ),

                    const SizedBox(height: 20),

                    // Botón de acción
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onTomar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Comenzar a Preparar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemPedido({
    required int cantidad,
    required String nombre,
    required String tipo,
    String? observaciones,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${cantidad}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tipo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (observaciones != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      observaciones,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnPreparacionCard extends StatelessWidget {
  final dynamic pedido;
  final VoidCallback onMarcarListo;

  const _EnPreparacionCard({
    required this.pedido,
    required this.onMarcarListo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'En preparación • 10 min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Items (simulados)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    children: [
                      _buildSimpleItem('2x Pizza Muzzarella - REDONDA'),
                      const SizedBox(height: 8),
                      _buildSimpleItem('1x Pizza Napolitana - PESO'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botón grande de marcar listo
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: onMarcarListo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 32),
                        SizedBox(width: 16),
                        Text(
                          'Marcar como Listo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildSimpleItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_box_outline_blank,
          size: 20,
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final dynamic pedido;

  const _HistorialCard({required this.pedido});

  Color get _estadoColor {
    return pedido.estado == EstadoPedido.LISTO
        ? AppColors.success
        : AppColors.success.withOpacity(0.7);
  }

  IconData get _estadoIcon {
    return pedido.estado == EstadoPedido.LISTO
        ? Icons.check_circle
        : Icons.done_all;
  }

  String get _estadoTexto {
    return pedido.estado == EstadoPedido.LISTO ? 'Listo' : 'Entregado';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_estadoIcon, color: _estadoColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${pedido.id}',
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
                          color: _estadoColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _estadoTexto,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _estadoColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pedido.items?.length ?? 0} items • ${TimeOfDay.now().format(context)}',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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