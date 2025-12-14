// lib/presentation/widgets/cajero/selector_sabores_dialog.dart
// MODIFICADO para soportar peso preseleccionado

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/producto_model.dart';
import 'package:flutter/services.dart';

class SelectorSaboresDialog extends StatefulWidget {
  final List<ProductoDto> saboresDisponibles;
  final String presentacion;
  final List<ProductoDto>? saboresPreseleccionados;
  final double? pesoPreseleccionado;
  final void Function(
    List<ProductoDto>, {
    double peso,
  }) onConfirmar;

  const SelectorSaboresDialog({
    super.key,
    required this.saboresDisponibles,
    required this.presentacion,
    this.saboresPreseleccionados,
    this.pesoPreseleccionado,
    required this.onConfirmar,
  });

  @override
  State<SelectorSaboresDialog> createState() => _SelectorSaboresDialogState();
}

class _SelectorSaboresDialogState extends State<SelectorSaboresDialog> {
  late final List<ProductoDto> _saboresSeleccionados;
  final TextEditingController _pesoController = TextEditingController();
  double _pesoKg = 0.0;

  @override
  void initState() {
    super.initState();
    // Inicializar con los sabores preseleccionados si existen
    _saboresSeleccionados = widget.saboresPreseleccionados != null
        ? List<ProductoDto>.from(widget.saboresPreseleccionados!)
        : [];

    if (widget.pesoPreseleccionado != null && widget.pesoPreseleccionado! > 0) {
      _pesoKg = widget.pesoPreseleccionado!;
      _pesoController.text = _pesoKg.toStringAsFixed(2);
      
      print('=== PESO INICIALIZADO ===');
      print('Peso: $_pesoKg kg');
      print('=========================');
    }
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  int get _maxSabores {
    switch (widget.presentacion) {
      case 'PESO':
        return 1;
      case 'REDONDA':
        return 2;
      case 'BANDEJA':
        return 3;
      default:
        return 1;
    }
  }

  String get _titulo {
    switch (widget.presentacion) {
      case 'PESO':
        return 'Selecciona el Sabor';
      case 'REDONDA':
        return 'Selecciona hasta 2 Sabores';
      case 'BANDEJA':
        return 'Selecciona hasta 3 Sabores';
      default:
        return 'Selecciona Sabores';
    }
  }

  bool _estaSeleccionado(ProductoDto sabor) {
    return _saboresSeleccionados.any((s) => s.id == sabor.id);
  }

  void _toggleSabor(ProductoDto sabor) {
    setState(() {
      if (_estaSeleccionado(sabor)) {
        _saboresSeleccionados.removeWhere((s) => s.id == sabor.id);
      } else {
        if (_saboresSeleccionados.length < _maxSabores) {
          _saboresSeleccionados.add(sabor);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Máximo $_maxSabores sabores permitidos'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  String _calcularPrecioPromedio() {
    if (_saboresSeleccionados.isEmpty) return 'Bs. 0.00';

    final total = _saboresSeleccionados.fold<double>(
      0.0,
      (sum, sabor) => sum + sabor.precio,
    );
    final promedio = total / _saboresSeleccionados.length;

    // Mostrar el cálculo
    final precios = _saboresSeleccionados
        .map((s) => s.precio.toStringAsFixed(2))
        .join(' + ');

    return '($precios) ÷ ${_saboresSeleccionados.length} = Bs. ${promedio.toStringAsFixed(2)}';
  }

  String _calcularPrecioTotal() {
    if (_saboresSeleccionados.isEmpty || _pesoKg <= 0) return '';

    final precioPromedio = _saboresSeleccionados.fold<double>(
          0.0,
          (sum, sabor) => sum + sabor.precio,
        ) /
        _saboresSeleccionados.length;

    return '${_pesoKg.toStringAsFixed(2)} kg × Bs. ${precioPromedio.toStringAsFixed(2)}/kg = Bs. ${(precioPromedio * _pesoKg).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pizza,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pizza ${widget.presentacion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contador de sabores seleccionados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  Icon(
                    _saboresSeleccionados.isEmpty
                        ? Icons.info_outline
                        : Icons.check_circle,
                    color: _saboresSeleccionados.isEmpty
                        ? AppColors.warning
                        : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _saboresSeleccionados.isEmpty
                          ? 'Selecciona al menos 1 sabor'
                          : '${_saboresSeleccionados.length} de $_maxSabores sabores seleccionados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de sabores
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.saboresDisponibles.length,
                itemBuilder: (context, index) {
                  final sabor = widget.saboresDisponibles[index];
                  final isSelected = _estaSeleccionado(sabor);
                  final selectionIndex = _saboresSeleccionados.indexWhere(
                    (s) => s.id == sabor.id,
                  );

                  return _SaborCard(
                    sabor: sabor,
                    isSelected: isSelected,
                    selectionNumber: isSelected ? selectionIndex + 1 : null,
                    onTap: () => _toggleSabor(sabor),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Sabores seleccionados preview con precio promediado
            if (_saboresSeleccionados.isNotEmpty) ...[
              Text(
                'Sabores Seleccionados:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),

              if (widget.presentacion == 'PESO') ...[
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          hintText: 'Peso (kg)',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.monitor_weight,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _pesoKg = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _saboresSeleccionados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sabor = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${sabor.nombre} - Bs. ${sabor.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Mostrar cálculo del precio promedio
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio Promedio',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.presentacion == 'PESO'
                                ? _calcularPrecioTotal()
                                : _calcularPrecioPromedio(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saboresSeleccionados.isEmpty
                        ? null
                        : () {
                            widget.onConfirmar(_saboresSeleccionados,
                                peso: _pesoKg);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      disabledBackgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirmar Sabores',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

class _SaborCard extends StatelessWidget {
  final ProductoDto sabor;
  final bool isSelected;
  final int? selectionNumber;
  final VoidCallback onTap;

  const _SaborCard({
    required this.sabor,
    required this.isSelected,
    this.selectionNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.secondary : const Color(0xFF2A2A2A),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isSelected
                                ? AppColors.secondary
                                : AppColors.secondary.withOpacity(0.2))
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_pizza,
                        color:
                            isSelected ? AppColors.secondary : Colors.white70,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sabor.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${sabor.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected && selectionNumber != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$selectionNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}