// lib/presentation/screens/cliente/pedido_screen.dart

// lib/presentation/screens/cliente/pedido_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cliente_layout.dart';
import '../../providers/carrito_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'carrito_screen.dart';

// Enums para el flujo
enum TipoProducto { PIZZA, BEBIDA, OTRO }
enum TipoPresentacion { PESO, REDONDA, BANDEJA }

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({super.key});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  // Estado del flujo
  TipoProducto? _tipoProductoSeleccionado;
  TipoPresentacion? _presentacionSeleccionada;

  // Para pizzas
  final List<String> _saboresSeleccionados = [];
  int _cantidad = 1;
  double _pesoSeleccionado = 0.0; // Para pizza por peso
  double _precioCalculado = 0.0;

  // Para bebidas
  String? _bebidaSeleccionada;
  String? _tamanioBebida;

  // Datos mock (después conectar con backend)
  final List<String> _saboresDisponibles = [
    'Margarita',
    'Pepperoni',
    'Hawaiana',
    'Cuatro Quesos',
    'Napolitana',
    'Vegetariana',
    'BBQ',
    'Carbonara',
  ];

  final Map<String, List<String>> _bebidasPorTamanio = {
    'Coca Cola': ['500ml', '1L', '2L'],
    'Fanta': ['500ml', '1L', '2L'],
    'Sprite': ['500ml', '1L', '2L'],
    'Agua': ['500ml', '1L'],
    'Jugo Natural': ['500ml'],
  };

  final List<String> _otros = [
    'Calzone de Jamón',
    'Calzone de Pollo',
    'Calzone Vegetariano',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return ClienteLayout(
      title: 'Realizar Pedido',
      currentRoute: '/cliente/pedido',
      child: Row(
        children: [
          // Panel izquierdo - Flujo de pedido
          Expanded(
            flex: isDesktop ? 3 : 1,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paso 1: Seleccionar tipo de producto
                  _buildTipoProductoSection(),

                  const SizedBox(height: 24),

                  // Paso 2: Seleccionar presentación (solo para pizzas)
                  if (_tipoProductoSeleccionado == TipoProducto.PIZZA)
                    _buildPresentacionSection(),

                  const SizedBox(height: 24),

                  // Paso 3: Contenido según selección
                  _buildContenidoSegunSeleccion(),
                ],
              ),
            ),
          ),

          // Panel derecho - Resumen del pedido (Desktop)
          if (isDesktop)
            Container(
              width: 400,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  left: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: _buildResumenPedido(),
            ),
        ],
      ),
      // Botón flotante para mobile
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A1A),
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => _buildResumenPedido(controller),
            ),
          );
        },
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.shopping_cart),
        label: Consumer<CarritoProvider>(
          builder: (context, carrito, _) => Text(
            'Ver Pedido (${carrito.cantidadItems})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      )
          : null,
    );
  }

  // Paso 1: Seleccionar tipo de producto
  Widget _buildTipoProductoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. ¿Qué deseas ordenar?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _TipoProductoCard(
              tipo: TipoProducto.PIZZA,
              icon: Icons.local_pizza,
              titulo: 'Pizza',
              isSelected: _tipoProductoSeleccionado == TipoProducto.PIZZA,
              onTap: () {
                setState(() {
                  _tipoProductoSeleccionado = TipoProducto.PIZZA;
                  _presentacionSeleccionada = null;
                  _saboresSeleccionados.clear();
                  _bebidaSeleccionada = null;
                });
              },
            ),
            _TipoProductoCard(
              tipo: TipoProducto.BEBIDA,
              icon: Icons.local_drink,
              titulo: 'Bebida',
              isSelected: _tipoProductoSeleccionado == TipoProducto.BEBIDA,
              onTap: () {
                setState(() {
                  _tipoProductoSeleccionado = TipoProducto.BEBIDA;
                  _presentacionSeleccionada = null;
                  _saboresSeleccionados.clear();
                });
              },
            ),
            _TipoProductoCard(
              tipo: TipoProducto.OTRO,
              icon: Icons.restaurant,
              titulo: 'Otros',
              isSelected: _tipoProductoSeleccionado == TipoProducto.OTRO,
              onTap: () {
                setState(() {
                  _tipoProductoSeleccionado = TipoProducto.OTRO;
                  _presentacionSeleccionada = null;
                  _saboresSeleccionados.clear();
                  _bebidaSeleccionada = null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // Paso 2: Seleccionar presentación (solo pizzas)
  Widget _buildPresentacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Selecciona la presentación',
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
              child: _PresentacionCard(
                presentacion: TipoPresentacion.PESO,
                titulo: 'Por Peso',
                descripcion: 'Indica el peso',
                icon: Icons.scale,
                isSelected: _presentacionSeleccionada == TipoPresentacion.PESO,
                onTap: () {
                  setState(() {
                    _presentacionSeleccionada = TipoPresentacion.PESO;
                    _saboresSeleccionados.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PresentacionCard(
                presentacion: TipoPresentacion.REDONDA,
                titulo: 'Redonda',
                descripcion: 'Hasta 2 sabores',
                icon: Icons.circle_outlined,
                isSelected: _presentacionSeleccionada == TipoPresentacion.REDONDA,
                onTap: () {
                  setState(() {
                    _presentacionSeleccionada = TipoPresentacion.REDONDA;
                    _saboresSeleccionados.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PresentacionCard(
                presentacion: TipoPresentacion.BANDEJA,
                titulo: 'Bandeja',
                descripcion: 'Hasta 3 sabores',
                icon: Icons.crop_square,
                isSelected: _presentacionSeleccionada == TipoPresentacion.BANDEJA,
                onTap: () {
                  setState(() {
                    _presentacionSeleccionada = TipoPresentacion.BANDEJA;
                    _saboresSeleccionados.clear();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Paso 3: Contenido según selección
  Widget _buildContenidoSegunSeleccion() {
    if (_tipoProductoSeleccionado == null) {
      return const SizedBox.shrink();
    }

    switch (_tipoProductoSeleccionado!) {
      case TipoProducto.PIZZA:
        return _buildPizzaConfig();
      case TipoProducto.BEBIDA:
        return _buildBebidaConfig();
      case TipoProducto.OTRO:
        return _buildOtrosConfig();
    }
  }

  // Configuración de Pizza
  Widget _buildPizzaConfig() {
    if (_presentacionSeleccionada == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Para pizza por peso: ingresar peso/precio
        if (_presentacionSeleccionada == TipoPresentacion.PESO)
          _buildPesoPrecioSelector(),

        // Seleccionar sabores
        if (_presentacionSeleccionada != TipoPresentacion.PESO) ...[
          Text(
            '3. Selecciona ${_getMaxSabores()} sabor${_getMaxSabores() > 1 ? 'es' : ''}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSaboresGrid(),
          const SizedBox(height: 24),
        ],

        // Cantidad
        _buildCantidadSelector(),

        const SizedBox(height: 24),

        // Botón agregar
        _buildAgregarButton(),
      ],
    );
  }

  // Selector de peso/precio para pizza por peso
  Widget _buildPesoPrecioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Indica el peso o precio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peso (kg)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            final peso = double.tryParse(value) ?? 0.0;
                            setState(() {
                              _pesoSeleccionado = peso;
                              _precioCalculado = peso * 45.0; // Bs. 45 por kg
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio (Bs.)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _precioCalculado.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Precio: Bs. 45.00 por kilogramo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Grid de sabores
  Widget _buildSaboresGrid() {
    final maxSabores = _getMaxSabores();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _saboresDisponibles.map((sabor) {
        final isSelected = _saboresSeleccionados.contains(sabor);
        final canSelect = _saboresSeleccionados.length < maxSabores;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _saboresSeleccionados.remove(sabor);
              } else if (canSelect) {
                _saboresSeleccionados.add(sabor);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : const Color(0xFF2A2A2A),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                Text(
                  sabor,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Configuración de Bebida
  Widget _buildBebidaConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Selecciona tu bebida',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bebidasPorTamanio.length,
          itemBuilder: (context, index) {
            final bebida = _bebidasPorTamanio.keys.elementAt(index);
            final tamanos = _bebidasPorTamanio[bebida]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _bebidaSeleccionada == bebida
                      ? AppColors.secondary
                      : const Color(0xFF2A2A2A),
                  width: _bebidaSeleccionada == bebida ? 2 : 1,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  bebida,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: const Icon(
                  Icons.local_drink,
                  color: AppColors.secondary,
                ),
                children: tamanos.map((tamano) {
                  final isSelected = _bebidaSeleccionada == bebida &&
                      _tamanioBebida == tamano;

                  return ListTile(
                    title: Text(
                      tamano,
                      style: TextStyle(
                        color: isSelected ? AppColors.secondary : Colors.white70,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                      Icons.check_circle,
                      color: AppColors.secondary,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _bebidaSeleccionada = bebida;
                        _tamanioBebida = tamano;
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        if (_bebidaSeleccionada != null) ...[
          const SizedBox(height: 24),
          _buildCantidadSelector(),
          const SizedBox(height: 24),
          _buildAgregarButton(),
        ],
      ],
    );
  }

  // Configuración de Otros
  Widget _buildOtrosConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Selecciona',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _otros.length,
          itemBuilder: (context, index) {
            final item = _otros[index];
            // Usar _bebidaSeleccionada temporalmente para otros
            final isSelected = _bebidaSeleccionada == item;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _bebidaSeleccionada = item;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary.withOpacity(0.2)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : const Color(0xFF2A2A2A),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: isSelected ? AppColors.secondary : Colors.white60,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppColors.secondary : Colors.white,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_bebidaSeleccionada != null) ...[
          const SizedBox(height: 24),
          _buildCantidadSelector(),
          const SizedBox(height: 24),
          _buildAgregarButton(),
        ],
      ],
    );
  }

  // Selector de cantidad
  Widget _buildCantidadSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Cantidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_cantidad > 1) {
                      setState(() => _cantidad--);
                    }
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  alignment: Alignment.center,
                  child: Text(
                    '$_cantidad',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _cantidad++);
                  },
                  icon: const Icon(Icons.add, color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Botón agregar al pedido
  Widget _buildAgregarButton() {
    bool canAdd = false;
    String buttonText = 'Agregar al Pedido';

    if (_tipoProductoSeleccionado == TipoProducto.PIZZA) {
      if (_presentacionSeleccionada == TipoPresentacion.PESO) {
        canAdd = _pesoSeleccionado > 0;
      } else {
        canAdd = _saboresSeleccionados.isNotEmpty;
      }
    } else if (_tipoProductoSeleccionado == TipoProducto.BEBIDA) {
      canAdd = _bebidaSeleccionada != null && _tamanioBebida != null;
    } else if (_tipoProductoSeleccionado == TipoProducto.OTRO) {
      canAdd = _bebidaSeleccionada != null;
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: buttonText,
        icon: Icons.add_shopping_cart,
        onPressed: canAdd ? _agregarAlCarrito : null,
      ),
    );
  }

  // Agregar al carrito
  void _agregarAlCarrito() {
    final carritoProvider = context.read<CarritoProvider>();
    String nombre = '';
    double precio = 0.0;
    String categoria = '';
    String? observaciones;

    if (_tipoProductoSeleccionado == TipoProducto.PIZZA) {
      categoria = 'Pizza';

      if (_presentacionSeleccionada == TipoPresentacion.PESO) {
        nombre = 'Pizza por Peso (${_pesoSeleccionado}kg)';
        precio = _precioCalculado;
      } else {
        final presentacion = _presentacionSeleccionada == TipoPresentacion.REDONDA
            ? 'Redonda'
            : 'Bandeja';
        nombre = 'Pizza $presentacion';
        precio = _presentacionSeleccionada == TipoPresentacion.REDONDA ? 35.0 : 50.0;
        observaciones = _saboresSeleccionados.join(', ');
      }
    } else if (_tipoProductoSeleccionado == TipoProducto.BEBIDA) {
      categoria = 'Bebida';
      nombre = '$_bebidaSeleccionada $_tamanioBebida';
      precio = _calcularPrecioBebida(_tamanioBebida!);
    } else {
      categoria = 'Otros';
      nombre = _bebidaSeleccionada!;
      precio = 25.0;
    }

    carritoProvider.agregarItem(
      productoId: DateTime.now().millisecondsSinceEpoch,
      nombre: nombre,
      precio: precio,
      categoria: categoria,
      observaciones: observaciones,
      cantidad: _cantidad,
    );

    // Resetear formulario
    setState(() {
      _presentacionSeleccionada = null;
      _saboresSeleccionados.clear();
      _cantidad = 1;
      _pesoSeleccionado = 0.0;
      _precioCalculado = 0.0;
      _bebidaSeleccionada = null;
      _tamanioBebida = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre agregado al pedido'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _calcularPrecioBebida(String tamano) {
    switch (tamano) {
      case '500ml':
        return 5.0;
      case '1L':
        return 8.0;
      case '2L':
        return 12.0;
      default:
        return 5.0;
    }
  }

  // Panel de resumen
  Widget _buildResumenPedido([ScrollController? controller]) {
    return Consumer<CarritoProvider>(
      builder: (context, carrito, _) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  const Text(
                    'Tu Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${carrito.cantidadItems} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de items
            Expanded(
              child: carrito.estaVacio
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu pedido está vacío',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(20),
                itemCount: carrito.items.length,
                itemBuilder: (context, index) {
                  final item = carrito.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () {
                                carrito.eliminarItem(index);
                              },
                            ),
                          ],
                        ),
                        if (item.observaciones != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.observaciones!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'x${item.cantidad}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              'Bs. ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Total y botón
            if (!carrito.estaVacio)
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
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Bs. ${carrito.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Continuar con el Pedido',
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CarritoScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _getMaxSabores() {
    switch (_presentacionSeleccionada) {
      case TipoPresentacion.REDONDA:
        return 2;
      case TipoPresentacion.BANDEJA:
        return 3;
      default:
        return 0;
    }
  }
}

// WIDGETS
class _TipoProductoCard extends StatelessWidget {
  final TipoProducto tipo;
  final IconData icon;
  final String titulo;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipoProductoCard({
    required this.tipo,
    required this.icon,
    required this.titulo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : const Color(0xFF2A2A2A),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppColors.secondary : Colors.white60,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.secondary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresentacionCard extends StatelessWidget {
  final TipoPresentacion presentacion;
  final String titulo;
  final String descripcion;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresentacionCard({
    required this.presentacion,
    required this.titulo,
    required this.descripcion,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : const Color(0xFF2A2A2A),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.secondary : Colors.white60,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.secondary : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}