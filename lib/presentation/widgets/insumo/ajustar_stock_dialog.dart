// lib/presentation/screens/admin/insumos/ajustar_stock_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/insumo_model.dart';
import '../../providers/insumo_provider.dart';

class AjustarStockDialog extends StatefulWidget {
  final int insumoId;
  final String nombreInsumo;

  const AjustarStockDialog({
    super.key,
    required this.insumoId,
    required this.nombreInsumo,
  });

  @override
  State<AjustarStockDialog> createState() => _AjustarStockDialogState();
}

class _AjustarStockDialogState extends State<AjustarStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();

  TipoMovimiento _tipoMovimiento = TipoMovimiento.ENTRADA;
  bool _isLoading = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _ajustarStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<InsumoProvider>();

    // Si es salida, la cantidad debe ser negativa
    double cantidad = double.parse(_cantidadController.text);
    if (_tipoMovimiento == TipoMovimiento.SALIDA) {
      cantidad = -cantidad;
    }

    final success = await provider.ajustarStock(
      AjustarStockRequest(
        insumoId: widget.insumoId,
        cantidad: cantidad,
        motivo: _motivoController.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock ajustado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al ajustar stock'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ajustar Stock'),
          const SizedBox(height: 4),
          Text(
            widget.nombreInsumo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de movimiento
              const Text(
                'Tipo de Movimiento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TipoMovimiento>(
                segments: const [
                  ButtonSegment(
                    value: TipoMovimiento.ENTRADA,
                    label: Text('Entrada'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: TipoMovimiento.SALIDA,
                    label: Text('Salida'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_tipoMovimiento},
                onSelectionChanged: (Set<TipoMovimiento> newSelection) {
                  setState(() {
                    _tipoMovimiento = newSelection.first;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  hintText: '0.00',
                  prefixIcon: Icon(
                    _tipoMovimiento == TipoMovimiento.ENTRADA
                        ? Icons.add
                        : Icons.remove,
                    color: _tipoMovimiento == TipoMovimiento.ENTRADA
                        ? AppColors.success
                        : AppColors.error,
                  ),
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
                    return 'La cantidad es requerida';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Ingrese una cantidad válida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Motivo
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Ej: Compra, Merma, Ajuste de inventario',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El motivo es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tipoMovimiento == TipoMovimiento.ENTRADA
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: _tipoMovimiento == TipoMovimiento.ENTRADA
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tipoMovimiento == TipoMovimiento.ENTRADA
                            ? 'El stock se incrementará'
                            : 'El stock se reducirá',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tipoMovimiento == TipoMovimiento.ENTRADA
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
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
          onPressed: _isLoading ? null : _ajustarStock,
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Ajustar'),
        ),
      ],
    );
  }
}