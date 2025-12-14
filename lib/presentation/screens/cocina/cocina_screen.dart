// lib/presentation/screens/cocina/cocina_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/detalle_pedido_model.dart';
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
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'A VERA PIZZA - COCINA',
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
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm:ss').format(_currentTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
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
              // COLUMNA 1: NUEVAS
              Expanded(
                child: _buildColumna(
                  titulo: 'NUEVAS',
                  icono: Icons.fiber_new,
                  color: const Color(0xFF4CAF50),
                  count: pendientes.length,
                  child: pendientes.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.check_circle_outline,
                    title: '¡Todo al día!',
                    color: const Color(0xFF4CAF50),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pendientes.length,
                    itemBuilder: (context, index) {
                      final pedido = pendientes[index];
                      return _buildPedidoNuevoCard(
                        context,
                        pedido,
                        provider,
                      );
                    },
                  ),
                ),
              ),

              Container(width: 2, color: const Color(0xFF1B5E20)),

              // COLUMNA 2: EN COCINA
              Expanded(
                child: _buildColumna(
                  titulo: 'EN COCINA',
                  icono: Icons.local_fire_department,
                  color: const Color(0xFFFF9800),
                  count: enPreparacion.length,
                  child: enPreparacion.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.restaurant,
                    title: 'Sin pedidos',
                    color: const Color(0xFFFF9800),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: enPreparacion.length,
                    itemBuilder: (context, index) {
                      final pedido = enPreparacion[index];
                      return _buildPedidoEnCocinaCard(
                        context,
                        pedido,
                        provider,
                      );
                    },
                  ),
                ),
              ),

              Container(width: 2, color: const Color(0xFF1B5E20)),

              // COLUMNA 3: LISTOS
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
                    color: const Color(0xFF2196F3),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listos.length,
                    itemBuilder: (context, index) {
                      final pedido = listos[index];
                      return _buildPedidoListoCard(pedido);
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
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  // CARD: PEDIDO NUEVO (Compacto)
  Widget _buildPedidoNuevoCard(
      BuildContext context,
      dynamic pedido,
      PedidoProvider provider,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PEDIDO #${pedido.id}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(pedido.fechaHora),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Cliente y tipo
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pedido.usuarioNombre ?? 'Cliente',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
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
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Items
          ...pedido.detalles.map<Widget>((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item.cantidad}x',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.getSaboresText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.presentacionNombre ?? 'Presentación',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),

          // Botón
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _iniciarPreparacion(context, pedido, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'INICIAR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CARD: PEDIDO EN COCINA (Con temporizador)
  Widget _buildPedidoEnCocinaCard(
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con temporizador
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PEDIDO #${pedido.id}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(pedido.fechaHora),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // TEMPORIZADOR DESTACADO
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorTiempo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tiempoTranscurrido,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Items
          ...pedido.detalles.map<Widget>((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A4A2F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item.cantidad}x',
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.getSaboresText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.presentacionNombre ?? 'Presentación',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),

          // Botón
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _marcarListo(context, pedido, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'MARCAR LISTO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CARD: PEDIDO LISTO (Compacto)
  Widget _buildPedidoListoCard(dynamic pedido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PEDIDO #${pedido.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('HH:mm').format(pedido.fechaHora),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pedido.detalles.length}x ${pedido.detalles.isNotEmpty ? pedido.detalles.first.getSaboresText() : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HELPERS

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
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
      return const Color(0xFF4CAF50);
    }

    final minutos =
        _currentTime.difference(_tiemposInicio[pedidoId]!).inMinutes;

    if (minutos < 15) return const Color(0xFF4CAF50);
    if (minutos < 25) return const Color(0xFFFF9800);
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
          content: Text('¡Pedido #${pedido.id} listo para entregar!'),
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}