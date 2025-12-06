// lib/presentation/screens/cliente/carrito_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cliente_layout.dart';
import '../../providers/carrito_provider.dart';

enum MetodoPago { QR, TARJETA }

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  MetodoPago? _metodoPagoSeleccionado;
  final TextEditingController _direccionController = TextEditingController();
  bool _procesandoPedido = false;

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();

    // Validaciones
    if (carritoProvider.estaVacio) {
      _mostrarError('El carrito está vacío');
      return;
    }

    if (carritoProvider.tipoEntrega == TipoEntrega.DELIVERY &&
        _direccionController.text.trim().isEmpty) {
      _mostrarError('Ingresa tu dirección de entrega');
      return;
    }

    if (_metodoPagoSeleccionado == null) {
      _mostrarError('Selecciona un método de pago');
      return;
    }

    setState(() => _procesandoPedido = true);

    // Guardar dirección si es delivery
    if (carritoProvider.tipoEntrega == TipoEntrega.DELIVERY) {
      carritoProvider.setDireccionEntrega(_direccionController.text.trim());
    }

    // Simular procesamiento del pedido
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Mostrar éxito
    _mostrarExito();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito() {
    final carritoProvider = context.read<CarritoProvider>();
    final total = carritoProvider.total;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        total: total,
        metodoPago: _metodoPagoSeleccionado!,
        tipoEntrega: carritoProvider.tipoEntrega,
      ),
    ).then((_) {
      // Limpiar carrito y volver al inicio
      carritoProvider.limpiarDespuesDePedido();
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isMobile = size.width <= 1024;

    return ClienteLayout(
      title: 'Mi Carrito',
      currentRoute: '/cliente/carrito',
      showCartButton: false,
      child: Consumer<CarritoProvider>(
        builder: (context, carrito, _) {
          if (carrito.estaVacio) {
            return _buildEmptyCart();
          }

          return Row(
            children: [
              // Panel izquierdo - Items y configuración
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items del carrito
                      _buildItemsSection(carrito),
                      const SizedBox(height: 24),

                      // Tipo de entrega
                      _buildTipoEntregaSection(carrito),
                      const SizedBox(height: 24),

                      // Dirección (si es delivery)
                      if (carrito.tipoEntrega == TipoEntrega.DELIVERY)
                        _buildDireccionSection(),
                    ],
                  ),
                ),
              ),

              // Panel derecho - Resumen y pago
              if (isDesktop)
                Container(
                  width: 400,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    border: Border(
                      left: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                    ),
                  ),
                  child: _buildResumenYPago(carrito),
                ),
            ],
          );
        },
      ),

    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agrega productos para continuar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a comprar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(CarritoProvider carrito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Vaciar Carrito',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '¿Deseas eliminar todos los productos?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          carrito.vaciarCarrito();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Vaciar'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Vaciar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: carrito.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = carrito.items[index];
            return _ItemCard(
              item: item,
              onIncrease: () => carrito.incrementarCantidad(index),
              onDecrease: () => carrito.decrementarCantidad(index),
              onDelete: () => carrito.eliminarItem(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTipoEntregaSection(CarritoProvider carrito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Entrega',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TipoEntregaCard(
                tipo: TipoEntrega.LOCAL,
                isSelected: carrito.tipoEntrega == TipoEntrega.LOCAL,
                onTap: () => carrito.setTipoEntrega(TipoEntrega.LOCAL),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoEntregaCard(
                tipo: TipoEntrega.DELIVERY,
                isSelected: carrito.tipoEntrega == TipoEntrega.DELIVERY,
                onTap: () => carrito.setTipoEntrega(TipoEntrega.DELIVERY),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDireccionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dirección de Entrega',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _direccionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Calle, número, referencias...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.location_on, color: AppColors.secondary),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
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
        ),
      ],
    );
  }

  Widget _buildResumenYPago(CarritoProvider carrito) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.secondary),
              SizedBox(width: 12),
              Text(
                'Resumen del Pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Desglose de precios
                _buildPriceRow('Subtotal', carrito.subtotal),
                const SizedBox(height: 12),
                _buildPriceRow('Delivery', carrito.costoDelivery),
                if (carrito.costoDelivery == 0 &&
                    carrito.tipoEntrega == TipoEntrega.DELIVERY)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '¡Envío gratis!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Divider(height: 32, color: Color(0xFF2A2A2A)),
                Row(
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
                      '\$${carrito.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Método de pago
                const Text(
                  'Método de Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                _MetodoPagoCard(
                  icon: Icons.qr_code_2,
                  title: 'Pago con QR',
                  subtitle: 'Escanea y paga',
                  isSelected: _metodoPagoSeleccionado == MetodoPago.QR,
                  color: const Color(0xFF0096C7),
                  onTap: () {
                    setState(() => _metodoPagoSeleccionado = MetodoPago.QR);
                  },
                ),
                const SizedBox(height: 12),
                _MetodoPagoCard(
                  icon: Icons.credit_card,
                  title: 'Tarjeta',
                  subtitle: 'Débito o crédito',
                  isSelected: _metodoPagoSeleccionado == MetodoPago.TARJETA,
                  color: const Color(0xFFF77F00),
                  onTap: () {
                    setState(() => _metodoPagoSeleccionado = MetodoPago.TARJETA);
                  },
                ),
              ],
            ),
          ),
        ),

        // Botón confirmar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: const Border(
              top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _procesandoPedido ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _procesandoPedido
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Confirmar Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// WIDGETS

class _ItemCard extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_pizza,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.categoria,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        if (item.observaciones != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.observaciones!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Text(
                      '${item.cantidad}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipoEntregaCard extends StatelessWidget {
  final TipoEntrega tipo;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipoEntregaCard({
    required this.tipo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.secondary.withOpacity(0.15)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.secondary : const Color(0xFF2A2A2A),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tipo.icono,
                size: 40,
                color: isSelected ? AppColors.secondary : Colors.white60,
              ),
              const SizedBox(height: 8),
              Text(
                tipo.texto,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.secondary : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MetodoPagoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : const Color(0xFF3A3A3A),
          width: isSelected ? 2 : 1,
        ),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final double total;
  final MetodoPago metodoPago;
  final TipoEntrega tipoEntrega;

  const _SuccessDialog({
    required this.total,
    required this.metodoPago,
    required this.tipoEntrega,
  });

  String get _metodoPagoTexto {
    return metodoPago == MetodoPago.QR ? 'Pago con QR' : 'Tarjeta';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Pedido Confirmado!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu pedido está siendo preparado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Total:', '\$${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Pago:', _metodoPagoTexto),
                  const SizedBox(height: 12),
                  _buildInfoRow('Entrega:', tipoEntrega.texto),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver Mis Pedidos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}