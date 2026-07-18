import 'package:flutter/material.dart';
import '../../widgets/shared_drivers_view.dart';
import '../../widgets/driver_form_dialog.dart';
import '../../models/driver_profile_model.dart';
import '../../constant.dart';

class StaffDrivers extends StatefulWidget {
  const StaffDrivers({super.key});

  @override
  State<StaffDrivers> createState() => _StaffDriversState();
}

class _StaffDriversState extends State<StaffDrivers> {
  // Changing string seed forces an absolute UI state redraw on data operations
  String _refreshSeed = DateTime.now().millisecondsSinceEpoch.toString();


  void _showDriverModal(BuildContext context, DriverProfileModel driver) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DriverFormDialog(
        driver: driver,
        backendUrl: backendUrl,
        onDelete: null, // 🔒 Staff cannot delete records
        onSuccess: () {
          _triggerInstantRefresh(); // Instantly catches modifications on save
        },
      ),
    );
  }

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
      body: SharedDriversView(
        // The unique value key tells Flutter to destroy the old layout cache and fetch fresh data
        key: ValueKey('staff_drivers_list_$_refreshSeed'),
        canManage: false, // Hides the row card delete trash icons
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