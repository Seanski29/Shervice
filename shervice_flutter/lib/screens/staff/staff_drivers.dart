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
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SharedDriversView(
        // The unique value key tells Flutter to destroy the old layout cache and fetch fresh data
        key: ValueKey('staff_drivers_list_$_refreshSeed'),
        canManage: false, // Hides the row card delete trash icons
        onDriverTapped: (ctx, model) {
          if (model != null) _showDriverModal(ctx, model);
        },
        // ─── Consistent header: title + subtitle + refresh ───
        customHeader: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Fleet Drivers Registry',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View and manage driver profiles.',
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
                  tooltip: 'Refresh Drivers',
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