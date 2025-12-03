

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/receta_model.dart';
import '../../../providers/receta_provider.dart';
import '../../../providers/insumo_provider.dart';

class RecetaFormDialog extends StatefulWidget {
  final int saborId;
  final List<dynamic> detallesActuales;

  const RecetaFormDialog({
    super.key,
    required this.saborId,
    this.detallesActuales = const [],
  });

  @override
  State<RecetaFormDialog> createState() => _RecetaFormDialogState();
}

class _RecetaFormDialogState extends State<RecetaFormDialog> {
  final List<_InsumoItem> _insumos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar insumos actuales si existen
    if (widget.detallesActuales.isNotEmpty) {
      for (var detalle in widget.detallesActuales) {
        _insumos.add(_InsumoItem(
          insumoId: detalle.insumoId,
          cantidad: detalle.cantidad,
        ));
      }
    } else {
      _addInsumo();
    }
  }

  void _addInsumo() {
    setState(() {
      _insumos.add(_InsumoItem());
    });
  }

  void _removeInsumo(int index) {
    setState(() {
      _insumos.removeAt(index);
    });
  }

  Future<void> _saveReceta() async {
    // Validar que todos los insumos tengan datos
    for (var item in _insumos) {
      if (item.insumoId == null || item.cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los insumos'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final provider = context.read<RecetaProvider>();

    final request = widget.detallesActuales.isEmpty
        ? CreateRecetaRequest(
      insumos: _insumos.map((item) => RecetaInsumoItem(
        insumoId: item.insumoId!,
        cantidad: item.cantidad,
      )).toList(),
    )
        : UpdateRecetaRequest(
      insumos: _insumos.map((item) => RecetaInsumoItem(
        insumoId: item.insumoId!,
        cantidad: item.cantidad,
      )).toList(),
    );

    bool success;
    if (widget.detallesActuales.isEmpty) {
      success = await provider.createReceta(widget.saborId, request as CreateRecetaRequest);
    } else {
      success = await provider.updateReceta(widget.saborId, request as UpdateRecetaRequest);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta guardada correctamente'),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurar Receta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega los insumos necesarios',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: _insumos.length,
                itemBuilder: (context, index) {
                  return _InsumoRow(
                    item: _insumos[index],
                    onRemove: _insumos.length > 1
                        ? () => _removeInsumo(index)
                        : null,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _addInsumo,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Insumo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveReceta,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Guardar'),
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

class _InsumoItem {
  int? insumoId;
  double cantidad;

  _InsumoItem({this.insumoId, this.cantidad = 0});
}

class _InsumoRow extends StatefulWidget {
  final _InsumoItem item;
  final VoidCallback? onRemove;

  const _InsumoRow({
    required this.item,
    this.onRemove,
  });

  @override
  State<_InsumoRow> createState() => _InsumoRowState();
}

class _InsumoRowState extends State<_InsumoRow> {
  final _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item.cantidad > 0) {
      _cantidadController.text = widget.item.cantidad.toString();
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Consumer<InsumoProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<int>(
                    value: widget.item.insumoId,
                    decoration: const InputDecoration(
                      labelText: 'Insumo',
                      isDense: true,
                    ),
                    items: provider.insumos.map((insumo) {
                      return DropdownMenuItem(
                        value: insumo.id,
                        child: Text(
                          insumo.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        widget.item.insumoId = value;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  widget.item.cantidad = double.tryParse(value) ?? 0;
                },
              ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: widget.onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}