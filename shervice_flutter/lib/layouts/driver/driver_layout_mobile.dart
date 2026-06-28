import 'package:flutter/material.dart';
import '../../screens/driver/driver_dashboard.dart';
import '../../screens/driver/driver_schedules.dart';
import '../../screens/driver/driver_ratings.dart';
import '../../screens/driver/driver_profile.dart';
import '../../login/login.dart';

class DriverLayoutMobile extends StatefulWidget {
  final String driverId; // ✅ Added driverId
  final String driverName;
  final String companyName; // ✅ Added companyName

  const DriverLayoutMobile({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.companyName,
  });

  @override
  State<DriverLayoutMobile> createState() => _DriverLayoutMobileState();
}

class _DriverLayoutMobileState extends State<DriverLayoutMobile> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    DriverDashboard(driverName: widget.driverName),
    DriverSchedules(
      driverId: widget.driverId,
    ), // ✅ Removed 'const' and passed the ID
    const DriverRatings(),
    DriverProfile(driverName: widget.driverName),
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
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SHERVICE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Log Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Confirm Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Are you sure you want to log out of your account?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Ratings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
