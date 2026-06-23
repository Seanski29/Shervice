import 'package:flutter/material.dart';

// Import your screens
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_schedules.dart';
import '../screens/admin/admin_drivers.dart';
import '../screens/admin/admin_vehicles.dart';
import '../screens/admin/admin_users.dart';
import '../screens/admin/admin_settings.dart';
import '../screens/admin/admin_feedbacks.dart';

// IMPORTANT: Import the Login Screen
import '../login/login.dart';

class AdminMobileLayout extends StatefulWidget {
  const AdminMobileLayout({super.key});

  @override
  State<AdminMobileLayout> createState() => _AdminMobileLayoutState();
}

class _AdminMobileLayoutState extends State<AdminMobileLayout> {
  int _selectedIndex = 0;

  // 6 Screens total
  final List<Widget> _screens = [
    const AdminDashboard(), // Index 0
    const AdminSchedules(), // Index 1
    const AdminDriver(),   // Index 2
    const AdminFleet(),  // Index 3
    const AdminUsers(),     // Index 4
    const AdminSettings(),  // Index 5
    // Note: AdminFeedbacks() is index 6, but your BottomNav only has 6 items (indices 0-5). 
    // You might need to add a 7th item to the bottom nav if you want to access this screen on mobile!
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
                'assets/logo.jpg', // Make sure you include the 'assets/' path
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 30,
                    height: 30,
                    color: Colors.white,
                    child: const Icon(Icons.directions_car, color: Colors.green, size: 16),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'SHERVICE',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        // Added the Log Out button to the top right with Confirmation Dialog
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
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
                          // Properly route back to LoginScreen
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
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 20,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.grid_view)),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month_outlined)),
              label: 'Schedules',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people_outline)),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.directions_car_outlined)),
              label: 'Fleet',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.admin_panel_settings_outlined)),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.settings_outlined)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}