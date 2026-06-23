import 'package:flutter/material.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/driver/driver_schedules.dart';
import '../screens/driver/driver_ratings.dart';
import '../screens/driver/driver_profile.dart';

// IMPORTANT: Import the Login Screen
import '../login/login.dart';

class DriverLayoutMobile extends StatefulWidget {
  const DriverLayoutMobile({super.key});

  @override
  State<DriverLayoutMobile> createState() => _DriverLayoutMobileState();
}

class _DriverLayoutMobileState extends State<DriverLayoutMobile> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DriverDashboard(),
    const DriverSchedules(),
    const DriverRatings(),
    const DriverProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevents a back button from appearing
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
                  width: 30, height: 30, color: Colors.white,
                  child: const Icon(Icons.directions_car, color: Colors.green, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SHERVICE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          // LOGOUT BUTTON directly in the app bar for mobile with Confirmation Dialog
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Log Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to log out of your account?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close dialog
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close dialog
                          // Navigate back to LoginScreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Ratings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}