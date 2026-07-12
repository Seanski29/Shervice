import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import '../constant.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// 1. ADD IMPORT FOR SESSION MANAGER
import '../session_manager.dart';

// Imports for your layouts
import '../layouts/admin/admin_layout.dart';
import '../layouts/driver/driver_layout.dart';
import '../layouts/oic/oic_layout.dart';
import '../layouts/staff/staff_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  double _bgAlignX = 0.0;
  double _bgAlignY = 0.0;

  bool _isFacebookLoading = false;

  // --- FACEBOOK LOGIN FUNCTION ---
  Future<void> _loginWithFacebook() async {
    setState(() => _isFacebookLoading = true);
    final navigator = Navigator.of(context);

    try {
      if (kIsWeb) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: '2455846521593896',
          cookie: true,
          xfbml: true,
          version: 'v17.0',
        );
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email",
        );

        final response = await http.post(
          Uri.parse('$backendUrl/auth/facebook'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': userData['email'],
            'full_name': userData['name'],
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if ((response.statusCode == 200 || response.statusCode == 201) &&
            responseData['success'] == true) {
          final userDataResponse = responseData['data'];
          final String role = userDataResponse['role'];

          if (role == 'admin') {
            final String realAdminId =
                (userDataResponse['user_id'] ?? userDataResponse['id'] ?? '')
                    .toString();
            // 👇 SAVE ADMIN SESSION
            await SessionManager.saveUserSession(
              'admin',
              realAdminId,
              'Admin',
              'GT LANTIN',
            );
            if (mounted) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AdminLayout(adminId: realAdminId),
                ),
              );
            }
          } else if (role == 'oic') {
            final String realUserId =
                (userDataResponse['user_id'] ?? userDataResponse['id'] ?? '')
                    .toString();
            final String oicDisplayName =
                (userDataResponse['name'] ??
                        userDataResponse['full_name'] ??
                        'OIC')
                    .toString();
            final String oicCompany =
                (userDataResponse['company'] ?? 'Internal').toString();

            // 👇 SAVE OIC SESSION
            await SessionManager.saveUserSession(
              'oic',
              realUserId,
              oicDisplayName,
              oicCompany,
            );
            if (mounted) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OicLayout(
                    oicId: realUserId,
                    oicName: oicDisplayName,
                    companyName: oicCompany,
                  ),
                ),
              );
            }
          } else if (role == 'staff') {
            final String realUserId =
                (userDataResponse['user_id'] ?? userDataResponse['id'] ?? '')
                    .toString();
            final String staffDisplayName =
                (userDataResponse['name'] ??
                        userDataResponse['full_name'] ??
                        'Staff Member')
                    .toString();
            final String staffCompany =
                (userDataResponse['company'] ?? 'Internal').toString();

            // 👇 SAVE STAFF SESSION
            await SessionManager.saveUserSession(
              'staff',
              realUserId,
              staffDisplayName,
              staffCompany,
            );
            if (mounted) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => StaffLayout(
                    staffId: realUserId,
                    staffName: staffDisplayName,
                    companyName: staffCompany,
                  ),
                ),
              );
            }
          } else if (role == 'driver') {
            final String realUserId =
                (userDataResponse['user_id'] ?? userDataResponse['id'] ?? '')
                    .toString();
            final String driverDisplayName =
                (userDataResponse['name'] ??
                        userDataResponse['full_name'] ??
                        'Driver')
                    .toString();
            final String driverCompany =
                (userDataResponse['company'] ?? 'Internal').toString();

            // 👇 SAVE DRIVER SESSION
            await SessionManager.saveUserSession(
              'driver',
              realUserId,
              driverDisplayName,
              driverCompany,
            );
            if (mounted) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DriverLayout(
                    driverId: realUserId,
                    driverName: driverDisplayName,
                    companyName: driverCompany,
                  ),
                ),
              );
            }
          } else {
            _showSnackBar(
              'Unrecognized user role assigned.',
              Colors.red.shade600,
            );
          }
        } else {
          _showSnackBar(
            responseData['message'] ?? 'Facebook auth rejected by server.',
            Colors.red.shade600,
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        _showSnackBar("Facebook login cancelled.", Colors.orange.shade600);
      } else {
        _showSnackBar(
          "Facebook Login Failed: ${result.message}",
          Colors.red.shade600,
        );
      }
    } catch (e) {
      _showSnackBar("Facebook authentication error: $e", Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  // --- DYNAMIC LOGIN LOGIC FUNCTION ---
  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange.shade700);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final navigator = Navigator.of(context);
    bool isLoadingDismissed = false;

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (mounted) {
        navigator.pop();
        isLoadingDismissed = true;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final userData = responseData['data'];
        final String role = userData['role'];

        if (role == 'admin') {
          final String realAdminId =
              (userData['user_id'] ?? userData['id'] ?? '').toString();

          // 👇 SAVE ADMIN SESSION
          await SessionManager.saveUserSession(
            'admin',
            realAdminId,
            'Admin',
            'GT LANTIN',
          );

          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => AdminLayout(adminId: realAdminId),
              ),
            );
          }
        } else if (role == 'oic') {
          final String realUserId =
              (userData['user_id'] ?? userData['id'] ?? '').toString();
          final String oicDisplayName =
              (userData['name'] ?? userData['full_name'] ?? 'OIC').toString();
          final String oicCompany = (userData['company'] ?? 'Internal')
              .toString();

          // 👇 SAVE OIC SESSION
          await SessionManager.saveUserSession(
            'oic',
            realUserId,
            oicDisplayName,
            oicCompany,
          );

          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => OicLayout(
                  oicId: realUserId,
                  oicName: oicDisplayName,
                  companyName: oicCompany,
                ),
              ),
            );
          }
        } else if (role == 'staff') {
          final String realUserId =
              (userData['user_id'] ?? userData['id'] ?? '').toString();
          final String staffDisplayName =
              (userData['name'] ?? userData['full_name'] ?? 'Staff Member')
                  .toString();
          final String staffCompany = (userData['company'] ?? 'Internal')
              .toString();

          // 👇 SAVE STAFF SESSION
          await SessionManager.saveUserSession(
            'staff',
            realUserId,
            staffDisplayName,
            staffCompany,
          );

          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => StaffLayout(
                  staffId: realUserId,
                  staffName: staffDisplayName,
                  companyName: staffCompany,
                ),
              ),
            );
          }
        } else if (role == 'driver') {
          final String realUserId =
              (userData['user_id'] ?? userData['id'] ?? '').toString();
          final String driverDisplayName =
              (userData['name'] ?? userData['full_name'] ?? 'Driver')
                  .toString();
          final String driverCompany = (userData['company'] ?? 'Internal')
              .toString();

          // 👇 SAVE DRIVER SESSION
          await SessionManager.saveUserSession(
            'driver',
            realUserId,
            driverDisplayName,
            driverCompany,
          );

          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => DriverLayout(
                  driverId: realUserId,
                  driverName: driverDisplayName,
                  companyName: driverCompany,
                ),
              ),
            );
          }
        } else {
          _showSnackBar(
            'Unrecognized user role assigned.',
            Colors.red.shade600,
          );
        }
      } else {
        final errorMsg = responseData['message'] ?? 'Authentication failed.';
        _showSnackBar(errorMsg, Colors.red.shade600);
      }
    } catch (e) {
      if (mounted && !isLoadingDismissed) navigator.pop();
      _showSnackBar(
        'Unable to connect to the backend server.',
        Colors.red.shade600,
      );
      debugPrint("❌ Login execution fault logged: $e");
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: MouseRegion(
        onHover: (PointerHoverEvent event) {
          setState(() {
            _bgAlignX = (event.position.dx / size.width) * 2 - 1;
            _bgAlignY = (event.position.dy / size.height) * 2 - 1;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(_bgAlignX, _bgAlignY),
              radius: 1.5,
              colors: const [
                Colors.white,
                Color(0xFFECFDF5),
                Color(0xFF284AA7),
              ],
              stops: const [0.0, 0.06, 1.0],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.blue.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          './assets/logo.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      './assets/shervice.jpg',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sign in to continue",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _isFacebookLoading
                            ? null
                            : _loginWithFacebook,
                        icon: _isFacebookLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.facebook, color: Colors.white),
                        label: Text(
                          _isFacebookLoading
                              ? "Connecting..."
                              : "Continue with Facebook",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "GT LANTIN SHUTTLE SERVICES",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
