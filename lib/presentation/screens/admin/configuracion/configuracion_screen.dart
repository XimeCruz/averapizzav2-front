// lib/presentation/screens/admin/configuracion/configuracion_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../layouts/admin_layout.dart';
import '../../auth/login_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesPedidos = true;
  bool _notificacionesStock = true;
  bool _modoOscuro = true;
  bool _sonidoAlerta = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AdminLayout(
      title: 'Configuración',
      currentRoute: '/admin/configuracion',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil del usuario
          _SectionCard(
            title: 'Mi Cuenta',
            icon: Icons.account_circle,
            children: [
              _ProfileTile(
                name: authProvider.userName ?? 'Usuario',
                email: 'admin@averapizza.com', // Puedes obtenerlo del provider
                role: 'Administrador',
                avatar: authProvider.userName?.substring(0, 1).toUpperCase() ?? 'A',
              ),
              const SizedBox(height: 16),
              _SettingButton(
                icon: Icons.edit,
                label: 'Editar Perfil',
                onTap: () {
                  _showComingSoonDialog(context, 'Editar Perfil');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.lock_outline,
                label: 'Cambiar Contraseña',
                onTap: () {
                  _showComingSoonDialog(context, 'Cambiar Contraseña');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notificaciones
          _SectionCard(
            title: 'Notificaciones',
            icon: Icons.notifications_outlined,
            children: [
              _SwitchTile(
                icon: Icons.receipt_long,
                title: 'Pedidos Nuevos',
                subtitle: 'Recibir alertas de nuevos pedidos',
                value: _notificacionesPedidos,
                onChanged: (value) {
                  setState(() {
                    _notificacionesPedidos = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _SwitchTile(
                icon: Icons.inventory_2,
                title: 'Stock Bajo',
                subtitle: 'Alertas cuando hay productos con poco stock',
                value: _notificacionesStock,
                onChanged: (value) {
                  setState(() {
                    _notificacionesStock = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _SwitchTile(
                icon: Icons.volume_up,
                title: 'Sonido de Alertas',
                subtitle: 'Reproducir sonido en notificaciones',
                value: _sonidoAlerta,
                onChanged: (value) {
                  setState(() {
                    _sonidoAlerta = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apariencia
          _SectionCard(
            title: 'Apariencia',
            icon: Icons.palette_outlined,
            children: [
              _SwitchTile(
                icon: Icons.dark_mode,
                title: 'Modo Oscuro',
                subtitle: 'Tema oscuro para la aplicación',
                value: _modoOscuro,
                onChanged: (value) {
                  setState(() {
                    _modoOscuro = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _SettingButton(
                icon: Icons.color_lens,
                label: 'Personalizar Colores',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Personalizar Colores');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sistema
          _SectionCard(
            title: 'Sistema',
            icon: Icons.settings_outlined,
            children: [
              _SettingButton(
                icon: Icons.restaurant,
                label: 'Datos del Restaurante',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Datos del Restaurante');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.print,
                label: 'Configuración de Impresión',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Configuración de Impresión');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.backup,
                label: 'Respaldo y Restauración',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Respaldo y Restauración');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.language,
                label: 'Idioma',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Español',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  ],
                ),
                onTap: () {
                  _showComingSoonDialog(context, 'Cambiar Idioma');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información
          _SectionCard(
            title: 'Información',
            icon: Icons.info_outline,
            children: [
              _InfoRow(
                label: 'Versión',
                value: '1.0.0',
              ),
              const SizedBox(height: 12),
              _SettingButton(
                icon: Icons.help_outline,
                label: 'Ayuda y Soporte',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Ayuda y Soporte');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.description,
                label: 'Términos y Condiciones',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Términos y Condiciones');
                },
              ),
              const SizedBox(height: 8),
              _SettingButton(
                icon: Icons.privacy_tip,
                label: 'Política de Privacidad',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  _showComingSoonDialog(context, 'Política de Privacidad');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cerrar Sesión
          _SectionCard(
            title: 'Sesión',
            icon: Icons.logout,
            children: [
              _DangerButton(
                icon: Icons.logout,
                label: 'Cerrar Sesión',
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  '© 2025 A Vera Pizza',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hecho con ❤️ para tu negocio',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();

              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.construction, color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Próximamente', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'La función "$feature" estará disponible en una próxima actualización.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String avatar;

  const _ProfileTile({
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingButton({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
            activeTrackColor: AppColors.secondary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}