import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../../widgets/shared_dashboard_view.dart';
=======
import '../../widgets/shared/shared_dashboard_view.dart';
>>>>>>> 17e5752e11d7c5ce8c89c26b152e7ba8e5e35b40

class StaffDashboard extends StatelessWidget {
  final String staffName;
  final String companyName;

  const StaffDashboard({
    super.key,
    required this.staffName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return SharedDashboardView(
      showClientTrips: true, // 👈 Now shows client weekly dispatches
      headerWidget: Row(
        children: [
          Text(
            'Staff Dashboard',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
