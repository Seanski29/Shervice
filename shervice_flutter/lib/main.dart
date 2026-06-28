import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'layouts/admin/admin_layout.dart';
import 'layouts/driver/driver_layout.dart';
import 'login/login.dart';

void main() {
  usePathUrlStrategy();
  runApp(const SherviceApp());
}

class SherviceApp extends StatelessWidget {
  const SherviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final String? role = uri.queryParameters['role'];

    Widget getInitialScreen() {
      if (role == 'admin') {
        return const AdminLayout();
      } else if (role == 'driver') {
        // FIXED: Provided all three required parameters for URL testing
        return const DriverLayout(
          driverId: '00000000-0000-0000-0000-000000000000', // Dummy UUID
          driverName: 'System Driver',
          companyName: 'Test Company',
        );
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
