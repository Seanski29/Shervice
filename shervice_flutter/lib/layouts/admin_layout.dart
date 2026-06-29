import 'package:flutter/material.dart';
import 'admin_layout_desktop.dart';
import 'admin_layout_mobile.dart';

class AdminLayout extends StatelessWidget {
  // 👇 1. Add the required variables to the main wrapper
  final String adminId;
  final String adminName;
  final String companyName;

  const AdminLayout({
    super.key,
    required this.adminId, // 👈 2. Require them here
    required this.adminName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us the constraints (size) of the screen
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: If the screen is wider than 800 pixels...
        if (constraints.maxWidth > 800) {
          // 👇 3. Pass the baton down to the Desktop layout (Notice 'const' is gone)
          return AdminDesktopLayout(
            adminId: adminId,
            adminName: adminName,
            companyName: companyName,
          );
        } else {
          // 👇 4. Pass the baton down to the Mobile layout
          return AdminMobileLayout(
            adminId: adminId,
            adminName: adminName,
            companyName: companyName,
          );
        }
      },
    );
  }
}