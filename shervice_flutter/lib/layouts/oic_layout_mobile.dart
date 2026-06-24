import 'package:flutter/material.dart';
import '../login/login.dart'; // Ensure correct path
import '../screens/oic/oic_dashboard.dart';
import '../screens/oic/oic_schedules.dart';
import '../screens/oic/oic_trips.dart';

class OicLayoutMobile extends StatefulWidget {
  const OicLayoutMobile({super.key});

  @override
  State<OicLayoutMobile> createState() => _OicLayoutMobileState();
}

class _OicLayoutMobileState extends State<OicLayoutMobile> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OicDashboard(),
    const OicSchedules(),
    const OicTrips(),
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
              child: Image.asset('assets/logo.jpg', width: 30, height: 30, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 30, height: 30, color: Colors.white, child: const Icon(Icons.directions_car, color: Colors.green, size: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('SHERVICE OIC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Manage'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedules'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Logs'),
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
          content: const Text('Are you sure you want to log out of your account?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
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