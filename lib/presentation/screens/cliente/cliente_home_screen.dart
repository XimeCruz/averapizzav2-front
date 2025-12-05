import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/producto_provider.dart';
import '../auth/login_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  TipoProducto? _tipoSeleccionado;
  Producto? _productoSeleccionado;
  final List<_ItemCarrito> _carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    await context.read<ProductoProvider>().loadProductos();
  }

  void _seleccionarTipo(TipoProducto tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      _productoSeleccionado = null;
    });
  }

  void _seleccionarProducto(Producto producto) {
    setState(() {
      _productoSeleccionado = producto;
    });
  }

  void _volverAlMenu() {
    setState(() {
      _tipoSeleccionado = null;
      _productoSeleccionado = null;
    });
  }

  void _agregarAlCarrito(_ItemCarrito item) {
    setState(() {
      _carrito.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.descripcion} agregado al carrito'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _verCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CarritoSheet(
        items: _carrito,
        onEliminar: (index) {
          setState(() {
            _carrito.removeAt(index);
          });
          Navigator.pop(context);
          if (_carrito.isNotEmpty) {
            _verCarrito();
          }
        },
        onConfirmar: () {
          // TODO: Crear pedido
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido creado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _carrito.clear();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('A Vera Pizza Italia'),
        leading: _tipoSeleccionado != null || _productoSeleccionado != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _volverAlMenu,
        )
            : null,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _carrito.isEmpty ? null : _verCarrito,
              ),
              if (_carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_carrito.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                'Hola, ${authProvider.userName ?? "Cliente"}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _productoSeleccionado != null
          ? _VistaSeleccionPresentacion(
        producto: _productoSeleccionado!,
        onAgregar: _agregarAlCarrito,
      )
          : _tipoSeleccionado != null
          ? _VistaProductosPorTipo(
        tipo: _tipoSeleccionado!,
        onSeleccionar: _seleccionarProducto,
      )
          : _VistaMenuPrincipal(
        onSeleccionar: _seleccionarTipo,
      ),
    );
  }
}

// ========== VISTA MENÚ PRINCIPAL ==========
class _VistaMenuPrincipal extends StatelessWidget {
  final Function(TipoProducto) onSeleccionar;

