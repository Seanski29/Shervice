import 'package:flutter/material.dart';
import '../login/login.dart'; // Ensure correct path
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_vehicle.dart';
import '../screens/staff/staff_schedules.dart';
import '../screens/staff/staff_drivers.dart'; 
import '../screens/staff/staff_attendance.dart'; 
import '../screens/staff/staff_analytics.dart'; 

class StaffLayoutMobile extends StatefulWidget {
  const StaffLayoutMobile({super.key});

  @override
  State<StaffLayoutMobile> createState() => _StaffLayoutMobileState();
}

class _StaffLayoutMobileState extends State<StaffLayoutMobile> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StaffDashboard(),
    const StaffVehicle(),
    const StaffSchedules(),
    const StaffDrivers(), // Assuming this exists based on previous files
    const StaffAttendance(),
    const StaffAnalytics(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/logo.jpg', 
                width: 30, 
                height: 30, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 30, 
                  height: 30, 
                  color: Colors.white, 
                  child: const Icon(Icons.directions_car, color: Colors.green, size: 16)
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SHERVICE STAFF', 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                fontStyle: FontStyle.italic
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _screens[_selectedIndex]),
      
      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1))
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, // Required to fit 6 items cleanly
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 10, // Scaled down slightly to fit 6 items
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Fleet'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Routes'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Drivers'),
            BottomNavigationBarItem(icon: Icon(Icons.how_to_reg), label: 'Logs'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'AI'),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out of your staff account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}