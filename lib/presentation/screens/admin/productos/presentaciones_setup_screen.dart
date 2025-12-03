// lib/presentation/screens/admin/productos/presentaciones_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/producto_model.dart';
import '../../../providers/producto_provider.dart';

class PresentacionesSetupScreen extends StatefulWidget {
  const PresentacionesSetupScreen({super.key});

  @override
  State<PresentacionesSetupScreen> createState() => _PresentacionesSetupScreenState();
}

class _PresentacionesSetupScreenState extends State<PresentacionesSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().loadPresentaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presentaciones'),
      ),
      body: Consumer<ProductoProvider>(
        builder: (context, provider, _) {
          if (provider.presentaciones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.category,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aún no hay presentaciones configuradas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Las presentaciones son necesarias para configurar precios (Peso, Redonda, Bandeja)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _createDefaultPresentaciones(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Presentaciones por Defecto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Presentaciones Configuradas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...provider.presentaciones.map((p) => _PresentacionCard(p)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createDefaultPresentaciones(BuildContext context) async {
    final provider = context.read<ProductoProvider>();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Crear las 3 presentaciones por defecto
    final presentaciones = [
      CreatePresentacionRequest(
        tipo: TipoPresentacion.PESO,
        usaPeso: true,
        maxSabores: 1,
      ),
      CreatePresentacionRequest(
        tipo: TipoPresentacion.REDONDA,
        usaPeso: false,
        maxSabores: 2,
      ),
      CreatePresentacionRequest(
        tipo: TipoPresentacion.BANDEJA,
        usaPeso: false,
        maxSabores: 3,
      ),
    ];

    int created = 0;
    for (var request in presentaciones) {
      final success = await provider.createPresentacion(request);
      if (success) created++;
    }

    if (!mounted) return;

    // Cerrar loading
    Navigator.pop(context);

    // Recargar
    await provider.loadPresentaciones();

    // Mostrar resultado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$created presentaciones creadas correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _PresentacionCard extends StatelessWidget {
  final PresentacionProducto presentacion;

  const _PresentacionCard(this.presentacion);

  IconData _getIcon() {
    switch (presentacion.tipo) {
      case TipoPresentacion.PESO:
        return Icons.scale;
      case TipoPresentacion.REDONDA:
        return Icons.circle_outlined;
      case TipoPresentacion.BANDEJA:
        return Icons.rectangle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIcon(),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          presentacion.getNombre(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Máx. sabores: ${presentacion.maxSabores}'),
            if (presentacion.usaPeso)
              const Text(
                'Precio por kilogramo',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
              SizedBox(width: 4),
              Text(
                'Activa',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}