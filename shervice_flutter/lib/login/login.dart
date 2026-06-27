import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb flag
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

// Imports for your layouts and the forgot password screen
import '../layouts/admin_layout.dart';
import '../layouts/driver_layout.dart';
// TODO: Adjust these two import paths to match exactly what you named your responsive wrapper files
import '../layouts/oic_layout.dart';
import '../layouts/staff_layout.dart';
import 'forgot_password.dart';

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

  // Helper getter to determine local backend base address seamlessly
  String get _backendUrl {
    if (kIsWeb) return 'http://localhost:5000/api/auth/login';
    // Loops back to your machine's server if running a mobile emulator
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/auth/login'
        : 'http://127.0.0.1:5000/api/auth/login';
  }

  // Dynamic Login Logic Function linking straight to Python API
  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange.shade700);
      return;
    }

    // Display a loading indicator during backend network verification
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Capture the navigator state BEFORE the async network gap to satisfy compiler lints
    final navigator = Navigator.of(context);
    bool isLoadingDismissed = false;

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // Dismiss the loading indicator safely right after network return
      if (mounted) {
        navigator.pop();
        isLoadingDismissed = true;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // ─── UPDATED: Checking for 'success' == true instead of 'status' ───
      if (response.statusCode == 200 && responseData['success'] == true) {
        final userData = responseData['data'];
        final String role = userData['role'];

        // 1. Safely extract the core data for ALL roles right away
        final String realUserId = (userData['user_id'] ?? userData['id'] ?? '')
            .toString();
        final String userDisplayName =
            (userData['name'] ?? userData['full_name'] ?? 'User').toString();

        // Note: Admin and Staff might not have a "company" in the DB, so we provide a fallback
        final String userCompany =
            (userData['company_name'] ?? userData['company'] ?? 'GT Lantin')
                .toString();

        // Navigates based on the role payload returned by Supabase via Flask
        if (role == 'admin') {
          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => AdminLayout(
                  adminId: realUserId, // 👈 Pass the ID!
                  adminName: userDisplayName, // 👈 Pass the Name!
                  companyName: userCompany, // 👈 Pass the Company!
                ),
              ),
            );
          }
        } else if (role == 'oic') {
          if (mounted) {
            final String realUserId =
                (userData['user_id'] ?? userData['id'] ?? '').toString();
            final String oicDisplayName =
                (userData['name'] ?? userData['full_name'] ?? 'OIC').toString();
            final String oicCompany = (userData['company'] ?? 'Internal')
                .toString();

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => OicLayout(
                  oicId: realUserId, // 👈 Start the baton pass here
                  oicName: oicDisplayName,
                  companyName: oicCompany,
                ),
              ),
            );
          }
        } else if (role == 'staff') {
          if (mounted) {
            // ─── BULLETPROOF DATA EXTRACTION ───
            // Checks multiple possible database keys and safely converts to String
            final String realUserId =
                (userData['user_id'] ?? userData['id'] ?? '').toString();
            final String staffDisplayName =
                (userData['name'] ?? userData['full_name'] ?? 'Staff Member')
                    .toString();
            final String staffCompany = (userData['company'] ?? 'Internal')
                .toString();

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
          if (mounted) {
            // Safely extract all three pieces of data from the database
            final String realUserId =
                (userData['user_id'] ?? userData['id'] ?? '').toString();
            final String driverDisplayName =
                (userData['name'] ?? userData['full_name'] ?? 'Driver')
                    .toString();
            final String driverCompany = (userData['company'] ?? 'Internal')
                .toString();

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => DriverLayout(
                  driverId: realUserId, // ✅ Added missing parameter
                  driverName: driverDisplayName,
                  companyName: driverCompany, // ✅ Added missing parameter
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
        // Displays exact authentication or user mismatch errors from server
        final errorMsg = responseData['message'] ?? 'Authentication failed.';
        _showSnackBar(errorMsg, Colors.red.shade600);
      }
    } catch (e) {
      // ONLY pop if the loading indicator wasn't dismissed yet to prevent popping the main screen
      if (mounted && !isLoadingDismissed) {
        navigator.pop();
      }
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
                    // Top Logo
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

                    // Shervice Logo Text
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

                    // Email Field
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

                    // Password Field
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

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button Triggering Async Flask Network Validation
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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

                    const SizedBox(height: 20),
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
