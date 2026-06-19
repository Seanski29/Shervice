import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_schedules.dart';
import '../screens/admin/admin_drivers.dart';
import '../screens/admin/admin_vehicles.dart';
import '../screens/admin/admin_users.dart';
import '../screens/admin/admin_settings.dart';

class AdminMobileLayout extends StatefulWidget {
  const AdminMobileLayout({super.key});

  @override
  State<AdminMobileLayout> createState() => _AdminMobileLayoutState();
}

class _AdminMobileLayoutState extends State<AdminMobileLayout> {
  int _selectedIndex = 0;

  // This list MUST exactly match the Desktop layout list
  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminSchedules(),
    const AdminDrivers(),
    const AdminVehicles(),
    const AdminUsers(),
    const AdminSettings(),
  ];

@override
  Widget build(BuildContext context) {
    return Scaffold(
      // NEW: Added the Logo to the Mobile AppBar
      appBar: AppBar(
        title: Row(
          children: [
           ClipRRect(
  borderRadius: BorderRadius.circular(20), // Keeps the logo perfectly circular
  child: Image.asset(
    'assets/GT LANTIN CAR RENTALS.jpg',
    width: 40,
    height: 40,
    fit: BoxFit.cover, // Ensures the image fills the circle without squishing
  ),
),
            const SizedBox(width: 12),
            const Text(
              'SHERVICE', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: _screens[_selectedIndex],
      ),

      bottomNavigationBar: BottomNavigationBar(
        // Forces the bar to keep our styling even with 6 items
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// We include the same placeholder widget here for the mobile view
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'This module is currently under development.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}