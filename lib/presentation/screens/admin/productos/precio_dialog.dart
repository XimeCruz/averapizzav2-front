// lib/presentation/screens/admin/productos/precio_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';

class PrecioDialog extends StatefulWidget {
  final int saborId;
  final PrecioSaborPresentacion? precio;

  const PrecioDialog({
    super.key,
    required this.saborId,
    this.precio,
  });

  @override
  State<PrecioDialog> createState() => _PrecioDialogState();
}

class _PrecioDialogState extends State<PrecioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();

  PresentacionProducto? _presentacionSeleccionada;
  bool _isLoading = false;

  bool get isEditing => widget.precio != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _precioController.text = widget.precio!.precio.toString();
      _presentacionSeleccionada = widget.precio!.presentacion;
    }
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _savePrecio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_presentacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una presentación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ProductoProvider>();
    final request = CreatePrecioRequest(
      presentacionId: _presentacionSeleccionada!.id,
      precio: double.parse(_precioController.text),
    );

    bool success;
    if (isEditing) {
      success = await provider.updatePrecio(widget.precio!.id, request);
    } else {
      success = await provider.createPrecio(widget.saborId, request);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Precio actualizado' : 'Precio agregado',
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Editar Precio' : 'Agregar Precio'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presentación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<ProductoProvider>(
                builder: (context, provider, _) {
                  if (provider.presentaciones.isEmpty) {
                    return const Text(
                      'No hay presentaciones disponibles',
                      style: TextStyle(color: AppColors.error),
                    );
                  }

                  return DropdownButtonFormField<PresentacionProducto>(
                    value: _presentacionSeleccionada,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona una presentación',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: provider.presentaciones.map((presentacion) {
                      return DropdownMenuItem(
                        value: presentacion,
                        child: Text(presentacion.getNombre()),
                      );
                    }).toList(),
                    onChanged: isEditing
                        ? null
                        : (value) {
                      setState(() {
                        _presentacionSeleccionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una presentación';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _precioController,
                decoration: InputDecoration(
                  labelText: 'Precio',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: _presentacionSeleccionada?.usaPeso ?? false
                      ? 'por kg'
                      : 'por unidad',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es requerido';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePrecio,
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}