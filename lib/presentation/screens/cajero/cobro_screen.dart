import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/item_pedido.dart';
import '../../../data/repositories/pedido_repository.dart';
import '../../../data/models/pedido_model.dart';
import '../../layouts/cajero_layout.dart';

class CobroScreen extends StatefulWidget {
  final List<ItemPedido> items;
  final String notas;

  const CobroScreen({
    super.key,
    required this.items,
    required this.notas,
  });

  @override
  State<CobroScreen> createState() => _CobroScreenState();
}

class _CobroScreenState extends State<CobroScreen> {
  final PedidoRepository _pedidoRepository = PedidoRepository();

  MetodoPago? _metodoPagoSeleccionado;
  TipoServicio _tipoServicioSeleccionado = TipoServicio.MESA;
  final TextEditingController _montoRecibidoController = TextEditingController();
  final TextEditingController _numeroMesaController = TextEditingController();
  bool _procesandoPago = false;

  // TODO: Obtener el usuarioId del usuario logueado
  final int _usuarioId = 1; // Temporal - debería venir de SharedPreferences o estado global

  @override
  void initState() {
    super.initState();
    // Listener para actualizar el estado cuando cambien los valores
    _montoRecibidoController.addListener(() {
      if (mounted) setState(() {});
    });
    _numeroMesaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  double get _total {
    return widget.items.fold(
        0.0, (sum, item) => sum + (item.precio * item.cantidad));
  }

  double get _montoRecibido {
    return double.tryParse(_montoRecibidoController.text) ?? 0.0;
  }

  double get _vuelto {
    if (_metodoPagoSeleccionado == MetodoPago.EFECTIVO) {
      return _montoRecibido - _total;
    }
    return 0.0;
  }

  bool get _puedeConfirmar {
    // Debe tener método de pago seleccionado
    if (_metodoPagoSeleccionado == null) return false;

    // Si es servicio en mesa, debe tener número de mesa
    if (_tipoServicioSeleccionado == TipoServicio.MESA &&
        _numeroMesaController.text.trim().isEmpty) {
      return false;
    }

    // Si es efectivo, debe tener monto suficiente
    if (_metodoPagoSeleccionado == MetodoPago.EFECTIVO) {
      return _montoRecibido >= _total;
    }

    // Para QR y Tarjeta, solo necesita método seleccionado
    return true;
  }

  String _convertirMetodoPago(MetodoPago metodo) {
    return metodo.name;
  }

  String _convertirTipoServicio(TipoServicio tipo) {
    return tipo.name;
  }

  void _confirmarPago() async {
    if (!_puedeConfirmar) return;

    setState(() => _procesandoPago = true);

    try {
      // Separar pizzas y otros productos (bebidas)
      final pizzas = widget.items.where((item) => item.esPizza).toList();
      final bebidas = widget.items.where((item) => !item.esPizza).toList();

      // Debug: Imprimir información de las pizzas
      print('=== DEBUG PEDIDO ===');
      print('Total de pizzas: ${pizzas.length}');
      for (var pizza in pizzas) {
        print('Pizza: ${pizza.nombre}');
        print('  - Sabor IDs: ${pizza.saboresIds}');
        print('  - Presentación ID: ${pizza.presentacionId}');
        print('  - Cantidad: ${pizza.cantidad}');
      }

      // Crear request
      final request = CreatePedidoRequest(
        usuarioId: _usuarioId,
        tipoServicio: _tipoServicioSeleccionado,
        metodoPago: _convertirMetodoPago(_metodoPagoSeleccionado!),
        detalles: bebidas.map((item) => DetallePedidoRequest(
          productoId: item.id,
          presentacionId: item.presentacionId,
          saborId: item.saborId ?? 0,
          cantidad: item.cantidad,
        )).toList(),
        pizzas: pizzas.map((item) {
          // Obtener los IDs de sabores
          final saboresIds = item.saboresIds ?? [item.saborId ?? item.id];

          // Debug detallado
          print('Procesando pizza: ${item.nombre}');
          print('  - item.saboresIds original: ${item.saboresIds}');
          print('  - saboresIds a usar: $saboresIds');
          print('  - Longitud de saboresIds: ${saboresIds.length}');

          // Asignar sabores con verificación
          final sabor1 = saboresIds.isNotEmpty ? saboresIds[0] : item.id;
          final sabor2 = saboresIds.length > 1 ? saboresIds[1] : 0;
          final sabor3 = saboresIds.length > 2 ? saboresIds[2] : 0;

          print('  - Valores asignados:');
          print('    * sabor1Id: $sabor1');
          print('    * sabor2Id: $sabor2');
          print('    * sabor3Id: $sabor3');

          final pizzaItem = PizzaPedidoItem(
            presentacionId: item.presentacionId,
            sabor1Id: sabor1,
            sabor2Id: sabor2,
            sabor3Id: sabor3,
            pesoKg: item.pesoKg,
            cantidad: item.cantidad,
          );

          // Debug: Imprimir pizza a enviar
          print('Pizza Item creado:');
          print('  - toJson: ${pizzaItem.toJson()}');

          return pizzaItem;
        }).toList(),
      );

      // Debug: Imprimir request completo
      print('Request JSON: ${request.toJson()}');
      print('===================');

      // Enviar pedido al backend
      final pedido = await _pedidoRepository.createPedido(request);

      if (!mounted) return;

      // Mostrar confirmación
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          pedidoId: pedido.id ?? 0,
          total: _total,
          metodoPago: _metodoPagoSeleccionado!,
          vuelto: _vuelto,
          tipoServicio: _tipoServicioSeleccionado,
          numeroMesa: _numeroMesaController.text,
        ),
      ).then((_) {
        // Volver al dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } catch (e) {
      setState(() => _procesandoPago = false);

      if (!mounted) return;

      // Parsear el error para obtener el mensaje del backend
      String errorTitle = 'Error en el Pedido';
      String errorMessage = 'Ha ocurrido un error al procesar el pedido';
      String? errorDetails;
      IconData errorIcon = Icons.error_outline;

      try {
        final errorString = e.toString();
        print('═══════════════════════════════');
        print('Error completo capturado:');
        print(errorString);
        print('═══════════════════════════════');

        Map<String, dynamic>? errorData;

        // Intentar parsear como JSON de diferentes formas

        // Método 1: Buscar JSON dentro del string
        if (errorString.contains('{') && errorString.contains('}')) {
          final jsonStart = errorString.indexOf('{');
          final jsonEnd = errorString.lastIndexOf('}') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = errorString.substring(jsonStart, jsonEnd);
            print('JSON extraído: $jsonString');

            try {
              errorData = jsonDecode(jsonString) as Map<String, dynamic>;
              print('JSON parseado exitosamente: $errorData');
            } catch (jsonError) {
              print('Error al parsear JSON método 1: $jsonError');
            }
          }
        }

        // Método 2: Buscar palabras clave directamente
        if (errorData == null && errorString.contains('STOCK_INSUFICIENTE')) {
          print('Detectado STOCK_INSUFICIENTE, extrayendo información...');

          // Extraer información con regex
          final regexInsumo = RegExp(r'insumo["\s:]+([^"]+)"');
          final regexMensaje = RegExp(r'mensaje["\s:]+([^"]+(?:"[^"]*"[^"]*)*)"');
          final regexStockActual = RegExp(r'stockActual["\s:]+([0-9.]+)');
          final regexStockRequerido = RegExp(r'stockRequerido["\s:]+([0-9.]+)');

          final matchInsumo = regexInsumo.firstMatch(errorString);
          final matchMensaje = regexMensaje.firstMatch(errorString);
          final matchStockActual = regexStockActual.firstMatch(errorString);
          final matchStockRequerido = regexStockRequerido.firstMatch(errorString);

          if (matchInsumo != null || matchMensaje != null) {
            errorData = {
              'tipo': 'STOCK_INSUFICIENTE',
              'insumo': matchInsumo?.group(1)?.trim() ?? 'desconocido',
              'mensaje': matchMensaje?.group(1)?.replaceAll(r'\"', '"')?.trim() ??
                  'Stock insuficiente',
              'stockActual': matchStockActual != null
                  ? double.tryParse(matchStockActual.group(1)!) ?? 0
                  : 0,
              'stockRequerido': matchStockRequerido != null
                  ? double.tryParse(matchStockRequerido.group(1)!) ?? 0
                  : 0,
            };
            print('Datos extraídos con regex: $errorData');
          }
        }

        // Si logramos obtener errorData, procesarlo
        if (errorData != null) {
          if (errorData['tipo'] == 'STOCK_INSUFICIENTE') {
            errorTitle = '⚠️ Stock Insuficiente';
            errorIcon = Icons.inventory_2_outlined;
            errorMessage = errorData['mensaje']?.toString() ?? 'Stock insuficiente';

            // Limpiar mensaje de caracteres de escape
            errorMessage = errorMessage
                .replaceAll(r'\"', '"')
                .replaceAll(r'\n', '\n')
                .trim();

            // Formatear detalles
            final insumo = errorData['insumo']?.toString() ?? 'desconocido';
            final stockActual = (errorData['stockActual'] is num)
                ? (errorData['stockActual'] as num).toStringAsFixed(2)
                : '0.00';
            final stockRequerido = (errorData['stockRequerido'] is num)
                ? (errorData['stockRequerido'] as num).toStringAsFixed(2)
                : '0.00';

            errorDetails = 'Insumo: $insumo\n'
                'Stock disponible: $stockActual kg\n'
                'Stock requerido: $stockRequerido kg';

            print('Mensaje final: $errorMessage');
            print('Detalles: $errorDetails');
          } else if (errorData['mensaje'] != null) {
            errorMessage = errorData['mensaje'].toString()
                .replaceAll(r'\"', '"')
                .replaceAll(r'\n', '\n')
                .trim();
          }
        }
      } catch (parseError) {
        print('Error en el parsing completo: $parseError');
        print('Stack trace: ${parseError}');
      }

      print('═══════════════════════════════');
      print('Mostrando diálogo con:');
      print('Title: $errorTitle');
      print('Message: $errorMessage');
      print('Details: $errorDetails');
      print('═══════════════════════════════');

      // Mostrar diálogo de error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorIcon,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  errorTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (errorDetails != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorDetails,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor, intenta con otro pedido o contacta al administrador.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _setMontoExacto() {
    setState(() {
      _montoRecibidoController.text = _total.toStringAsFixed(2);
    });
  }

  void _agregarMonto(double monto) {
    setState(() {
      final actual = _montoRecibido;
      _montoRecibidoController.text = (actual + monto).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return CajeroLayout(
      title: 'Cobro de Pedido',
      currentRoute: '/cajero/cobro',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de servicio
                    _buildServiceType(),
                    const SizedBox(height: 24),

                    // Número de mesa si es MESA
                    if (_tipoServicioSeleccionado == TipoServicio.MESA)
                      _buildTableNumber(),
                    if (_tipoServicioSeleccionado == TipoServicio.MESA)
                      const SizedBox(height: 24),

                    // Métodos de pago
                    _buildPaymentMethods(),
                    const SizedBox(height: 24),

                    // Campo de monto si es efectivo
                    if (_metodoPagoSeleccionado == MetodoPago.EFECTIVO)
                      _buildCashPayment(),

                    // QR si es pago por QR
                    if (_metodoPagoSeleccionado == MetodoPago.QR)
                      _buildQRPayment(),

                    // Tarjeta
                    if (_metodoPagoSeleccionado == MetodoPago.TARJETA)
                      _buildCardPayment(),
                  ],
                ),
              ),
            ),
          ),
          if (isDesktop)
            Container(
              width: 380,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  left: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: _buildSummary(),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Servicio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ServiceTypeCard(
                icon: Icons.restaurant,
                title: 'Mesa',
                isSelected: _tipoServicioSeleccionado == TipoServicio.MESA,
                onTap: () {
                  setState(() {
                    _tipoServicioSeleccionado = TipoServicio.MESA;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceTypeCard(
                icon: Icons.shopping_bag,
                title: 'Para Llevar',
                isSelected: _tipoServicioSeleccionado == TipoServicio.LLEVAR,
                onTap: () {
                  setState(() {
                    _tipoServicioSeleccionado = TipoServicio.LLEVAR;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceTypeCard(
                icon: Icons.delivery_dining,
                title: 'Delivery',
                isSelected: _tipoServicioSeleccionado == TipoServicio.DELIVERY,
                onTap: () {
                  setState(() {
                    _tipoServicioSeleccionado = TipoServicio.DELIVERY;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableNumber() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Mesa',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _numeroMesaController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.table_restaurant, color: AppColors.secondary),
            hintText: 'Ej: 12',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                icon: Icons.attach_money,
                title: 'Efectivo',
                isSelected: _metodoPagoSeleccionado == MetodoPago.EFECTIVO,
                gradient: const LinearGradient(
                  colors: [Color(0xFF388E3C), Color(0xFF4CAF50)],
                ),
                onTap: () {
                  setState(() {
                    _metodoPagoSeleccionado = MetodoPago.EFECTIVO;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodCard(
                icon: Icons.qr_code,
                title: 'QR',
                isSelected: _metodoPagoSeleccionado == MetodoPago.QR,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                ),
                onTap: () {
                  setState(() {
                    _metodoPagoSeleccionado = MetodoPago.QR;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodCard(
                icon: Icons.credit_card,
                title: 'Tarjeta',
                isSelected: _metodoPagoSeleccionado == MetodoPago.TARJETA,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                ),
                onTap: () {
                  setState(() {
                    _metodoPagoSeleccionado = MetodoPago.TARJETA;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monto Recibido',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _montoRecibidoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixText: 'Bs. ',
            prefixStyle: const TextStyle(
              color: AppColors.secondary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            hintText: '0.00',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAmountButton(label: 'Exacto', onTap: _setMontoExacto),
            _QuickAmountButton(label: '+10', onTap: () => _agregarMonto(10)),
            _QuickAmountButton(label: '+20', onTap: () => _agregarMonto(20)),
            _QuickAmountButton(label: '+50', onTap: () => _agregarMonto(50)),
            _QuickAmountButton(label: '+100', onTap: () => _agregarMonto(100)),
          ],
        ),
        const SizedBox(height: 24),
        if (_montoRecibido > 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _vuelto >= 0
                    ? [
                  AppColors.success.withOpacity(0.2),
                  AppColors.success.withOpacity(0.1),
                ]
                    : [
                  AppColors.error.withOpacity(0.2),
                  AppColors.error.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _vuelto >= 0
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vuelto >= 0 ? 'Vuelto' : 'Falta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${_vuelto.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _vuelto >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _vuelto >= 0 ? Icons.check_circle : Icons.warning,
                  size: 48,
                  color: _vuelto >= 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQRPayment() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 200,
                      color: Colors.grey.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Escanea para pagar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Total: Bs. ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Esperando confirmación del pago...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardPayment() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withOpacity(0.2),
                AppColors.warning.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.credit_card,
                size: 80,
                color: AppColors.warning,
              ),
              const SizedBox(height: 24),
              Text(
                'Inserta o acerca la tarjeta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esperando terminal de pago...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Total: Bs. ${_total.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.cantidad}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${item.tipoProducto} - ${item.presentacion}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Bs. ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.notas.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.notas,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a Pagar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Bs. ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _puedeConfirmar && !_procesandoPago
                      ? _confirmarPago
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _procesandoPago
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
                        'Confirmar Pago',
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
    );
  }

  @override
  void dispose() {
    _montoRecibidoController.dispose();
    _numeroMesaController.dispose();
    super.dispose();
  }
}

// Service Type Card
class _ServiceTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTypeCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.secondary : const Color(0xFF2A2A2A),
          width: 2,
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
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

// Payment Method Card
class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: isSelected ? gradient : null,
        color: isSelected ? null : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFF2A2A2A),
          width: 2,
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
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Amount Button
class _QuickAmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Success Dialog
class _SuccessDialog extends StatelessWidget {
  final int pedidoId;
  final double total;
  final MetodoPago metodoPago;
  final double vuelto;
  final TipoServicio tipoServicio;
  final String numeroMesa;

  const _SuccessDialog({
    required this.pedidoId,
    required this.total,
    required this.metodoPago,
    required this.vuelto,
    required this.tipoServicio,
    required this.numeroMesa,
  });

  String get _metodoPagoTexto {
    switch (metodoPago) {
      case MetodoPago.EFECTIVO:
        return 'Efectivo';
      case MetodoPago.QR:
        return 'QR';
      case MetodoPago.TARJETA:
        return 'Tarjeta';
    }
  }

  String get _tipoServicioTexto {
    switch (tipoServicio) {
      case TipoServicio.MESA:
        return 'Mesa $numeroMesa';
      case TipoServicio.LLEVAR:
        return 'Para Llevar';
      case TipoServicio.DELIVERY:
        return 'Delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Pago Confirmado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pedido #$pedidoId enviado a cocina',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Servicio:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _tipoServicioTexto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        'Bs. ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Método:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _metodoPagoTexto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  if (metodoPago == MetodoPago.EFECTIVO && vuelto > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vuelto:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          'Bs. ${vuelto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  'Volver al Inicio',
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
}