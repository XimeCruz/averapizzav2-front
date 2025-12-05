// lib/presentation/screens/cajero/historial_pedidos_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cajero_layout.dart';
import '../../providers/pedido_provider.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  String _searchQuery = '';
  EstadoPedido? _filtroEstado;
  DateTimeRange? _rangoFechas;
  String _ordenarPor = 'reciente'; // reciente, antiguo, monto_mayor, monto_menor

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar todos los pedidos del historial
    await context.read<PedidoProvider>().loadPedidos();
  }

  void _seleccionarRangoFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _rangoFechas = picked;
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _searchQuery = '';
      _filtroEstado = null;
      _rangoFechas = null;
      _ordenarPor = 'reciente';
    });
  }

  void _verDetalles(dynamic pedido) {
    showDialog(
      context: context,
      builder: (context) => _PedidoDetalleDialog(pedido: pedido),
    );
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

  void _mostrarEstadisticas() {
    showDialog(
      context: context,
      builder: (context) => _EstadisticasDialog(
        pedidos: context.read<PedidoProvider>().pedidos,
      ),
    );
  }

  List<dynamic> _filtrarYOrdenarPedidos(List<dynamic> pedidos) {
    var resultado = pedidos;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      resultado = resultado
          .where((p) => p.id.toString().contains(_searchQuery))
          .toList();
    }

    // Filtrar por estado
    if (_filtroEstado != null) {
      resultado = resultado.where((p) => p.estado == _filtroEstado).toList();
    }

    // Filtrar por rango de fechas
    if (_rangoFechas != null) {
      resultado = resultado.where((p) {
        // Aquí deberías usar la fecha real del pedido
        // final fecha = p.fechaCreacion;
        // return fecha.isAfter(_rangoFechas!.start) &&
        //        fecha.isBefore(_rangoFechas!.end);
        return true; // Temporal
      }).toList();
    }

    // Ordenar
    switch (_ordenarPor) {
      case 'reciente':
        resultado.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'antiguo':
        resultado.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'monto_mayor':
        resultado.sort((a, b) => (b.total ?? 0).compareTo(a.total ?? 0));
        break;
      case 'monto_menor':
        resultado.sort((a, b) => (a.total ?? 0).compareTo(b.total ?? 0));
        break;
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return CajeroLayout(
      title: 'Historial de Pedidos',
      currentRoute: '/cajero/historial',
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.white70),
          onPressed: _mostrarEstadisticas,
          tooltip: 'Estadísticas',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadData,
          tooltip: 'Actualizar',
        ),
      ],
      child: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),

          // Chips de filtros activos
          _buildActiveFilters(),

          // Lista de pedidos
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                if (provider.status == PedidoStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  );
                }

                final pedidosFiltrados = _filtrarYOrdenarPedidos(provider.pedidos);

                if (pedidosFiltrados.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  backgroundColor: const Color(0xFF1A1A1A),
                  color: AppColors.secondary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: pedidosFiltrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final pedido = pedidosFiltrados[index];
                      return _HistorialPedidoCard(
                        pedido: pedido,
                        onVerDetalles: () => _verDetalles(pedido),
                        onReimprimir: () => _reimprimirTicket(pedido),
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Búsqueda
          TextField(
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
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),

          // Botones de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtro de estado
                _FilterButton(
                  icon: Icons.filter_list,
                  label: 'Estado',
                  isActive: _filtroEstado != null,
                  onTap: () => _mostrarFiltroEstado(),
                ),
                const SizedBox(width: 8),

                // Filtro de fecha
                _FilterButton(
                  icon: Icons.date_range,
                  label: _rangoFechas == null
                      ? 'Fecha'
                      : '${DateFormat('dd/MM').format(_rangoFechas!.start)} - ${DateFormat('dd/MM').format(_rangoFechas!.end)}',
                  isActive: _rangoFechas != null,
                  onTap: _seleccionarRangoFechas,
                ),
                const SizedBox(width: 8),

                // Ordenar por
                _FilterButton(
                  icon: Icons.sort,
                  label: _obtenerTextoOrden(),
                  isActive: _ordenarPor != 'reciente',
                  onTap: () => _mostrarOpcionesOrden(),
                ),
                const SizedBox(width: 8),

                // Limpiar filtros
                if (_filtroEstado != null ||
                    _rangoFechas != null ||
                    _ordenarPor != 'reciente')
                  TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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

  Widget _buildActiveFilters() {
    final hasFilters = _filtroEstado != null || _rangoFechas != null;
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFF0A0A0A),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_filtroEstado != null)
            Chip(
              label: Text(_obtenerTextoEstado(_filtroEstado!)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _filtroEstado = null);
              },
              backgroundColor: _obtenerColorEstado(_filtroEstado!).withOpacity(0.2),
              deleteIconColor: _obtenerColorEstado(_filtroEstado!),
              labelStyle: TextStyle(
                color: _obtenerColorEstado(_filtroEstado!),
                fontSize: 12,
              ),
            ),
          if (_rangoFechas != null)
            Chip(
              label: Text(
                  '${DateFormat('dd/MM/yy').format(_rangoFechas!.start)} - ${DateFormat('dd/MM/yy').format(_rangoFechas!.end)}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _rangoFechas = null);
              },
              backgroundColor: AppColors.info.withOpacity(0.2),
              deleteIconColor: AppColors.info,
              labelStyle: const TextStyle(
                color: AppColors.info,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No hay pedidos en el historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos completados aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltroEstado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filtrar por Estado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions, color: AppColors.warning),
              title: const Text('Pendientes', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filtroEstado = EstadoPedido.PENDIENTE);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: AppColors.info),
              title: const Text('En Cocina', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filtroEstado = EstadoPedido.EN_PREPARACION);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Listos', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filtroEstado = EstadoPedido.LISTO);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: AppColors.success),
              title: const Text('Entregados', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filtroEstado = EstadoPedido.ENTREGADO);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('Cancelados', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filtroEstado = EstadoPedido.CANCELADO);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _mostrarOpcionesOrden() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ordenar por',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.secondary),
              title: const Text('Más reciente', style: TextStyle(color: Colors.white)),
              trailing: _ordenarPor == 'reciente'
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _ordenarPor = 'reciente');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.secondary),
              title: const Text('Más antiguo', style: TextStyle(color: Colors.white)),
              trailing: _ordenarPor == 'antiguo'
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _ordenarPor = 'antiguo');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: AppColors.secondary),
              title: const Text('Monto mayor', style: TextStyle(color: Colors.white)),
              trailing: _ordenarPor == 'monto_mayor'
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _ordenarPor = 'monto_mayor');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: AppColors.secondary),
              title: const Text('Monto menor', style: TextStyle(color: Colors.white)),
              trailing: _ordenarPor == 'monto_menor'
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _ordenarPor = 'monto_menor');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  String _obtenerTextoOrden() {
    switch (_ordenarPor) {
      case 'reciente':
        return 'Reciente';
      case 'antiguo':
        return 'Antiguo';
      case 'monto_mayor':
        return 'Mayor monto';
      case 'monto_menor':
        return 'Menor monto';
      default:
        return 'Ordenar';
    }
  }

  String _obtenerTextoEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.PENDIENTE:
        return 'Pendiente';
      case EstadoPedido.EN_PREPARACION:
        return 'En Cocina';
      case EstadoPedido.LISTO:
        return 'Listo';
      case EstadoPedido.ENTREGADO:
        return 'Entregado';
      case EstadoPedido.CANCELADO:
        return 'Cancelado';
    }
  }

  Color _obtenerColorEstado(EstadoPedido estado) {
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

// ============================================================================
// PANTALLA: TODOS LOS PEDIDOS
// ============================================================================

class TodosPedidosScreen extends StatefulWidget {
  const TodosPedidosScreen({super.key});

  @override
  State<TodosPedidosScreen> createState() => _TodosPedidosScreenState();
}

class _TodosPedidosScreenState extends State<TodosPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<PedidoProvider>().loadPedidos();
  }

  void _verDetalles(dynamic pedido) {
    showDialog(
      context: context,
      builder: (context) => _PedidoDetalleDialog(pedido: pedido),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CajeroLayout(
      title: 'Todos los Pedidos',
      currentRoute: '/cajero/todos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _loadData,
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
              isScrollable: true,
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: Colors.white60,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Pendientes'),
                Tab(text: 'En Cocina'),
                Tab(text: 'Listos'),
                Tab(text: 'Entregados'),
                Tab(text: 'Cancelados'),
              ],
            ),
          ),

          // Barra de búsqueda
          Container(
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
                hintText: 'Buscar pedido...',
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
                  borderSide:
                  const BorderSide(color: AppColors.secondary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Contenido de tabs
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, provider, _) {
                if (provider.status == PedidoStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPedidosList(provider.pedidos, null),
                    _buildPedidosList(
                        provider.pedidos, EstadoPedido.PENDIENTE),
                    _buildPedidosList(
                        provider.pedidos, EstadoPedido.EN_PREPARACION),
                    _buildPedidosList(provider.pedidos, EstadoPedido.LISTO),
                    _buildPedidosList(
                        provider.pedidos, EstadoPedido.ENTREGADO),
                    _buildPedidosList(
                        provider.pedidos, EstadoPedido.CANCELADO),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosList(List<dynamic> todosPedidos, EstadoPedido? estado) {
    var pedidos = todosPedidos;

    // Filtrar por estado si se especifica
    if (estado != null) {
      pedidos = pedidos.where((p) => p.estado == estado).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      pedidos = pedidos
          .where((p) => p.id.toString().contains(_searchQuery))
          .toList();
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      backgroundColor: const Color(0xFF1A1A1A),
      color: AppColors.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
          return _TodosPedidosCard(
            pedido: pedido,
            onTap: () => _verDetalles(pedido),
          );
        },
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
// WIDGETS COMPARTIDOS
// ============================================================================

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? AppColors.secondary : Colors.white70,
        backgroundColor:
        isActive ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
        side: BorderSide(
          color: isActive
              ? AppColors.secondary
              : const Color(0xFF2A2A2A),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _HistorialPedidoCard extends StatelessWidget {
  final dynamic pedido;
  final VoidCallback onVerDetalles;
  final VoidCallback onReimprimir;

  const _HistorialPedidoCard({
    required this.pedido,
    required this.onVerDetalles,
    required this.onReimprimir,
  });

  Color get _estadoColor {
    switch (pedido.estado) {
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
      default:
        return Colors.grey;
    }
  }

  IconData get _estadoIcon {
    switch (pedido.estado) {
      case EstadoPedido.PENDIENTE:
        return Icons.pending_actions;
      case EstadoPedido.EN_PREPARACION:
        return Icons.restaurant;
      case EstadoPedido.LISTO:
        return Icons.check_circle;
      case EstadoPedido.ENTREGADO:
        return Icons.done_all;
      case EstadoPedido.CANCELADO:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String get _estadoTexto {
    switch (pedido.estado) {
      case EstadoPedido.PENDIENTE:
        return 'Pendiente';
      case EstadoPedido.EN_PREPARACION:
        return 'En Cocina';
      case EstadoPedido.LISTO:
        return 'Listo';
      case EstadoPedido.ENTREGADO:
        return 'Entregado';
      case EstadoPedido.CANCELADO:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: InkWell(
        onTap: onVerDetalles,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador de estado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_estadoIcon, color: _estadoColor, size: 24),
              ),
              const SizedBox(width: 16),

              // Info
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
                    const SizedBox(height: 6),
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

              // Total y acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${pedido.total?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: onReimprimir,
                    icon: const Icon(Icons.print, size: 20),
                    color: AppColors.info,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Reimprimir',
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

class _TodosPedidosCard extends StatelessWidget {
  final dynamic pedido;
  final VoidCallback onTap;

  const _TodosPedidosCard({
    required this.pedido,
    required this.onTap,
  });

  Color get _estadoColor {
    switch (pedido.estado) {
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
      default:
        return Colors.grey;
    }
  }

  IconData get _estadoIcon {
    switch (pedido.estado) {
      case EstadoPedido.PENDIENTE:
        return Icons.pending_actions;
      case EstadoPedido.EN_PREPARACION:
        return Icons.restaurant;
      case EstadoPedido.LISTO:
        return Icons.check_circle;
      case EstadoPedido.ENTREGADO:
        return Icons.done_all;
      case EstadoPedido.CANCELADO:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String get _estadoTexto {
    switch (pedido.estado) {
      case EstadoPedido.PENDIENTE:
        return 'Pendiente';
      case EstadoPedido.EN_PREPARACION:
        return 'En Cocina';
      case EstadoPedido.LISTO:
        return 'Listo';
      case EstadoPedido.ENTREGADO:
        return 'Entregado';
      case EstadoPedido.CANCELADO:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Barra de estado
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _estadoColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Info
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
                        Icon(_estadoIcon, size: 16, color: _estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          _estadoTexto,
                          style: TextStyle(
                            fontSize: 12,
                            color: _estadoColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pedido.items?.length ?? 0} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Total
              Text(
                '\$${pedido.total?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog de detalles
class _PedidoDetalleDialog extends StatelessWidget {
  final dynamic pedido;

  const _PedidoDetalleDialog({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles del pedido',
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
                      child: Text(
                        'Items, notas, etc...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
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

// Dialog de estadísticas
class _EstadisticasDialog extends StatelessWidget {
  final List<dynamic> pedidos;

  const _EstadisticasDialog({required this.pedidos});

  @override
  Widget build(BuildContext context) {
    final totalVentas = pedidos.fold<double>(
        0.0, (sum, p) => sum + (p.total ?? 0));
    final promedioVenta = pedidos.isEmpty ? 0.0 : totalVentas / pedidos.length;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estadísticas',
                    style: TextStyle(
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
            const SizedBox(height: 24),
            _StatItem(
              label: 'Total de Pedidos',
              value: '${pedidos.length}',
              icon: Icons.receipt_long,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            _StatItem(
              label: 'Total Ventas',
              value: '\$${totalVentas.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            _StatItem(
              label: 'Promedio por Pedido',
              value: '\$${promedioVenta.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: AppColors.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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