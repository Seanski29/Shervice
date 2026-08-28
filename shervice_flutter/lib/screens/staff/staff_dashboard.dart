import 'package:flutter/material.dart';
import '../../widgets/shared/shared_dashboard_view.dart';

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
