// lib/presentation/screens/admin/insumos/insumo_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/insumo_model.dart';
import '../../../providers/insumo_provider.dart';

class InsumoFormScreen extends StatefulWidget {
  final Insumo? insumo;

  const InsumoFormScreen({super.key, this.insumo});

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _unidadMedidaController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _stockActualController = TextEditingController();

  bool get isEditing => widget.insumo != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nombreController.text = widget.insumo!.nombre;
      _unidadMedidaController.text = widget.insumo!.unidadMedida;
      _stockMinimoController.text = widget.insumo!.stockMinimo.toString();
      _stockActualController.text = widget.insumo!.stockActual.toString();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _unidadMedidaController.dispose();
    _stockMinimoController.dispose();
    _stockActualController.dispose();
    super.dispose();
  }

  Future<void> _saveInsumo() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InsumoProvider>();
    bool success;

    if (isEditing) {
      success = await provider.updateInsumo(
        widget.insumo!.id,
        UpdateInsumoRequest(
          nombre: _nombreController.text.trim(),
          unidadMedida: _unidadMedidaController.text.trim(),
          stockMinimo: double.parse(_stockMinimoController.text),
          stockActual: double.parse(_stockActualController.text),
        ),
      );
    } else {
      success = await provider.createInsumo(
        CreateInsumoRequest(
          nombre: _nombreController.text.trim(),
          unidadMedida: _unidadMedidaController.text.trim(),
          stockMinimo: double.parse(_stockMinimoController.text),
          stockActual: double.parse(_stockActualController.text),
        ),
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Insumo actualizado correctamente'
                : 'Insumo creado correctamente',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Insumo' : 'Nuevo Insumo'),
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
                      'Información del Insumo',
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
                        labelText: 'Nombre del Insumo *',
                        hintText: 'Ej: Queso mozzarella',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Unidad de Medida
                    TextFormField(
                      controller: _unidadMedidaController,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de Medida *',
                        hintText: 'Ej: kg, litros, unidad',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La unidad de medida es requerida';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Inventario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock Mínimo
                    TextFormField(
                      controller: _stockMinimoController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Mínimo *',
                        hintText: 'Ej: 5',
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El stock mínimo es requerido';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Ingrese un número válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Stock Actual
                    TextFormField(
                      controller: _stockActualController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Actual *',
                        hintText: 'Ej: 16',
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El stock actual es requerido';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Ingrese un número válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Vista previa del estado
                    Builder(
                      builder: (context) {
                        final stockActual = double.tryParse(
                          _stockActualController.text,
                        ) ?? 0;
                        final stockMinimo = double.tryParse(
                          _stockMinimoController.text,
                        ) ?? 0;

                        if (stockActual == 0 && stockMinimo == 0) {
                          return const SizedBox.shrink();
                        }

                        final esBajo = stockActual <= stockMinimo;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esBajo
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: esBajo ? AppColors.error : AppColors.success,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                esBajo ? Icons.warning_amber : Icons.check_circle,
                                color: esBajo ? AppColors.error : AppColors.success,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  esBajo
                                      ? 'Stock bajo el mínimo requerido'
                                      : 'Stock en nivel adecuado',
                                  style: TextStyle(
                                    color: esBajo ? AppColors.error : AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
                  child: Consumer<InsumoProvider>(
                    builder: (context, provider, _) {
                      final isLoading = provider.status == InsumoStatus.loading;

                      return ElevatedButton(
                        onPressed: isLoading ? null : _saveInsumo,
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