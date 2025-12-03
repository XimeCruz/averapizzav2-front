// lib/presentation/screens/admin/productos/producto_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  TipoProducto _tipoProducto = TipoProducto.PIZZA;
  bool _tieneSabores = true;

  bool get isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nombreController.text = widget.producto!.nombre;
      _tipoProducto = widget.producto!.tipoProducto;
      _tieneSabores = widget.producto!.tieneSabores;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _saveProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductoProvider>();

    final request = CreateProductoRequest(
      nombre: _nombreController.text.trim(),
      tipoProducto: _tipoProducto,
      tieneSabores: _tieneSabores,
    );

    bool success;
    if (isEditing) {
      success = await provider.updateProducto(widget.producto!.id, request);
    } else {
      success = await provider.createProducto(request);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Producto actualizado correctamente'
                : 'Producto creado correctamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al guardar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  IconData _getIconByTipo(TipoProducto tipo) {
    switch (tipo) {
      case TipoProducto.PIZZA:
        return Icons.local_pizza;
      case TipoProducto.BEBIDA:
        return Icons.local_drink;
      case TipoProducto.OTRO:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'Ej: Pizza artesanal',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Tipo de Producto
                    const Text(
                      'Tipo de Producto *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      children: TipoProducto.values.map((tipo) {
                        final isSelected = _tipoProducto == tipo;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconByTipo(tipo),
                                size: 18,
                                color: isSelected ? Colors.white : null,
                              ),
                              const SizedBox(width: 8),
                              Text(tipo.name),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _tipoProducto = tipo;
                                // Pizza siempre tiene sabores
                                if (tipo == TipoProducto.PIZZA) {
                                  _tieneSabores = true;
                                }
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ¿Tiene sabores?
                    SwitchListTile(
                      title: const Text(
                        '¿Tiene sabores?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _tieneSabores
                            ? 'Este producto podrá tener múltiples sabores'
                            : 'Este producto no tendrá sabores',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _tieneSabores,
                      onChanged: _tipoProducto == TipoProducto.PIZZA
                          ? null // Pizza siempre tiene sabores
                          : (value) {
                        setState(() {
                          _tieneSabores = value;
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_tipoProducto == TipoProducto.PIZZA) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.info,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Las pizzas siempre tienen sabores',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
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
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Consumer<ProductoProvider>(
                    builder: (context, provider, _) {
                      final isLoading = provider.status == ProductoStatus.loading;

                      return ElevatedButton(
                        onPressed: isLoading ? null : _saveProducto,
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(isEditing ? 'Actualizar' : 'Guardar'),
                      );
                    },
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