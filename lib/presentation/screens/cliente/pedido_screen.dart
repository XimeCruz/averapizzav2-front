// lib/presentation/screens/cliente/pedido_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/item_carrito_model.dart';
import '../../../data/models/producto_model.dart';
import '../../layouts/cliente_layout.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'carrito_screen.dart';

enum TipoProducto { PIZZA, BEBIDA }

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({super.key});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  TipoProducto? _tipoProductoSeleccionado;
  String? _presentacionSeleccionada; // "PESO", "REDONDA", "BANDEJA"

  // Para pizzas
  final Map<int, String> _saboresSeleccionados = {}; // id -> nombre
  int _cantidad = 1;
  double _pesoSeleccionado = 0.0;
  double _precioCalculado = 0.0;

  // Para bebidas
  ProductoDto? _bebidaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().cargarMenu();
    });
  }

  int _getMaxSabores() {
    switch (_presentacionSeleccionada) {
      case 'PESO':
        return 1;
      case 'REDONDA':
        return 2;
      case 'BANDEJA':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return ClienteLayout(
      title: 'Realizar Pedido',
      currentRoute: '/cliente/pedido',
      child: Consumer<MenuProvider>(
        builder: (context, menuProvider, _) {
          if (menuProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (menuProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar el menú',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    menuProvider.error!,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => menuProvider.cargarMenu(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (menuProvider.menu == null) {
            return const Center(
              child: Text(
                'No hay productos disponibles',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: isDesktop ? 3 : 1,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipoProductoSection(),
                      const SizedBox(height: 24),
                      if (_tipoProductoSeleccionado == TipoProducto.PIZZA)
                        _buildPresentacionSection(menuProvider),
                      const SizedBox(height: 24),
                      _buildContenidoSegunSeleccion(menuProvider),
                    ],
                  ),
                ),
              ),
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
          );
        },
      ),
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
        Row(
          children: [
            Expanded(
              child: _TipoProductoCard(
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoProductoCard(
                tipo: TipoProducto.BEBIDA,
                icon: Icons.local_drink,
                titulo: 'Bebida',
                isSelected: _tipoProductoSeleccionado == TipoProducto.BEBIDA,
                onTap: () {
                  setState(() {
                    _tipoProductoSeleccionado = TipoProducto.BEBIDA;
                    _presentacionSeleccionada = null;
                    _saboresSeleccionados.clear();
                    _bebidaSeleccionada = null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresentacionSection(MenuProvider menuProvider) {
    final presentacionesDisponibles = menuProvider.pizzasPorPresentacion.keys.toList();

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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presentacionesDisponibles.map((presentacion) {
            return _PresentacionCard(
              presentacion: presentacion,
              titulo: _getNombrePresentacion(presentacion),
              descripcion: _getDescripcionPresentacion(presentacion),
              icon: _getIconoPresentacion(presentacion),
              isSelected: _presentacionSeleccionada == presentacion,
              onTap: () {
                setState(() {
                  _presentacionSeleccionada = presentacion;
                  _saboresSeleccionados.clear();
                  _pesoSeleccionado = 0.0;
                  _precioCalculado = 0.0;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getNombrePresentacion(String presentacion) {
    switch (presentacion) {
      case 'PESO':
        return 'Por Peso';
      case 'REDONDA':
        return 'Redonda';
      case 'BANDEJA':
        return 'Bandeja';
      default:
        return presentacion;
    }
  }

  String _getDescripcionPresentacion(String presentacion) {
    switch (presentacion) {
      case 'PESO':
        return 'Indica el peso';
      case 'REDONDA':
        return 'Hasta 2 sabores';
      case 'BANDEJA':
        return 'Hasta 3 sabores';
      default:
        return '';
    }
  }

  IconData _getIconoPresentacion(String presentacion) {
    switch (presentacion) {
      case 'PESO':
        return Icons.scale;
      case 'REDONDA':
        return Icons.circle_outlined;
      case 'BANDEJA':
        return Icons.crop_square;
      default:
        return Icons.local_pizza;
    }
  }

  Widget _buildContenidoSegunSeleccion(MenuProvider menuProvider) {
    if (_tipoProductoSeleccionado == null) {
      return const SizedBox.shrink();
    }

    switch (_tipoProductoSeleccionado!) {
      case TipoProducto.PIZZA:
        return _buildPizzaConfig(menuProvider);
      case TipoProducto.BEBIDA:
        return _buildBebidaConfig(menuProvider);
    }
  }

  Widget _buildPizzaConfig(MenuProvider menuProvider) {
    if (_presentacionSeleccionada == null) {
      return const SizedBox.shrink();
    }

    final saboresDisponibles = menuProvider.getSaboresByPresentacion(_presentacionSeleccionada!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_presentacionSeleccionada == 'PESO')
          _buildPesoPrecioSelector(saboresDisponibles)
        else ...[
          Text(
            '3. Selecciona ${_getMaxSabores()} sabor${_getMaxSabores() > 1 ? 'es' : ''}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSaboresGrid(saboresDisponibles),
          const SizedBox(height: 24),
        ],
        _buildCantidadSelector(),
        const SizedBox(height: 24),
        _buildAgregarButton(),
      ],
    );
  }

  Widget _buildPesoPrecioSelector(List<ProductoDto> saboresDisponibles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Selecciona el sabor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Seleccionar sabor
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: saboresDisponibles.map((sabor) {
            final isSelected = _saboresSeleccionados.containsKey(sabor.id);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _saboresSeleccionados.clear();
                  _saboresSeleccionados[sabor.id] = sabor.nombre;
                  // Al seleccionar un sabor, recalcular el precio si ya hay peso
                  if (_pesoSeleccionado > 0) {
                    _precioCalculado = _pesoSeleccionado * sabor.precio;
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
                      sabor.nombre,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Input de peso
        const Text(
          '4. Indica el peso',
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
                            color: Colors.black,
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
                              if (_saboresSeleccionados.isNotEmpty) {
                                final saborId = _saboresSeleccionados.keys.first;
                                final sabor = saboresDisponibles.firstWhere((s) => s.id == saborId);
                                _precioCalculado = peso * sabor.precio;
                              }
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
              if (_saboresSeleccionados.isNotEmpty) ...[
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
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Precio: Bs. ${saboresDisponibles.firstWhere((s) => s.id == _saboresSeleccionados.keys.first).precio.toStringAsFixed(2)} por kilogramo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSaboresGrid(List<ProductoDto> saboresDisponibles) {
    final maxSabores = _getMaxSabores();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: saboresDisponibles.map((sabor) {
        final isSelected = _saboresSeleccionados.containsKey(sabor.id);
        final canSelect = _saboresSeleccionados.length < maxSabores;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _saboresSeleccionados.remove(sabor.id);
              } else if (canSelect) {
                _saboresSeleccionados[sabor.id] = sabor.nombre;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sabor.nombre,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      'Bs. ${sabor.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBebidaConfig(MenuProvider menuProvider) {
    final bebidas = menuProvider.bebidas;

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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: bebidas.length,
          itemBuilder: (context, index) {
            final bebida = bebidas[index];
            final isSelected = _bebidaSeleccionada?.id == bebida.id &&
                _bebidaSeleccionada?.presentacionId == bebida.presentacionId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _bebidaSeleccionada = bebida;
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
                      Icons.local_drink,
                      color: isSelected ? AppColors.secondary : Colors.white60,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bebida.nombre,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppColors.secondary : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${bebida.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.secondary : Colors.white70,
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

  Widget _buildAgregarButton() {
    bool canAdd = false;

    if (_tipoProductoSeleccionado == TipoProducto.PIZZA) {
      if (_presentacionSeleccionada == 'PESO') {
        canAdd = _pesoSeleccionado > 0 && _saboresSeleccionados.isNotEmpty;
      } else {
        canAdd = _saboresSeleccionados.isNotEmpty;
      }
    } else if (_tipoProductoSeleccionado == TipoProducto.BEBIDA) {
      canAdd = _bebidaSeleccionada != null;
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Agregar al Pedido',
        icon: Icons.add_shopping_cart,
        onPressed: canAdd ? _agregarAlCarrito : null,
      ),
    );
  }

  void _agregarAlCarrito() {
    final carritoProvider = context.read<CarritoProvider>();
    final menuProvider = context.read<MenuProvider>();

    if (_tipoProductoSeleccionado == TipoProducto.PIZZA) {
      _agregarPizzaAlCarrito(carritoProvider, menuProvider);
    } else if (_tipoProductoSeleccionado == TipoProducto.BEBIDA) {
      _agregarBebidaAlCarrito();  // ✅ SIN PARÁMETROS
    }
  }

  void _agregarPizzaAlCarrito(CarritoProvider carritoProvider, MenuProvider menuProvider) {
    if (_presentacionSeleccionada == null || _saboresSeleccionados.isEmpty) return;

    final saboresDisponibles = menuProvider.getSaboresByPresentacion(_presentacionSeleccionada!);
    final saboresList = _saboresSeleccionados.entries.toList();

    String nombre;
    double precio;
    String? presentacionNombre;
    int? presentacionId;
    double? pesoKg;

    if (_presentacionSeleccionada == 'PESO') {
      final sabor = saboresDisponibles.firstWhere((s) => s.id == saboresList[0].key);
      nombre = '${sabor.nombre} (${_pesoSeleccionado}kg)';
      precio = _precioCalculado;
      presentacionId = sabor.presentacionId;
      presentacionNombre = 'PESO';
      pesoKg = _pesoSeleccionado;  // ✅ AQUÍ SE ASIGNA EL PESO

      // 🔍 AGREGA ESTE PRINT PARA DEBUG
      print('DEBUG: Peso seleccionado: $_pesoSeleccionado');
      print('DEBUG: pesoKg asignado: $pesoKg');
    } else {
      // Calcular precio promedio
      double sumaPrecios = 0.0;
      for (var saborEntry in saboresList) {
        final sabor = saboresDisponibles.firstWhere((s) => s.id == saborEntry.key);
        sumaPrecios += sabor.precio;
      }
      precio = sumaPrecios / saboresList.length;

      nombre = 'Pizza $_presentacionSeleccionada';
      final primerSabor = saboresDisponibles.firstWhere((s) => s.id == saboresList[0].key);
      presentacionId = primerSabor.presentacionId;
      presentacionNombre = _presentacionSeleccionada;
      pesoKg = null;  // ✅ Para pizzas normales no hay peso
    }

    final item = ItemCarrito(
      productoId: 1,
      nombre: nombre,
      precio: precio,
      categoria: 'Pizza',
      cantidad: _cantidad,
      observaciones: _saboresSeleccionados.values.join(', '),
      presentacionId: presentacionId,
      presentacionNombre: presentacionNombre,
      sabor1Id: saboresList.isNotEmpty ? saboresList[0].key : null,
      sabor1Nombre: saboresList.isNotEmpty ? saboresList[0].value : null,
      sabor2Id: saboresList.length > 1 ? saboresList[1].key : null,
      sabor2Nombre: saboresList.length > 1 ? saboresList[1].value : null,
      sabor3Id: saboresList.length > 2 ? saboresList[2].key : null,
      sabor3Nombre: saboresList.length > 2 ? saboresList[2].value : null,
      pesoKg: pesoKg,  // ✅ PASANDO EL PESO AL ITEM
    );

    // 🔍 AGREGA ESTE PRINT PARA DEBUG
    print('DEBUG: Item creado con pesoKg: ${item.pesoKg}');

    carritoProvider.agregarItem(item);

    setState(() {
      _presentacionSeleccionada = null;
      _saboresSeleccionados.clear();
      _cantidad = 1;
      _pesoSeleccionado = 0.0;
      _precioCalculado = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre agregado al pedido'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _agregarBebidaAlCarrito() {
    if (_bebidaSeleccionada == null) return;

    final carritoProvider = context.read<CarritoProvider>();

    final item = ItemCarrito(
      productoId: _bebidaSeleccionada!.id,
      nombre: _bebidaSeleccionada!.nombre,
      precio: _bebidaSeleccionada!.precio,
      categoria: 'Bebida',
      cantidad: _cantidad,
      presentacionId: _bebidaSeleccionada!.presentacionId,
      presentacionNombre: _bebidaSeleccionada!.presentacion,
      sabor1Id: _bebidaSeleccionada!.id,
    );

    carritoProvider.agregarItem(item);

    setState(() {
      _bebidaSeleccionada = null;
      _cantidad = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.nombre} agregado al pedido'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildResumenPedido([ScrollController? controller]) {
    return Consumer<CarritoProvider>(
      builder: (context, carrito, _) {
        return Column(
          children: [
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
                            style: const TextStyle(
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
        height: 120,
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
  final String presentacion;
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
        width: 140,
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