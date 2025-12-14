class ApiConstants {

  // static const String baseUrl = 'https://averapizza.servernux.com/backend';
  // static const String apiVersion = '/api';

  static const String baseUrl = 'http://localhost:8089';
  static const String apiVersion = '/api';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '$apiVersion/auth/login';
  static String register(String rol) => '$apiVersion/auth/register?rolNombre=$rol';

  //ENDPOINTS SIN SEGURIDAD
  static const String productosPublicos = '$apiVersion/auth/completo';
  static const String menu = '$apiVersion/cliente/productos/menu';


  // ========== USUARIOS ENDPOINTS ==========
  static const String usuarios = '$apiVersion/dashboard/clientes';
  static const String usuariosEstadisticas = '$apiVersion/clientes/estadisticas';
  static String usuarioById(int id) => '$apiVersion/admin/usuarios/$id';
  static String toggleEstadoUsuario(int id) => '$apiVersion/admin/usuarios/$id/toggle-estado';
  static String usuariosByRol(String rol) => '$apiVersion/admin/usuarios/rol/$rol';
  static const String usuariosActivos = '$apiVersion/admin/usuarios/activos';

  // ========== PRODUCTOS ENDPOINTS ==========
  static const String productos = '$apiVersion/cliente/productos';
  static String productoById(int id) => '$apiVersion/cliente/productos/$id';

  static String topSabores(String inicio, String fin) =>
      '$apiVersion/estadisticas/top-sabores?fechaInicio=$inicio&fechaFin=$fin';

  // ========== SABORES ENDPOINTS ==========
  static const String sabores = '$apiVersion/admin/sabores';
  static String saborById(int id) => '$apiVersion/admin/sabores/$id';
  static String saboresByProducto(int productoId) =>
      '$apiVersion/admin/sabores/producto/$productoId';
  static String saboresClienteByProducto(int productoId) =>
      '$apiVersion/cliente/sabores/producto/$productoId';


  // ========== PRESENTACIONES ENDPOINTS ==========
  static const String presentaciones = '$apiVersion/admin/presentaciones';
  static String presentacionById(int id) => '$apiVersion/admin/presentaciones/$id';
  static String presentacionesByProducto(int productoId) =>
      '$apiVersion/cliente/presentaciones/producto/$productoId';


  // ========== PRECIOS ENDPOINTS ==========
  static String preciosBySabor(int saborId) =>
      '$apiVersion/admin/precios/sabor/$saborId';
  static String createPrecio(int saborId) =>
      '$apiVersion/admin/precios/$saborId';
  static String updatePrecio(int precioId) =>
      '$apiVersion/admin/precios/$precioId';

  // ========== INSUMOS ENDPOINTS ==========
  static const String insumos = '$apiVersion/admin/insumos';
  static String insumoById(int id) => '$apiVersion/admin/insumos/$id';
  static const String insumosBajoStock = '$apiVersion/admin/insumos/bajo-stock';

  // ========== RECETAS ENDPOINTS ==========
  static const String recetas = '$apiVersion/admin/recetas';
  static String recetaByProducto(int saborId) =>
      '$apiVersion/admin/recetas/$saborId';

  // ========== INVENTARIO ENDPOINTS ==========
  static const String verificarStock = '$apiVersion/admin/inventario/verificar-stock';
  static const String ajustarStock = '$apiVersion/inventario/ajustar';
  static const String movimientos = '$apiVersion/inventario/movimientos';
  static String movimientosByInsumo(int insumoId) =>
      '$apiVersion/inventario/movimientos/insumo/$insumoId';

  // ========== PEDIDOS - CAJERO ENDPOINTS ==========
  static const String pedidosCajero = '$apiVersion/cajero/pedidos/hoy';
  static String pedidosByEstado(String estado) =>
      '$apiVersion/cajero/pedidos/estado/$estado';



  // ========== PEDIDOS - COCINA ENDPOINTS ==========
  static const String pedidosPendientes = '$apiVersion/cajero/pedidos/estado/PENDIENTE';
  static const String pedidosEnPreparacion = '$apiVersion/cajero/pedidos/estado/EN_PREPARACION';
  static String tomarPedido(int id) => '$apiVersion/cocina/pedidos/$id/tomar';
  static String marcarListo(int id) => '$apiVersion/cocina/pedidos/$id/marcar-listo';
  static String entregarPedido(int id) => '$apiVersion/cocina/pedidos/$id/entregar';
  static String cancelarPedido(int id) =>
      '$apiVersion/cajero/pedidos/$id/cancelar';

  // ========== REPORTES ENDPOINTS ==========
  static const String reporteDiario = '$apiVersion/admin/reportes/diario';
  static String ventasEntreFechas(String inicio, String fin) =>
      '$apiVersion/admin/reportes/ventas?inicio=$inicio&fin=$fin';
  static String ventasPorTipo(String inicio, String fin) =>
      '$apiVersion/admin/reportes/ventas-por-tipo?inicio=$inicio&fin=$fin';
  static const String ventasHoy = '$apiVersion/reportes/ventas/hoy';
  static const String productosTop = '$apiVersion/admin/reportes/productos/top';
  static const String inventarioBajoStock = '$apiVersion/reportes/inventario/bajo-stock';

  // ========== DASHBOARD ENDPOINTS ==========
  static const String dashboard = '$apiVersion/dashboard/metricas-generales';

  // ========== VENTAS ENDPOINTS ==========
  static const String ventas = '$apiVersion/ventas';
  static String ventaById(int id) => '$apiVersion/ventas/$id';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
}

enum UserRole {
  ADMIN,
  CAJERO,
  CLIENTE,
  COCINA
}


enum EstadoPedido {
  PENDIENTE,
  EN_PREPARACION,
  LISTO,
  ENTREGADO,
  CANCELADO
}

enum TipoServicio {
  MESA,
  LLEVAR,
  DELIVERY
}