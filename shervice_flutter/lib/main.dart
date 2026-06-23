import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 
import 'dart:html' as html; // 1. Import HTML to read the raw browser window

import 'layouts/admin_layout.dart'; 
import 'layouts/driver_layout.dart'; 

void main() {
  usePathUrlStrategy(); 
  runApp(const SherviceApp());
}

class SherviceApp extends StatelessWidget {
  const SherviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. BULLETPROOF URL CHECK: Read directly from the Chrome address bar, NOT Flutter's router
    final rawUrl = html.window.location.href;
    final uri = Uri.parse(rawUrl);

    // Extract the role parameter, and fall back to path inspection.
    final String? role = uri.queryParameters['role'];
    final String pathSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

    // Route to the correct layout based on URL information.
    Widget initialScreen;

    if (role == 'admin' || pathSegment == 'admin') {
      initialScreen = const AdminLayout();
    } else if (role == 'driver' || pathSegment == 'driver') {
      initialScreen = const DriverLayout();
    } else {
      debugPrint('RECEIVED URL: $rawUrl');
      debugPrint('EXTRACTED ROLE: $role');
      debugPrint('PATH SEGMENT: $pathSegment');

      // Fallback to admin portal for local development when no role is provided.
      initialScreen = const AdminLayout();
    }

    return MaterialApp(
      title: 'Shervice Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F172A), 
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: initialScreen, 
    );
  }
}