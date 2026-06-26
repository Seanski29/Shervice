import 'package:flutter/material.dart';
import '../../../screens/staff/staff_dashboard.dart';
import '../../../screens/staff/staff_vehicle.dart';
import '../../../screens/staff/staff_schedules.dart';
import '../../../screens/staff/staff_drivers.dart';
import '../../../screens/staff/staff_attendance.dart';
import '../../../screens/staff/staff_analytics.dart';
import '../../../login/login.dart';

class StaffLayoutMobile extends StatefulWidget {
  const StaffLayoutMobile({super.key});

  @override
  State<StaffLayoutMobile> createState() => _StaffLayoutMobileState();
}

class _StaffLayoutMobileState extends State<StaffLayoutMobile> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const StaffDashboard(), const StaffVehicle(), const StaffSchedules(),
    const StaffDrivers(), const StaffAttendance(), const StaffAnalytics(),
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
              child: Center(child: Text('STAFF MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerTile(0, 'Dashboard', Icons.grid_view),
                  _buildDrawerTile(1, 'Fleet', Icons.directions_car_outlined),
                  _buildDrawerTile(2, 'Schedules', Icons.calendar_month_outlined),
                  _buildDrawerTile(3, 'Drivers', Icons.people_outline),
                  _buildDrawerTile(4, 'Attendance', Icons.how_to_reg),
                  _buildDrawerTile(5, 'Analytics', Icons.analytics),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout'), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
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
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}