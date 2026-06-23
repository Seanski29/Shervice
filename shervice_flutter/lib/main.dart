import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 

import 'layouts/admin_layout.dart'; 
import 'layouts/driver_layout.dart'; 
import 'login/login.dart';

void main() {
  usePathUrlStrategy(); 
  runApp(const SherviceApp());
}

class SherviceApp extends StatelessWidget {
  const SherviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    // SAFE URL CHECK: Uri.base safely gets the current URL parameters 
    // on both Web and Mobile without needing dart:html
    final uri = Uri.base;
    final String? role = uri.queryParameters['role'];

    // Logic: If role exists in the URL, go to layout. Otherwise, default to Login.
    Widget getInitialScreen() {
      if (role == 'admin') {
        return const AdminLayout();
      } else if (role == 'driver') {
        return const DriverLayout();
      } else {
        return const LoginScreen(); 
      }
    }

    return MaterialApp(
      title: 'Shervice Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F172A), 
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: getInitialScreen(), 
    );
  }
}