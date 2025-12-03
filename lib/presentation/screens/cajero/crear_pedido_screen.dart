// lib/presentation/screens/cajero/crear_pedido_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pedido_model.dart';
import '../../providers/producto_provider.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/auth_provider.dart';

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  TipoServicio _tipoServicio = TipoServicio.MESA;
  final List<_PizzaItem> _pizzas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productoProvider = context.read<ProductoProvider>();
    await Future.wait([
      productoProvider.loadProductos(),
      productoProvider.loadSabores(),
      productoProvider.loadPresentaciones(),
    ]);
  }

  void _addPizza() {
    setState(() {
      _pizzas.add(_PizzaItem());
    });
  }

  void _removePizza(int index) {
    setState(() {
      _pizzas.removeAt(index);
    });
  }

  Future<void> _crearPedido() async {
    // Validar que haya al menos una pizza
    if (_pizzas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validar que todas las pizzas estén completas
    for (var pizza in _pizzas) {
      if (!pizza.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los campos de los productos'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final pedidoProvider = context.read<PedidoProvider>();

    final items = _pizzas.map((pizza) {
      return PizzaPedidoItem(
        presentacionId: pizza.presentacionId!,
        sabor1Id: pizza.sabor1Id!,
        sabor2Id: pizza.sabor2Id ?? 0,
        sabor3Id: pizza.sabor3Id ?? 0,
        pesoKg: pizza.pesoKg,
        cantidad: pizza.cantidad,
      );
    }).toList();

    final request = CreatePedidoRequest(
      usuarioId: authProvider.userId ?? 0,
      tipoServicio: _tipoServicio,
      pizzas: items,
    );

    final pedido = await pedidoProvider.createPedido(request);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (pedido != null) {
      Navigator.pop(context, true);

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 32),
              SizedBox(width: 12),
              Text('Pedido Creado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido #${pedido.id} creado exitosamente'),
              const SizedBox(height: 8),
              Text('Total: Bs. ${pedido.total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Estado: ${pedido.getEstadoTexto()}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pedidoProvider.errorMessage ?? 'Error al crear pedido',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
      ),
      body: Column(
        children: [
          // Tipo de servicio
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de Servicio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<TipoServicio>(
                  segments: const [
                    ButtonSegment(
                      value: TipoServicio.MESA,
                      label: Text('Mesa'),
                      icon: Icon(Icons.table_restaurant),
                    ),
                    ButtonSegment(
                      value: TipoServicio.LLEVAR,
                      label: Text('Llevar'),
                      icon: Icon(Icons.shopping_bag),
                    ),
                    ButtonSegment(
                      value: TipoServicio.DELIVERY,
                      label: Text('Delivery'),
                      icon: Icon(Icons.delivery_dining),
                    ),
                  ],
                  selected: {_tipoServicio},
                  onSelectionChanged: (Set<TipoServicio> newSelection) {
                    setState(() {
                      _tipoServicio = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),

          // Lista de pizzas
          Expanded(
            child: _pizzas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_pizza,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay productos agregados',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addPizza,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Producto'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pizzas.length,
              itemBuilder: (context, index) {
                return _PizzaCard(
                  pizza: _pizzas[index],
                  index: index,
                  onRemove: () => _removePizza(index),
                  onChanged: () => setState(() {}),
                );
              },
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_pizzas.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total de productos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_pizzas.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addPizza,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Producto'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _crearPedido,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check),
                        label: const Text('Crear Pedido'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PizzaItem {
  int? presentacionId;
  int? sabor1Id;
  int? sabor2Id;
  int? sabor3Id;
  double? pesoKg;
  int cantidad = 1;

  bool isValid() {
    if (presentacionId == null || sabor1Id == null || cantidad < 1) {
      return false;
    }
    // Si es peso, debe tener pesoKg
    // Esto se valida en el card
    return true;
  }
}

class _PizzaCard extends StatelessWidget {
  final _PizzaItem pizza;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PizzaCard({
    required this.pizza,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Producto #${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Presentación
            Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<int>(
                  value: pizza.presentacionId,
                  decoration: const InputDecoration(
                    labelText: 'Presentación *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: provider.presentaciones.map((presentacion) {
                    return DropdownMenuItem(
                      value: presentacion.id,
                      child: Text(presentacion.getNombre()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    pizza.presentacionId = value;
                    onChanged();
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Sabor 1
            Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<int>(
                  value: pizza.sabor1Id,
                  decoration: const InputDecoration(
                    labelText: 'Sabor Principal *',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: provider.sabores.map((sabor) {
                    return DropdownMenuItem(
                      value: sabor.id,
                      child: Text(sabor.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    pizza.sabor1Id = value;
                    onChanged();
                  },
                );
              },
            ),

            // Mostrar sabor 2 y 3 según la presentación
            if (pizza.presentacionId != null) ...[
              Consumer<ProductoProvider>(
                builder: (context, provider, _) {
                  final presentacion = provider.getPresentacionById(
                    pizza.presentacionId!,
                  );

                  if (presentacion != null && presentacion.maxSabores >= 2) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          value: pizza.sabor2Id,
                          decoration: const InputDecoration(
                            labelText: 'Sabor 2 (Opcional)',
                            prefixIcon: Icon(Icons.restaurant_menu),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin segundo sabor'),
                            ),
                            ...provider.sabores.map((sabor) {
                              return DropdownMenuItem(
                                value: sabor.id,
                                child: Text(sabor.nombre),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            pizza.sabor2Id = value;
                            onChanged();
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Consumer<ProductoProvider>(
                builder: (context, provider, _) {
                  final presentacion = provider.getPresentacionById(
                    pizza.presentacionId!,
                  );

                  if (presentacion != null && presentacion.maxSabores >= 3) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          value: pizza.sabor3Id,
                          decoration: const InputDecoration(
                            labelText: 'Sabor 3 (Opcional)',
                            prefixIcon: Icon(Icons.restaurant_menu),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin tercer sabor'),
                            ),
                            ...provider.sabores.map((sabor) {
                              return DropdownMenuItem(
                                value: sabor.id,
                                child: Text(sabor.nombre),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            pizza.sabor3Id = value;
                            onChanged();
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            // Peso (si es necesario)
            if (pizza.presentacionId != null) ...[
              Consumer<ProductoProvider>(
                builder: (context, provider, _) {
                  final presentacion = provider.getPresentacionById(
                    pizza.presentacionId!,
                  );

                  if (presentacion != null && presentacion.usaPeso) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg) *',
                            prefixIcon: Icon(Icons.scale),
                            suffixText: 'kg',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,3}'),
                            ),
                          ],
                          onChanged: (value) {
                            pizza.pesoKg = double.tryParse(value);
                            onChanged();
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            const SizedBox(height: 16),

            // Cantidad
            Row(
              children: [
                const Text(
                  'Cantidad:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: pizza.cantidad > 1
                      ? () {
                    pizza.cantidad--;
                    onChanged();
                  }
                      : null,
                ),
                Text(
                  '${pizza.cantidad}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    pizza.cantidad++;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}