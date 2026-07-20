import 'package:flutter/material.dart';
import '../../widgets/shared_dashboard_view.dart';

class AdminDashboard extends StatelessWidget {
  final Function(int)? onSwitchTab;

  const AdminDashboard({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SharedDashboardView(
        showClientTrips: true,

        // ─── STANDARD HEADER (matches AdminSchedules, AdminDriver, etc.) ───
        headerWidget: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 24.0,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fleet Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time metrics and actionable insights for your fleet operations.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Optional action button can be added here in the future
              // For now, just a placeholder to keep symmetry
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}