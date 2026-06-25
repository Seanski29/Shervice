import 'package:flutter/material.dart';
import '../../screens/staff/staff_dashboard.dart';
import '../../screens/staff/staff_vehicle.dart';
import '../../screens/staff/staff_schedules.dart';
import '../../screens/staff/staff_drivers.dart';
import '../../screens/staff/staff_attendance.dart';
import '../../screens/staff/staff_analytics.dart';
import '../../login/login.dart';

class StaffLayoutDesktop extends StatefulWidget {
  const StaffLayoutDesktop({super.key});

  @override
  State<StaffLayoutDesktop> createState() => _StaffLayoutDesktopState();
}

class _StaffLayoutDesktopState extends State<StaffLayoutDesktop> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Widget> _screens = [
    const StaffDashboard(),
    const StaffVehicle(),
    const StaffSchedules(),
    const StaffDrivers(),
    const StaffAttendance(),
    const StaffAnalytics(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarExpanded ? 260 : 76,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('logo.jpg', width: 40, height: 40, fit: BoxFit.cover)),
                      if (_isSidebarExpanded) ...[
                        const SizedBox(width: 16),
                        const Expanded(child: Text('SHERVICE\nStaff Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic))),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(0, 'Dashboard', Icons.grid_view),
                      _buildNavItem(1, 'Fleet Management', Icons.directions_car_outlined),
                      _buildNavItem(2, 'Schedules', Icons.calendar_month_outlined),
                      _buildNavItem(3, 'Driver Records', Icons.people_outline),
                      _buildNavItem(4, 'Attendance', Icons.how_to_reg),
                      _buildNavItem(5, 'Predictive AI', Icons.analytics),
                    ],
                  ),
                ),
                _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: Colors.grey), onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded)),
          const Spacer(),
          const Text('Staff User', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = _selectedIndex == index && !isLogout;
    return InkWell(
      onTap: () => isLogout ? _confirmLogout() : setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isActive ? Colors.blue.shade600 : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
            if (_isSidebarExpanded) ...[const SizedBox(width: 16), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Logout'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Logout'))]));
  }
}