import 'package:flutter/material.dart';

// Import your screens
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_schedules.dart';
import '../../screens/admin/admin_drivers.dart';
import '../../screens/admin/admin_vehicles.dart';
import '../../screens/admin/admin_users.dart';
import '../../screens/admin/admin_settings.dart';
import '../../screens/admin/admin_feedbacks.dart';

// IMPORTANT: Import the Login Screen
import '../../login/login.dart';

class AdminMobileLayout extends StatefulWidget {
  const AdminMobileLayout({super.key});

  @override
  State<AdminMobileLayout> createState() => _AdminMobileLayoutState();
}

class _AdminMobileLayoutState extends State<AdminMobileLayout> {
  int _selectedIndex = 0;

  // 7 Screens total
  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminSchedules(),
    const AdminDriver(),
    const AdminFleet(),
    const AdminUsers(),
    const AdminSettings(),
  ];

  // Shortened Titles for Bottom Nav to prevent text from overflowing
  final List<String> _shortTitles = [
    'Overview',
    'Schedules',
    'Drivers',
    'Fleet',
    'Users',
    'Settings',
    'Feedbacks',
  ];

  // Icons matching each screen
  final List<IconData> _icons = [
    Icons.grid_view,
    Icons.calendar_month_outlined,
    Icons.people_outline,
    Icons.directions_car_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.settings_outlined,
    Icons.forum_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Perfectly circular logo container with white background
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // White text logo image
            Image.asset(
              'assets/shervice - white.jpg',
              height: 25,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'SHERVICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // FIX: Added Padding inside SafeArea to fix pagination elements from being crushed at the bottom
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _screens[_selectedIndex],
        ),
      ),

      // FIX: Custom horizontally scrollable Bottom Navigation Bar to prevent yellow/black tapes!
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_screens.length, (index) {
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    // Dividing by 5 displays exactly 5 items and peeks at the next, prompting scrolling
                    width: MediaQuery.of(context).size.width / 5,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[index],
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortTitles[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
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
  }
}
