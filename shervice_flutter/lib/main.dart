import 'package:flutter/material.dart';
import 'layouts/admin_layout.dart'; // We will create this next!

void main() {
  runApp(const SherviceApp());
}

class SherviceApp extends StatelessWidget {
  const SherviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shervice Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Deep blue for Admin authority, matching your Tailwind React design
        primaryColor: const Color(0xFF0F172A), 
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Soft off-white background
        useMaterial3: true,
      ),
      // This is the "traffic controller" we are about to build
      home: const AdminLayout(), 
    );
  }
}