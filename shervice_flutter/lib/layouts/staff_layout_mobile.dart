import 'package:flutter/material.dart';
import '../../screens/staff/staff_dashboard.dart';
import '../../screens/staff/staff_vehicle.dart';
import '../../screens/staff/staff_schedules.dart';
import '../../screens/staff/staff_trips.dart';
import '../../screens/staff/staff_drivers.dart';
import '../../screens/staff/staff_attendance.dart';
import '../../screens/staff/staff_analytics.dart';
import '../../login/login.dart';
import '../../screens/staff/staff_settings.dart';

class StaffLayoutMobile extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String companyName;

  const StaffLayoutMobile({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.companyName,
  });

  @override
  State<StaffLayoutMobile> createState() => _StaffLayoutMobileState();
}

class _StaffLayoutMobileState extends State<StaffLayoutMobile> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    StaffDashboard(
      staffName: widget.staffName,
      companyName: widget.companyName,
    ),
    const StaffVehicle(),
    StaffSchedules(staffId: widget.staffId),
    StaffTrips(staffId: widget.staffId),
    const StaffDrivers(),
    const StaffAttendance(),
    const StaffAnalytics(),
    StaffSettings(
      staffId: widget.staffId,
      staffName: widget.staffName,
      companyName: widget.companyName,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('SHERVICE Staff'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1E293B)),
              child: Center(
                child: Text(
                  'STAFF MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(0, 'Dashboard', Icons.grid_view),
                  _buildDrawerTile(
                    1,
                    'Fleet Management',
                    Icons.directions_car_outlined,
                  ),
                  _buildDrawerTile(
                    2,
                    'Pending Requests',
                    Icons.calendar_month_outlined,
                  ),
                  _buildDrawerTile(
                    3,
                    'Dispatch History',
                    Icons.assignment_turned_in,
                  ), // 👈 3. Add the navigation tile
                  _buildDrawerTile(4, 'Driver Records', Icons.people_outline),
                  _buildDrawerTile(5, 'Attendance', Icons.how_to_reg),
                  _buildDrawerTile(6, 'Predictive AI', Icons.analytics),
                  _buildDrawerTile(7, 'Settings', Icons.settings_outlined),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawerTile(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
