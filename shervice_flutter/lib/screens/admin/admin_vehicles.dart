import 'package:flutter/material.dart';
import '../shared/vehicle_fleet_view.dart';

class AdminVehicles extends StatefulWidget {
  const AdminVehicles({super.key});

  @override
  State<AdminVehicles> createState() => _AdminVehiclesState();
}

class _AdminVehiclesState extends State<AdminVehicles> {
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
        key: ValueKey('admin_fleet_list_$_refreshSeed'),
        userRole: 'admin',
        onRefreshNeeded: _triggerInstantRefresh,
        customHeader: const Text(
          'Vehicle Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}