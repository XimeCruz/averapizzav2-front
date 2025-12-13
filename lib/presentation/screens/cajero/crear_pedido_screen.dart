// lib/presentation/screens/cajero/crear_pedido_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cajero_layout.dart';
import 'cobro_screen.dart';

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  String? _categoriaSeleccionada;
  final List<ItemPedido> _items = [];
  final TextEditingController _notasController = TextEditingController();

  // Simulación de datos - En producción vendrían del backend
  final Map<String, List<Map<String, dynamic>>> _productos = {
    'PESO': [
      {'id': 1, 'nombre': 'Muzzarella', 'precio': 12.50},
      {'id': 2, 'nombre': 'Napolitana', 'precio': 14.00},
      {'id': 3, 'nombre': 'Jamón y Morrones', 'precio': 15.50},
      {'id': 4, 'nombre': 'Fugazzeta', 'precio': 13.50},
      {'id': 5, 'nombre': 'Calabresa', 'precio': 14.50},
    ],
    'REDONDA': [
      {'id': 6, 'nombre': 'Muzzarella', 'precio': 18.00},
      {'id': 7, 'nombre': 'Napolitana', 'precio': 20.00},
      {'id': 8, 'nombre': 'Especial', 'precio': 22.00},
      {'id': 9, 'nombre': 'Calabresa', 'precio': 19.00},
      {'id': 10, 'nombre': 'Jamón y Morrones', 'precio': 21.00},
    ],
    'BANDEJA': [
      {'id': 11, 'nombre': 'Muzzarella Grande', 'precio': 35.00},
      {'id': 12, 'nombre': 'Napolitana Grande', 'precio': 38.00},
      {'id': 13, 'nombre': 'Especial Familiar', 'precio': 42.00},
      {'id': 14, 'nombre': 'Mixta Familiar', 'precio': 45.00},
    ],
  };

  final List<Map<String, dynamic>> _bebidas = [
    {'id': 101, 'nombre': 'Coca-Cola 500ml', 'precio': 3.50},
    {'id': 102, 'nombre': 'Coca-Cola 1.5L', 'precio': 5.00},
    {'id': 103, 'nombre': 'Sprite 500ml', 'precio': 3.50},
    {'id': 104, 'nombre': 'Agua Mineral', 'precio': 2.50},
    {'id': 105, 'nombre': 'Fanta 500ml', 'precio': 3.50},
    {'id': 106, 'nombre': 'Cerveza Quilmes', 'precio': 4.00},
  ];

  double get _total {
    return _items.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
  }

  void _agregarItem(Map<String, dynamic> producto, String categoria) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == producto['id']);
      if (index >= 0) {
        _items[index].cantidad++;
      } else {
        _items.add(ItemPedido(
          id: producto['id'],
          nombre: producto['nombre'],
          precio: producto['precio'],
          cantidad: 1,
          categoria: categoria,
        ));
      }
    });
  }

  void _actualizarCantidad(int index, int delta) {
    setState(() {
      _items[index].cantidad += delta;
      if (_items[index].cantidad <= 0) {
        _items.removeAt(index);
      }
    });
  }

  void _irACobro() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto al pedido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CobroScreen(
          items: _items,
          notas: _notasController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return CajeroLayout(
      title: 'Crear Nuevo Pedido',
      currentRoute: '/cajero/crear-pedido',
      child: Row(
        children: [
          // Panel principal - Selección de productos
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: Column(
                children: [
                  // Selector de categorías
                  _buildCategorySelector(),

                  // Lista de productos
                  Expanded(
                    child: _categoriaSeleccionada == null
                        ? _buildEmptyState()
                        : _buildProductList(),
                  ),
                ],
              ),
            ),
          ),

          // Panel lateral - Carrito
          if (isDesktop)
            Container(
              width: 380,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  left: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: _buildCart(),
            ),
        ],
      ),
      floatingActionButton: !isDesktop && _items.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _irACobro,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.payment),
        label: Text(
          'Cobrar \$${_total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      )
          : null,
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona la Categoría',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CategoryCard(
                  emoji: '⚖️',
                  title: 'PESO',
                  subtitle: '${_productos['PESO']!.length} opciones',
                  isSelected: _categoriaSeleccionada == 'PESO',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                  ),
                  onTap: () {
                    setState(() {
                      _categoriaSeleccionada = 'PESO';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryCard(
                  emoji: '🍕',
                  title: 'REDONDA',
                  subtitle: '${_productos['REDONDA']!.length} opciones',
                  isSelected: _categoriaSeleccionada == 'REDONDA',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFE64A19)],
                  ),
                  onTap: () {
                    setState(() {
                      _categoriaSeleccionada = 'REDONDA';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryCard(
                  emoji: '📦',
                  title: 'BANDEJA',
                  subtitle: '${_productos['BANDEJA']!.length} opciones',
                  isSelected: _categoriaSeleccionada == 'BANDEJA',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF57C00), Color(0xFFFFB300)],
                  ),
                  onTap: () {
                    setState(() {
                      _categoriaSeleccionada = 'BANDEJA';
                    });
                  },
                ),
              ),
            ],
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
            Icons.category_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona una categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige entre Pizza por Peso, Redonda o Bandeja',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final productos = _productos[_categoriaSeleccionada]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pizzas
          Text(
            'Pizzas - $_categoriaSeleccionada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              final cantidadEnCarrito = _items
                  .firstWhere(
                    (item) => item.id == producto['id'],
                orElse: () => ItemPedido(
                  id: 0,
                  nombre: '',
                  precio: 0,
                  cantidad: 0,
                  categoria: '',
                ),
              )
                  .cantidad;

              return _ProductCard(
                nombre: producto['nombre'],
                precio: producto['precio'],
                cantidadEnCarrito: cantidadEnCarrito,
                onTap: () => _agregarItem(producto, _categoriaSeleccionada!),
              );
            },
          ),
          const SizedBox(height: 32),

          // Bebidas
          Text(
            'Bebidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _bebidas.length,
            itemBuilder: (context, index) {
              final bebida = _bebidas[index];
              final cantidadEnCarrito = _items
                  .firstWhere(
                    (item) => item.id == bebida['id'],
                orElse: () => ItemPedido(
                  id: 0,
                  nombre: '',
                  precio: 0,
                  cantidad: 0,
                  categoria: '',
                ),
              )
                  .cantidad;

              return _ProductCard(
                nombre: bebida['nombre'],
                precio: bebida['precio'],
                cantidadEnCarrito: cantidadEnCarrito,
                onTap: () => _agregarItem(bebida, 'BEBIDAS'),
                icon: Icons.local_drink,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        // Header del carrito
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
                  Icons.shopping_cart,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_items.length} productos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (_items.isNotEmpty)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _items.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Vaciar carrito',
                ),
            ],
          ),
        ),

        // Lista de items
        Expanded(
          child: _items.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carrito vacío',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _CartItem(
                item: item,
                onIncrease: () => _actualizarCantidad(index, 1),
                onDecrease: () => _actualizarCantidad(index, -1),
                onDelete: () => _actualizarCantidad(index, -item.cantidad),
              );
            },
          ),
        ),

        // Notas para cocina
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          child: TextField(
            controller: _notasController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notas para cocina',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              hintText: 'Ej: Sin cebolla, bien cocida...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
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
        ),

        // Total y botón de cobrar
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
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
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
                  onPressed: _items.isEmpty ? null : _irACobro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Ir a Cobrar',
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
    _notasController.dispose();
    super.dispose();
  }
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected ? gradient : null,
        color: isSelected ? null : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFF3A3A3A),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final String nombre;
  final double precio;
  final int cantidadEnCarrito;
  final VoidCallback onTap;
  final IconData? icon;

  const _ProductCard({
    required this.nombre,
    required this.precio,
    required this.cantidadEnCarrito,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cantidadEnCarrito > 0
              ? AppColors.secondary
              : const Color(0xFF2A2A2A),
          width: cantidadEnCarrito > 0 ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon ?? Icons.local_pizza,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    if (cantidadEnCarrito > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$cantidadEnCarrito',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${precio.toStringAsFixed(2)}',
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
      ),
    );
  }
}

// Cart Item Widget
class _CartItem extends StatelessWidget {
  final ItemPedido item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const _CartItem({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoria,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove, color: Colors.white),
                      iconSize: 18,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.cantidad}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add, color: AppColors.secondary),
                      iconSize: 18,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '\$${(item.precio * item.cantidad).toStringAsFixed(2)}',
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
  }
}

// Modelo de Item de Pedido
class ItemPedido {
  final int id;
  final String nombre;
  final double precio;
  int cantidad;
  final String categoria;

  ItemPedido({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });
}