  const _VistaMenuPrincipal({required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué te gustaría pedir?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _TipoProductoCard(
                  tipo: TipoProducto.PIZZA,
                  titulo: 'Pizzas',
                  icono: Icons.local_pizza,
                  color: AppColors.primary,
                  onTap: () => onSeleccionar(TipoProducto.PIZZA),
                ),
                _TipoProductoCard(
                  tipo: TipoProducto.BEBIDA,
                  titulo: 'Bebidas',
                  icono: Icons.local_drink,
                  color: Colors.blue,
                  onTap: () => onSeleccionar(TipoProducto.BEBIDA),
                ),
                _TipoProductoCard(
                  tipo: TipoProducto.OTRO,
                  titulo: 'Otros',
                  icono: Icons.restaurant,
                  color: Colors.orange,
                  onTap: () => onSeleccionar(TipoProducto.OTRO),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoProductoCard extends StatelessWidget {
  final TipoProducto tipo;
  final String titulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _TipoProductoCard({
    required this.tipo,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== VISTA PRODUCTOS POR TIPO ==========
class _VistaProductosPorTipo extends StatelessWidget {
  final TipoProducto tipo;
  final Function(Producto) onSeleccionar;

  const _VistaProductosPorTipo({
    required this.tipo,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        if (provider.status == ProductoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final productos = provider.productos
            .where((p) => p.tipoProducto == tipo)
            .toList();

        if (productos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay ${tipo.name.toLowerCase()}s disponibles',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return _ProductoCard(
              producto: producto,
              onTap: () => onSeleccionar(producto),
            );
          },
        );
      },
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _ProductoCard({
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getColorByTipo(producto.tipoProducto).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconByTipo(producto.tipoProducto),
                  size: 40,
                  color: _getColorByTipo(producto.tipoProducto),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto.tieneSabores
                          ? 'Varios sabores disponibles'
                          : 'Producto único',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorByTipo(TipoProducto tipo) {
    switch (tipo) {
      case TipoProducto.PIZZA:
        return AppColors.primary;
      case TipoProducto.BEBIDA:
        return Colors.blue;
      case TipoProducto.OTRO:
        return Colors.orange;
    }
  }

  IconData _getIconByTipo(TipoProducto tipo) {
    switch (tipo) {
      case TipoProducto.PIZZA:
        return Icons.local_pizza;
      case TipoProducto.BEBIDA:
        return Icons.local_drink;
      case TipoProducto.OTRO:
        return Icons.restaurant;
    }
  }
}

// ========== VISTA SELECCIÓN PRESENTACIÓN Y SABORES ==========
class _VistaSeleccionPresentacion extends StatefulWidget {
  final Producto producto;
  final Function(_ItemCarrito) onAgregar;

  const _VistaSeleccionPresentacion({
    required this.producto,
    required this.onAgregar,
  });

  @override
  State<_VistaSeleccionPresentacion> createState() =>
      _VistaSeleccionPresentacionState();
}

class _VistaSeleccionPresentacionState
    extends State<_VistaSeleccionPresentacion> {
  PresentacionProducto? _presentacionSeleccionada;
  List<SaborPizza> _saboresDisponibles = [];
  final List<SaborPizza> _saboresSeleccionados = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final provider = context.read<ProductoProvider>();

    await provider.loadPresentacionesByProducto(widget.producto.id);

    // if (widget.producto.tieneSabores) {
    //   // Cargar todos los sabores y filtrar por producto
    //   await provider.loadSabores();
    //   setState(() {
    //     _saboresDisponibles = provider.sabores
    //         .where((s) => s.productoId == widget.producto.id)
    //         .toList();
    //   });
    // }
    if (widget.producto.tieneSabores) {
      // Cargar sabores filtrados por producto
      await provider.loadSaboresByProducto(widget.producto.id);
      setState(() {
        _saboresDisponibles = provider.sabores;
      });
    }
    setState(() => _isLoading = false);
  }

  void _seleccionarPresentacion(PresentacionProducto presentacion) {
    setState(() {
      _presentacionSeleccionada = presentacion;
      _saboresSeleccionados.clear();
    });
  }

  void _toggleSabor(SaborPizza sabor) {
    setState(() {
      if (_saboresSeleccionados.contains(sabor)) {
        _saboresSeleccionados.remove(sabor);
      } else {
        final maxSabores = _presentacionSeleccionada?.maxSabores ?? 1;
        if (_saboresSeleccionados.length < maxSabores) {
          _saboresSeleccionados.add(sabor);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Solo puedes seleccionar $maxSabores sabor${maxSabores > 1 ? 'es' : ''}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  Future<void> _agregarAlCarrito() async {
    if (_presentacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una presentación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (widget.producto.tieneSabores && _saboresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un sabor'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Calcular precio (simplificado - en producción deberías obtenerlo del backend)
    double precio = _presentacionSeleccionada?.precioBase ?? 0;

    final descripcion = widget.producto.tieneSabores
        ? '${widget.producto.nombre} ${_presentacionSeleccionada!.tipo.name} - ${_saboresSeleccionados.map((s) => s.nombre).join(', ')}'
        : '${widget.producto.nombre} ${_presentacionSeleccionada!.tipo.name}';

    final item = _ItemCarrito(
      productoId: widget.producto.id,
      presentacionId: _presentacionSeleccionada!.id,
      saboresIds: _saboresSeleccionados.map((s) => s.id).toList(),
      descripcion: descripcion,
      precio: precio,
    );

    widget.onAgregar(item);

    // Resetear selección
    setState(() {
      _presentacionSeleccionada = null;
      _saboresSeleccionados.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        final presentaciones = provider.presentaciones;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.producto.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Selección de Presentación
              Text(
                'Selecciona la presentación',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...presentaciones.map((presentacion) {
                final isSelected = _presentacionSeleccionada == presentacion;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: isSelected ? AppColors.primary : Colors.grey[300],
                    ),
                    title: Text(
                      presentacion.tipo.name,
                      style: TextStyle(
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'Hasta ${presentacion.maxSabores} sabor${presentacion.maxSabores > 1 ? 'es' : ''}',
                    ),
                    trailing: presentacion.precioBase != null
                        ? Text(
                      'Bs. ${presentacion.precioBase!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                        : null,
                    onTap: () => _seleccionarPresentacion(presentacion),
                  ),
                );
              }),

              // Selección de Sabores
              if (_presentacionSeleccionada != null &&
                  widget.producto.tieneSabores) ...[
                const SizedBox(height: 24),
                Text(
                  'Selecciona ${_presentacionSeleccionada!.maxSabores > 1 ? 'los sabores' : 'el sabor'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._saboresDisponibles.map((sabor) {
                  final isSelected = _saboresSeleccionados.contains(sabor);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color:
                    isSelected ? AppColors.primary.withOpacity(0.1) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(
                          color: AppColors.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color:
                        isSelected ? AppColors.primary : Colors.grey[300],
                      ),
                      title: Text(
                        sabor.nombre,
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: sabor.descripcion != null
                          ? Text(sabor.descripcion!)
                          : null,
                      onTap: () => _toggleSabor(sabor),
                    ),
                  );
                }),
              ],

              // Botón agregar
              if (_presentacionSeleccionada != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _agregarAlCarrito,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar al carrito'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ========== CARRITO SHEET ==========
class _CarritoSheet extends StatelessWidget {
  final List<_ItemCarrito> items;
  final Function(int) onEliminar;
  final VoidCallback onConfirmar;

  const _CarritoSheet({
    required this.items,
    required this.onEliminar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.precio);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu Pedido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(item.descripcion),
                        subtitle: Text(
                          'Bs. ${item.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => onEliminar(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Bs. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onConfirmar,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Pedido'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========== MODELO DE ITEM DEL CARRITO ==========
class _ItemCarrito {
  final int productoId;
  final int presentacionId;
  final List<int> saboresIds;
  final String descripcion;
  final double precio;

  _ItemCarrito({
    required this.productoId,
    required this.presentacionId,
    required this.saboresIds,
    required this.descripcion,
    required this.precio,
  });
}