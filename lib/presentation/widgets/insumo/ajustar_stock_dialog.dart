// lib/presentation/widgets/insumo/ajustar_stock_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/insumo_model.dart';
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al ajustar stock'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ícono
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajustar Stock',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.nombreInsumo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tipo de movimiento
                const Text(
                  'Tipo de Movimiento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MovementTypeButton(
                        label: 'Entrada',
                        icon: Icons.add_circle_outline,
                        color: AppColors.success,
                        isSelected: _tipoMovimiento == TipoMovimiento.ENTRADA,
                        onTap: () {
                          setState(() {
                            _tipoMovimiento = TipoMovimiento.ENTRADA;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MovementTypeButton(
                        label: 'Salida',
                        icon: Icons.remove_circle_outline,
                        color: AppColors.error,
                        isSelected: _tipoMovimiento == TipoMovimiento.SALIDA,
                        onTap: () {
                          setState(() {
                            _tipoMovimiento = TipoMovimiento.SALIDA;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cantidad
                TextFormField(
                  controller: _cantidadController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Cantidad *',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(
                      _tipoMovimiento == TipoMovimiento.ENTRADA
                          ? Icons.add
                          : Icons.remove,
                      color: _tipoMovimiento == TipoMovimiento.ENTRADA
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _tipoMovimiento == TipoMovimiento.ENTRADA
                            ? AppColors.success
                            : AppColors.error,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
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

                const SizedBox(height: 20),

                // Motivo
                TextFormField(
                  controller: _motivoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Motivo *',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: 'Ej: Compra, Merma, Ajuste de inventario',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: const Icon(Icons.notes, color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El motivo es requerido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _tipoMovimiento == TipoMovimiento.ENTRADA
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tipoMovimiento == TipoMovimiento.ENTRADA
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _tipoMovimiento == TipoMovimiento.ENTRADA
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 24,
                        color: _tipoMovimiento == TipoMovimiento.ENTRADA
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tipoMovimiento == TipoMovimiento.ENTRADA
                                  ? 'Stock se incrementará'
                                  : 'Stock se reducirá',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _tipoMovimiento == TipoMovimiento.ENTRADA
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tipoMovimiento == TipoMovimiento.ENTRADA
                                  ? 'La cantidad ingresada se sumará al stock actual'
                                  : 'La cantidad ingresada se restará del stock actual',
                              style: TextStyle(
                                fontSize: 11,
                                color: (_tipoMovimiento == TipoMovimiento.ENTRADA
                                    ? AppColors.success
                                    : AppColors.error)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _ajustarStock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoMovimiento == TipoMovimiento.ENTRADA
                              ? AppColors.success
                              : AppColors.error,
                          disabledBackgroundColor: (_tipoMovimiento == TipoMovimiento.ENTRADA
                              ? AppColors.success
                              : AppColors.error)
                              .withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tipoMovimiento == TipoMovimiento.ENTRADA
                                  ? Icons.add
                                  : Icons.remove,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ajustar Stock',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para los botones de tipo de movimiento
class _MovementTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MovementTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A2A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}