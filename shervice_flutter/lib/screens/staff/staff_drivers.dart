import 'package:flutter/material.dart';
import '../../widgets/shared_drivers_view.dart';
import '../../widgets/driver_form_dialog.dart';
import '../../models/driver_profile_model.dart';

class StaffDrivers extends StatelessWidget {
  const StaffDrivers({super.key});

  String get _backendUrl => 'http://127.0.0.1:5000/api';

  void _showDriverModal(BuildContext context, DriverProfileModel driver) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DriverFormDialog(
        driver: driver,
        backendUrl: _backendUrl,
        onDelete: null, // 🔒 PASSING NULL HIDES THE DELETE LINK FOR STAFF
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SharedDriversView(
        canManage: false, // Disables the row card trash-can delete shortcut icons
        onDriverTapped: (ctx, model) {
          if (model != null) _showDriverModal(ctx, model);
        },
        customHeader: const Text(
          'Active Fleet Drivers Registry',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
      ),
    );
  }
}