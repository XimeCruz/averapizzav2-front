// lib/presentation/screens/cliente/perfil_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../layouts/cliente_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _isEditingInfo = false;
  bool _isEditingPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadEstadisticas();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    // Cargar datos del usuario actual
    _nombreController.text = authProvider.userName ?? '';
    _emailController.text = authProvider.userEmail ?? '';
    // TODO: Cargar apellido, teléfono y dirección desde el provider
  }

  void _loadEstadisticas() {
    final authProvider = context.read<AuthProvider>();
    final clienteProvider = context.read<ClienteProvider>();

    // Obtener el ID del cliente del AuthProvider
    final idCliente = authProvider.userId;

    if (idCliente != null) {
      clienteProvider.loadEstadisticas(idCliente);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implementar actualización de datos del usuario
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() => _isEditingInfo = false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passwordNuevaController.text != _passwordConfirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_passwordNuevaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implementar cambio de contraseña
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña cambiada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() => _isEditingPassword = false);
      _passwordActualController.clear();
      _passwordNuevaController.clear();
      _passwordConfirmarController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar contraseña: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return ClienteLayout(
      title: 'Mi Perfil',
      currentRoute: '/cliente/perfil',
      showCartButton: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con foto de perfil
                _buildProfileHeader(authProvider),

                const SizedBox(height: 32),

                // Información Personal
                _buildPersonalInfoSection(isDesktop),

                const SizedBox(height: 24),

                // Seguridad (Cambiar contraseña)
                _buildSecuritySection(isDesktop),

                const SizedBox(height: 24),

                // Estadísticas del cliente
                _buildStatsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                (authProvider.userName ?? 'C')
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userName ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authProvider.userEmail ?? 'cliente@email.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cliente Regular',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!_isEditingInfo)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingInfo = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _nombreController,
                          label: 'Nombre',
                          enabled: _isEditingInfo,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su nombre';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _apellidoController,
                          label: 'Apellido',
                          enabled: _isEditingInfo,
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                    ],
                  )
                else ...[
                  CustomTextField(
                    controller: _nombreController,
                    label: 'Nombre',
                    enabled: _isEditingInfo,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _apellidoController,
                    label: 'Apellido',
                    enabled: _isEditingInfo,
                    prefixIcon: Icons.person_outline,
                  ),
                ],

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  enabled: _isEditingInfo,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  enabled: _isEditingInfo,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _direccionController,
                  label: 'Dirección de Entrega',
                  enabled: _isEditingInfo,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),

                if (_isEditingInfo) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _isEditingInfo = false);
                          _loadUserData();
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: 'Guardar Cambios',
                        onPressed: _guardarCambios,
                        isLoading: _isLoading,
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seguridad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!_isEditingPassword)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingPassword = true),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Cambiar Contraseña'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                ),
            ],
          ),

          if (_isEditingPassword) ...[
            const SizedBox(height: 24),

            CustomTextField(
              controller: _passwordActualController,
              label: 'Contraseña Actual',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordNuevaController,
              label: 'Nueva Contraseña',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              helperText: 'Mínimo 6 caracteres',
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordConfirmarController,
              label: 'Confirmar Nueva Contraseña',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _isEditingPassword = false);
                    _passwordActualController.clear();
                    _passwordNuevaController.clear();
                    _passwordConfirmarController.clear();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Cambiar Contraseña',
                  onPressed: _cambiarPassword,
                  isLoading: _isLoading,
                  width: 200,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Última actualización: hace 30 días',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer<ClienteProvider>(
      builder: (context, clienteProvider, child) {
        final estadisticas = clienteProvider.estadisticas;
        final isLoading = clienteProvider.isLoading;
        final error = clienteProvider.error;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis Estadísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (error != null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar estadísticas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadEstadisticas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (estadisticas != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      final formatter = NumberFormat.currency(
                        locale: 'es_BO',
                        symbol: 'Bs. ',
                        decimalDigits: 2,
                      );

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _StatCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Pedidos Realizados',
                            value: estadisticas.totalPedidos.toString(),
                            color: AppColors.primary,
                            width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                          ),
                          _StatCard(
                            icon: Icons.attach_money,
                            label: 'Total Gastado',
                            value: formatter.format(estadisticas.totalGastado),
                            color: AppColors.accent,
                            width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                          ),
                          _StatCard(
                            icon: Icons.local_pizza_outlined,
                            label: 'Pizza Favorita',
                            value: estadisticas.pizzaFavorita,
                            color: AppColors.warning,
                            width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                          ),
                        ],
                      );
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No hay estadísticas disponibles',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? width;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}