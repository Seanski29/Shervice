import 'package:flutter/material.dart';
import '../shared/vehicle_fleet_view.dart';

class StaffVehicle extends StatefulWidget {
  const StaffVehicle({super.key});

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: VehicleFleetView(
        key: ValueKey('staff_fleet_list_$_refreshSeed'),
        userRole: 'staff',
        onRefreshNeeded: _triggerInstantRefresh,
        customHeader: const Text(
          'Fleet Status Monitor',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}