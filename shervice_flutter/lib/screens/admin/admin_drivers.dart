import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/shared_drivers_view.dart';
import '../../widgets/driver_form_dialog.dart';
import '../../models/driver_profile_model.dart';
import '../../constant.dart';

class AdminDriver extends StatefulWidget {
  const AdminDriver({super.key});

  @override
  State<AdminDriver> createState() => _AdminDriverState();
}

class _AdminDriverState extends State<AdminDriver> {
  // Changing string seed forces an absolute UI state redraw on data operations
  String _refreshSeed = DateTime.now().millisecondsSinceEpoch.toString();

  void _showDriverModal(BuildContext context, DriverProfileModel? driver) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DriverFormDialog(
        driver: driver,
        backendUrl: backendUrl,
        onDelete: () => _confirmPurgeDriver(context, driver!),
        onSuccess: () {
          _triggerInstantRefresh();
        },
      ),
    );
  }

  void _confirmPurgeDriver(BuildContext context, DriverProfileModel driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently erase ${driver.name} from the fleet network?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await http
                    .delete(
                      Uri.parse(
                        '$backendUrl/auth/delete-driver/${driver.userId}',
                      ),
                    )
                    .timeout(const Duration(seconds: 10));

                if (res.statusCode == 200) {
                  _triggerInstantRefresh();
                }
              } catch (e) {
                debugPrint("❌ Failure purging account records: $e");
              }
            },
            child: const Text(
              'Delete permanently',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
        // The unique value key tells Flutter to destroy the old layout cache and fetch data immediately
        key: ValueKey('admin_drivers_list_$_refreshSeed'),
        canManage: true,
        onDriverTapped: (ctx, model) => _showDriverModal(ctx, model),

        // FIX: Wrapped the header in a Wrap so the Title and "Add Driver" button
        // drop to the next line on narrow mobile screens instead of throwing an overflow error!
        customHeader: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            const Text(
              'Driver Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showDriverModal(context, null),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Add Driver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
