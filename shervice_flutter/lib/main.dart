import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Allows clean URLs without the '#'

import 'layouts/admin_layout.dart'; 
import 'layouts/driver_layout.dart'; 

void main() {
  // Removes the '#' from Flutter Web URLs so it reads React parameters correctly
  usePathUrlStrategy(); 
  
  runApp(const SherviceApp());
}

class SherviceApp extends StatelessWidget {
  const SherviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the current URL the browser is on
    final uri = Uri.base;
    
    // Extract the role parameter sent from the React login
    final String? role = uri.queryParameters['role'];

    // Route to the correct layout based on the role
    Widget initialScreen;
    
    if (role == 'admin') {
      initialScreen = const AdminLayout();
    } else if (role == 'driver') {
      initialScreen = const DriverLayout(); 
    } else {
      // Fallback screen if someone accesses the Flutter port directly without logging in
      initialScreen = Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blue.shade800
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in through the main React portal.',
                style: TextStyle(color: Colors.blue.shade500),
              ),
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