import 'package:flutter/material.dart';

import '../../../data/repositories/producto_repository.dart';

class PublicCatalogScreen extends StatefulWidget {
  const PublicCatalogScreen({super.key});

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  final ProductoRepository _repository = ProductoRepository();
  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'TODOS';

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productos = await _repository.getProductosPublicos();

      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'TODOS') {
      return _productos;
    }
    return _productos
        .where((p) => p['tipoProducto'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF1C1C1C),
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.white),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   // title: Row(
      //   //   children: [
      //   //     // const Icon(Icons.local_pizza, color: Color(0xFF4ADE80), size: 28),
      //   //     // const SizedBox(width: 12),
      //   //     const Text(
      //   //       'A Vera Pizza',
      //   //       style: TextStyle(
      //   //         color: Color(0xFF4ADE80),
      //   //         fontSize: 24,
      //   //         fontWeight: FontWeight.bold,
      //   //       ),
      //   //     ),
      //   //   ],
      //   // ),
      // ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4ADE80),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProductos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Category filter
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('TODOS'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('PIZZA'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('BEBIDA'),
                ],
              ),
            ),
          ),

          // Products grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Text(
                'No hay productos disponibles',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final producto = _filteredProducts[index];
                return _buildProductCard(producto);
              },
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Listo para ordenar?',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Iniciar sesión para ordenar',
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
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4ADE80) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ADE80) : const Color(0xFF3A3A3A),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> producto) {
    final isPizza = producto['tipoProducto'] == 'PIZZA';
    final imageUrl = isPizza
        ? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400'
        : 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2A2A2A),
                    child: Icon(
                      isPizza ? Icons.local_pizza : Icons.local_drink,
                      size: 48,
                      color: const Color(0xFF4ADE80),
                    ),
                  );
                },
              ),
            ),
          ),

          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['sabor'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Text(
                  //   producto['producto'] ?? '',
                  //   style: TextStyle(
                  //     color: Colors.grey[400],
                  //     fontSize: 12,
                  //   ),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  // const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatPresentacion(producto['presentacion'] ?? ''),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bs. ${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFF4ADE80).withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: const Icon(
                      //     Icons.add_shopping_cart,
                      //     color: Color(0xFF4ADE80),
                      //     size: 18,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPresentacion(String presentacion) {
    if (presentacion.startsWith('L_')) {
      return '${presentacion.substring(2)}L';
    } else if (presentacion.startsWith('ML_')) {
      return '${presentacion.substring(3)}ml';
    }
    return presentacion;
  }
}