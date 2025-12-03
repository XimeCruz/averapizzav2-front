import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SecureStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(StorageKeys.token, token);
  }

  static String? getToken() {
    return _prefs?.getString(StorageKeys.token);
  }

  static Future<void> deleteToken() async {
    await _prefs?.remove(StorageKeys.token);
  }

  // User Info
  static Future<void> saveUserInfo({
    required String role,
    required int userId,
    required String userName,
  }) async {
    await _prefs?.setString(StorageKeys.userRole, role);
    await _prefs?.setInt(StorageKeys.userId, userId);
    await _prefs?.setString(StorageKeys.userName, userName);
  }

  static String? getUserRole() {
    return _prefs?.getString(StorageKeys.userRole);
  }

  static int? getUserId() {
    return _prefs?.getInt(StorageKeys.userId);
  }

  static String? getUserName() {
    return _prefs?.getString(StorageKeys.userName);
  }

  // Clear all
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Check if authenticated
  static bool isAuthenticated() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}