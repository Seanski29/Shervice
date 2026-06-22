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
    
    // Extract the role parameter
    final String? role = uri.queryParameters['role'];

    // Route to the correct layout based on the role
    Widget initialScreen;
    
    if (role == 'admin') {
      initialScreen = const AdminLayout();
    } else if (role == 'driver') {
      initialScreen = const DriverLayout(); 
    } else {
      // Print to the debug console so you can see exactly what Flutter received
      debugPrint('RECEIVED URL: $rawUrl');
      debugPrint('EXTRACTED ROLE: $role');
      
      initialScreen = Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('Missing Role Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Raw URL received: $rawUrl', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => html.window.location.href = 'http://localhost:3000',
                child: const Text('Return to Login'),
              )
            ],
          ),
        ),
      );
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