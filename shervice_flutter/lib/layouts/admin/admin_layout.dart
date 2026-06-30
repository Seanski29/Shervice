import 'package:flutter/material.dart';
import 'admin_layout_desktop.dart';
import 'admin_layout_mobile.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us the constraints (size) of the screen
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: If the screen is wider than 800 pixels...
        if (constraints.maxWidth > 800) {
          return const AdminDesktopLayout(); // Show the Web/Desktop view
        } else {
          return const AdminMobileLayout(); // Show the Phone view
        }
      },
    );
  }
}
