// lib/presentation/screens/cocina/cocina_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/constants/api_constants.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> {
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Guardar tiempos de inicio de preparación
  final Map<int, DateTime> _tiemposInicio = {};

  @override
  void initState() {
    super.initState();
    _loadPedidos();
    _startAutoRefresh();

    // Actualizar reloj cada segundo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadPedidos();
      }
    });
  }

  Future<void> _loadPedidos() async {
    if (!mounted) return;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Text(
              'COCINA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('HH:mm:ss').format(_currentTime),
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPedidos,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
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
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, _) {
          if (provider.status == PedidoStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          if (provider.status == PedidoStatus.error) {
            return _buildErrorState(provider.errorMessage);
          }

          final pendientes = provider.pedidosPendientes
            ..sort((a, b) => (a.fechaHora).compareTo(b.fechaHora));

          final enPreparacion = provider.pedidosEnPreparacion
            ..sort((a, b) => (a.fechaHora).compareTo(b.fechaHora));

          final listos = provider.pedidosListos
            ..sort((a, b) => (a.fechaHora).compareTo(b.fechaHora));

          return Row(
            children: [
              // COLUMNA: NUEVOS
              Expanded(
                child: _buildColumna(
                  titulo: 'NUEVOS',
                  icono: Icons.fiber_new,
                  color: const Color(0xFF4CAF50),
                  count: pendientes.length,
                  child: pendientes.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.check_circle_outline,
                    title: '¡Todo al día!',
                    subtitle: 'No hay pedidos nuevos',
                    color: const Color(0xFF4CAF50),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pendientes.length,
                    itemBuilder: (context, index) {
                      final pedido = pendientes[index];
                      return _buildPedidoNuevo(
                        context,
                        pedido,
                        provider,
                      );
                    },
                  ),
                ),
              ),

              Container(width: 2, color: const Color(0xFF1B5E20)),

              // COLUMNA: EN PREPARACIÓN
              Expanded(
                child: _buildColumna(
                  titulo: 'EN PREPARACIÓN',
                  icono: Icons.local_fire_department,
                  color: const Color(0xFFFF9800),
                  count: enPreparacion.length,
                  child: enPreparacion.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.restaurant,
                    title: 'Sin pedidos',
                    subtitle: 'En cocina',
                    color: const Color(0xFFFF9800),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: enPreparacion.length,
                    itemBuilder: (context, index) {
                      final pedido = enPreparacion[index];
                      return _buildPedidoEnPreparacion(
                        context,
                        pedido,
                        provider,
                      );
                    },
                  ),
                ),
              ),

              Container(width: 2, color: const Color(0xFF1B5E20)),

              // COLUMNA: LISTOS
              Expanded(
                child: _buildColumna(
                  titulo: 'LISTOS',
                  icono: Icons.check_circle,
                  color: const Color(0xFF2196F3),
                  count: listos.length,
                  child: listos.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Sin pedidos',
                    subtitle: 'Listos',
                    color: const Color(0xFF2196F3),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listos.length,
                    itemBuilder: (context, index) {
                      final pedido = listos[index];
                      return _buildPedidoListo(pedido);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumna({
    required String titulo,
    required IconData icono,
    required Color color,
    required int count,
    required Widget child,
  }) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              border: Border(bottom: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPedidoNuevo(
      BuildContext context,
      dynamic pedido,
      PedidoProvider provider,
      ) {
    final esRetrasado = _esPedidoRetrasado(pedido);
    final color = esRetrasado ? Colors.red : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: esRetrasado ? 2 : 1,
        ),
        boxShadow: esRetrasado
            ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8)]
            : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PEDIDO #${pedido.id}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(pedido.fechaHora),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (esRetrasado) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente y tipo
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600], size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pedido.usuarioNombre ?? 'Cliente',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pedido.getTipoServicioTexto(),
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),

                // Items
                ...pedido.detalles.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${item.cantidad}x',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.getSaboresText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.presentacionNombre ?? 'Presentación',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _iniciarPreparacion(context, pedido, provider),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'INICIAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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

  Widget _buildPedidoEnPreparacion(
      BuildContext context,
      dynamic pedido,
      PedidoProvider provider,
      ) {
    // Guardar tiempo de inicio si no existe
    if (!_tiemposInicio.containsKey(pedido.id)) {
      _tiemposInicio[pedido.id!] = pedido.fechaHora ?? DateTime.now();
    }

    final tiempoTranscurrido = _getTiempoPreparacion(pedido.id!);
    final colorTiempo = _getColorTiempo(pedido.id!);
    const color = Color(0xFFFF9800);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header con temporizador
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PEDIDO #${pedido.id}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(pedido.fechaHora),
                  style: const TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // TEMPORIZADOR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorTiempo,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        tiempoTranscurrido,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                ...pedido.detalles.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${item.cantidad}x',
                              style: const TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.getSaboresText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.presentacionNombre ?? 'Presentación',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _marcarListo(context, pedido, provider),
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'MARCAR LISTO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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

  Widget _buildPedidoListo(dynamic pedido) {
    const color = Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PEDIDO #${pedido.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(pedido.fechaHora),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...pedido.detalles.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${item.cantidad}x',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.getSaboresText(),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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
          Icon(icon, size: 60, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Error desconocido',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPedidos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODOS AUXILIARES

  bool _esPedidoRetrasado(dynamic pedido) {
    try {
      final now = DateTime.now();
      final tiempoTranscurrido = now.difference(pedido.fechaHora);
      return tiempoTranscurrido.inMinutes > 15;
    } catch (e) {
      return false;
    }
  }

  String _getTiempoPreparacion(int pedidoId) {
    if (!_tiemposInicio.containsKey(pedidoId)) {
      return '00:00';
    }

    final inicio = _tiemposInicio[pedidoId]!;
    final diferencia = _currentTime.difference(inicio);
    final minutos = diferencia.inMinutes;
    final segundos = diferencia.inSeconds % 60;

    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  Color _getColorTiempo(int pedidoId) {
    if (!_tiemposInicio.containsKey(pedidoId)) {
      return Colors.green;
    }

    final minutos = _currentTime.difference(_tiemposInicio[pedidoId]!).inMinutes;

    if (minutos < 15) return Colors.green;
    if (minutos < 25) return Colors.orange;
    return Colors.red;
  }

  Future<void> _iniciarPreparacion(
      BuildContext context,
      dynamic pedido,
      PedidoProvider provider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        context,
        title: 'Iniciar Preparación',
        message: '¿Comenzar a preparar el pedido #${pedido.id}?',
        confirmText: 'Iniciar',
        icon: Icons.play_arrow,
        color: const Color(0xFF4CAF50),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.tomarPedido(pedido.id!);
      _tiemposInicio[pedido.id!] = DateTime.now();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #${pedido.id} en preparación'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _marcarListo(
      BuildContext context,
      dynamic pedido,
      PedidoProvider provider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        context,
        title: 'Marcar como Listo',
        message: '¿El pedido #${pedido.id} está terminado?',
        confirmText: 'Marcar Listo',
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.marcarListo(pedido.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Pedido #${pedido.id} listo!'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmText,
        required IconData icon,
        required Color color,
      }) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Icon(icon, size: 40, color: color),
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
                        borderRadius: BorderRadius.circular(8),
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
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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