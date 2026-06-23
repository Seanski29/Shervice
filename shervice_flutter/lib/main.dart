import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 
import 'dart:html' as html;
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
    // 1. Get the current URL
    final rawUrl = html.window.location.href;
    final uri = Uri.parse(rawUrl);
    final String? role = uri.queryParameters['role'];

    // 2. Logic: If role exists, go to layout. Otherwise, go to LoginScreen.
    Widget getInitialScreen() {
      if (role == 'admin') {
        return const AdminLayout();
      } else if (role == 'driver') {
        return const DriverLayout();
      } else {
        // This is where we point to your login screen
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
      // Set the home to the result of our logic function
      home: getInitialScreen(), 
    );
  }
}