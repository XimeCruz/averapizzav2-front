import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../cajero/cajero_dashboard_screen.dart';
import '../cliente/cliente_home_screen.dart';
import '../cocina/cocina_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateToHome(authProvider.userRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.lightGreenAccent[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _navigateToHome(String? role) {
    Widget screen;

    switch (role?.toUpperCase()) {
      case 'ADMIN':
        screen = const AdminDashboardScreen();
        break;
      case 'CAJERO':
        screen = const CajeroDashboardScreen();
        break;
      case 'COCINA':
        screen = const CocinaScreen();
        break;
      case 'CLIENTE':
        screen = const ClienteHomeScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rol no válido'),
            backgroundColor: Colors.lightGreenAccent[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String selectedRole = 'CLIENTE';
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete sus datos para registrarse',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDarkTextField(
                    controller: nombreController,
                    label: 'Nombre completo',
                    hint: 'Ingresa tu nombre',
                  ),
                  const SizedBox(height: 16),
                  _buildDarkTextField(
                    controller: emailController,
                    label: 'Dirección de correo electrónico',
                    hint: 'email@gmail.com',
                  ),
                  const SizedBox(height: 16),
                  _buildDarkTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    hint: 'Ingrese la contraseña',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDarkTextField(
                    controller: confirmPasswordController,
                    label: 'Confirmar contraseña',
                    hint: 'Confirmar contraseña',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rol',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFFFFF)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'CLIENTE',
                              child: Text('Cliente',),
                            ),
                            DropdownMenuItem(
                              value: 'CAJERO',
                              child: Text('Cajero'),
                            ),
                            DropdownMenuItem(
                              value: 'COCINA',
                              child: Text('Cocina'),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('Administrador'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedRole = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF2A2A2A),
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(color: const Color(0xFF3A3A3A)),
                  //   ),
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: DropdownButtonFormField<String>(
                  //     value: selectedRole,
                  //     dropdownColor: const Color(0xFF2A2A2A),
                  //     decoration: const InputDecoration(
                  //       labelText: 'Rol',
                  //       labelStyle: TextStyle(color: Color(0xFF888888)),
                  //       border: InputBorder.none,
                  //     ),
                  //     style: const TextStyle(color: Colors.white),
                  //     items: const [
                  //       DropdownMenuItem(value: 'CLIENTE', child: Text('Cliente')),
                  //       DropdownMenuItem(value: 'CAJERO', child: Text('Cajero')),
                  //       DropdownMenuItem(value: 'COCINA', child: Text('Cocina')),
                  //       DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  //     ],
                  //     onChanged: (value) {
                  //       if (value != null) {
                  //         setState(() {
                  //           selectedRole = value;
                  //         });
                  //       }
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        void showError(String message) {
                          setState(() {
                            errorMessage = message;
                          });
                        }

                        setState(() {
                          errorMessage = null;
                        });

                        if (nombreController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            passwordController.text.isEmpty ||
                            confirmPasswordController.text.isEmpty) {
                          showError('Por favor complete todos los campos');
                          return;
                        }

                        if (!emailController.text.contains('@')) {
                          showError('Por favor, introduzca un correo electrónico válido');
                          return;
                        }

                        if (passwordController.text != confirmPasswordController.text) {
                          showError('Las contraseñas no coinciden');
                          return;
                        }

                        if (passwordController.text.length < 6) {
                          showError('La contraseña debe tener al menos 6 caracteres');
                          return;
                        }

                        final authProvider = context.read<AuthProvider>();
                        final success = await authProvider.register(
                          nombreController.text.trim(),
                          emailController.text.trim(),
                          passwordController.text,
                          selectedRole,
                        );

                        if (!dialogContext.mounted) return;

                        if (success) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('¡Cuenta creada exitosamente!'),
                              backgroundColor: const Color(0xFF4ADE80),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          _navigateToHome(authProvider.userRole);
                        } else {
                          showError(authProvider.errorMessage ?? 'Error de registro');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF555555)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Pizza image with branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF0A0A0A),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pizza image
                  Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.2),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A1A),
                            ),
                            child: const Icon(
                              Icons.local_pizza,
                              size: 120,
                              color: Color(0xFF4ADE80),
                            ),
                          );
                        },
                      ),
                    ),
                  ).animate().scale(duration: 800.ms).fadeIn(),

                  const SizedBox(height: 48),

                  // Logo
                  // Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  //     const Text(
                  //       'A VERA PIZZA',
                  //       style: TextStyle(
                  //         color: Color(0xFF4ADE80),
                  //         fontSize: 32,
                  //         fontWeight: FontWeight.bold,
                  //         fontStyle: FontStyle.italic,
                  //         letterSpacing: 2,
                  //       ),
                  //     ),
                  //   ],
                  // ).animate().fadeIn(delay: 300.ms),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A Vera Pizza',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4ADE80),
                          letterSpacing: -2,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideX(begin: -0.3, end: 0),

                  const SizedBox(height: 24),

                  const Text(
                    'Satisface tus antojos de pizza.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: 400,
                    child: Text(
                      'Experimente el máximo placer de la pizza con nuestra deliciosa selección y ofertas irresistibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),

        // Right side - Login form
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF0A0A0A),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildLoginForm(),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top section with pizza image
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF0A0A0A),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A1A),
                            ),
                            child: const Icon(
                              Icons.local_pizza,
                              size: 80,
                              color: Color(0xFF4ADE80),
                            ),
                          );
                        },
                      ),
                    ),
                  ).animate().scale(duration: 800.ms),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A Vera Pizza',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4ADE80),
                              letterSpacing: -2,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      const Text(
                        'Satisface tus antojos de pizza.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Experimente el máximo placer de la pizza con nuestra selección.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Login form section
          Container(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _buildLoginForm(),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ingrese su dirección de correo electrónico y contraseña para iniciar sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dirección de correo electrónico',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'ejemplo@gmail.com',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: _usernameController.text.isNotEmpty
                        ? const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 20)
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduzca su nombre de usuario';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Password field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contraseña',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Mostrar contraseña',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.remove_red_eye_outlined,
                        color: const Color(0xFF888888),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduzca su contraseña';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Remember me and Forgot password
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Row(
          //       children: [
          //         SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: Checkbox(
          //             value: _rememberMe,
          //             onChanged: (value) {
          //               setState(() {
          //                 _rememberMe = value ?? false;
          //               });
          //             },
          //             activeColor: const Color(0xFF4ADE80),
          //             checkColor: Colors.black,
          //             side: const BorderSide(color: Color(0xFF3A3A3A)),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(4),
          //             ),
          //           ),
          //         ),
          //         const SizedBox(width: 8),
          //         Text(
          //           'Recordarme',
          //           style: TextStyle(
          //             color: Colors.grey[400],
          //             fontSize: 13,
          //           ),
          //         ),
          //       ],
          //     ),
          //     TextButton(
          //       onPressed: () {},
          //       child: const Text(
          //         '¿Has olvidado tu contraseña?',
          //         style: TextStyle(
          //           color: Color(0xFF4ADE80),
          //           fontSize: 13,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),

          const SizedBox(height: 8),

          //const SizedBox(height: 24),

          // Sign In button
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.status == AuthStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4ADE80),
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () => _showRegisterDialog(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[800], thickness: 1))
            ],
          ),

          const SizedBox(height: 8),

          Center(
            child: Column(
              children: [
                Text(
                  '¿Quieres ordenar algo?',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Navigate to catalog without login
                  },
                  child: const Text(
                    'Ver pizzas disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
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