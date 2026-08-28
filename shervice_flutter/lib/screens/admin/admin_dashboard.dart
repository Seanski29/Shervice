import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../../widgets/shared_dashboard_view.dart';
=======
import '../../widgets/shared/shared_dashboard_view.dart';
>>>>>>> 17e5752e11d7c5ce8c89c26b152e7ba8e5e35b40

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Dark Mode is active
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SharedDashboardView(
      showClientTrips: true, // Admins track company metrics
      headerWidget: Text(
        'Admin Dashboard',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          // Dynamic text color
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
