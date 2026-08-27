import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Save user data when they log in
  static Future<void> saveUserSession(
    String role,
    String userId,
    String name,
    String company,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setString('userId', userId);
    await prefs.setString('userName', name);
    await prefs.setString('companyName', company);
    await prefs.setBool('isLoggedIn', true);
  }

  // Check if someone is currently logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Fetch the saved user data
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'role': prefs.getString('role'),
      'userId': prefs.getString('userId'),
      'userName': prefs.getString('userName'),
      'companyName': prefs.getString('companyName'),
    };
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('companyName');
    await prefs.remove('isLoggedIn');
  }
}
