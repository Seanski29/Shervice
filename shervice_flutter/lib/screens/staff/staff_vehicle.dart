import 'package:flutter/material.dart';
import '../shared/vehicle_fleet_view.dart';
import '../../constant.dart';

class StaffVehicle extends StatefulWidget {
  final String staffId;

  const StaffVehicle({super.key, required this.staffId});

  @override
  State<StaffVehicle> createState() => _StaffVehicleState();
}

class _StaffVehicleState extends State<StaffVehicle> {
  String _refreshSeed = DateTime.now().millisecondsSinceEpoch.toString();

  void _triggerInstantRefresh() {
    if (mounted) {
      setState(() {
        _refreshSeed = DateTime.now().millisecondsSinceEpoch.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        child: VehicleFleetView(
          key: ValueKey('staff_fleet_list_$_refreshSeed'),
          userRole: 'staff',
          userId: widget.staffId,
          onRefreshNeeded: _triggerInstantRefresh,
          // ─── Consistent header: title + subtitle + refresh (like AdminSchedules) ───
          customHeader: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fleet Status Monitor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View real‑time status and health of all vehicles in the fleet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button – compact and matches admin style
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: _triggerInstantRefresh,
                  icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                  tooltip: 'Refresh Fleet',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}