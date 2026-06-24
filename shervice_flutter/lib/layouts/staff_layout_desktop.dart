import 'package:flutter/material.dart';
import '../login/login.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_vehicle.dart';
import '../screens/staff/staff_schedules.dart';
import '../screens/staff/staff_drivers.dart'; // Assume created
import '../screens/staff/staff_attendance.dart'; // Assume created
import '../screens/staff/staff_analytics.dart'; // Assume created

class StaffLayoutDesktop extends StatefulWidget {
  const StaffLayoutDesktop({super.key});

  @override
  State<StaffLayoutDesktop> createState() => _StaffLayoutDesktopState();
}

class _StaffLayoutDesktopState extends State<StaffLayoutDesktop> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StaffDashboard(),
    const StaffVehicle(),
    const StaffSchedules(),
    const StaffDrivers(), // Replace with StaffDriver()
    const StaffAttendance(), // Replace with StaffAttendance()
    const StaffAnalytics(), // Replace with StaffAnalytics()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/logo.jpg', width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 36, height: 36, color: Colors.white, child: const Icon(Icons.directions_car, color: Colors.green)))),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('SHERVICE\nSTAFF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic, height: 1.2))),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildItem(Icons.dashboard, 'Overview', 0),
                      _buildItem(Icons.local_shipping, 'Vehicles', 1),
                      _buildItem(Icons.calendar_month, 'Schedules', 2),
                      _buildItem(Icons.group, 'Drivers', 3),
                      _buildItem(Icons.how_to_reg, 'Attendance', 4),
                      _buildItem(Icons.analytics, 'Predictive AI', 5),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: InkWell(
                    onTap: () => _handleLogout(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [Icon(Icons.logout, color: Colors.redAccent, size: 22), SizedBox(width: 16), Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600))]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, int index) {
    final isSel = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: isSel ? Colors.blue.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(icon, color: isSel ? Colors.blue.shade400 : Colors.grey.shade400, size: 22), const SizedBox(width: 16), Text(title, style: TextStyle(color: isSel ? Colors.white : Colors.grey.shade300, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal))])),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Logout'), content: const Text('Are you sure you want to log out?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Logout', style: TextStyle(color: Colors.white)))]));
  }
}