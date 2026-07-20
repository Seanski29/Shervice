import 'package:flutter/material.dart';
import '../../widgets/shared_dashboard_view.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedDashboardView(
      role: AdminDashboardRole(), // Injecting the polymorphic Admin Role
      headerWidget: const Text(
        'Fleet Overview',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}