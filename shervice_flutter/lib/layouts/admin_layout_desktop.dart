import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_schedules.dart';
import '../screens/admin/admin_drivers.dart';
import '../screens/admin/admin_vehicles.dart';
import '../screens/admin/admin_users.dart';
import '../screens/admin/admin_settings.dart';

class AdminDesktopLayout extends StatefulWidget {
  const AdminDesktopLayout({super.key});

  @override
  State<AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;
  
  // NEW: This controls whether the sidebar is wide or collapsed
  bool _isSidebarExpanded = true;

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ---------------------------------------------------------
          // 1. CUSTOM ANIMATED SIDEBAR
          // ---------------------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarExpanded ? 260 : 76, // Expands and shrinks
            color: const Color(0xFF1E293B), // Deep Blue/Slate from your image
            child: Column(
              children: [
                // LOGO AREA
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Placeholder for GT LANTIN Logo
                      ClipRRect(
  borderRadius: BorderRadius.circular(20), // Keeps the logo perfectly circular
  child: Image.asset(
    'assets/GT LANTIN CAR RENTALS.jpg',
    width: 40,
    height: 40,
    fit: BoxFit.cover, // Ensures the image fills the circle without squishing
  ),
),
                      // Only show text if sidebar is expanded
                      if (_isSidebarExpanded) ...[
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SHERVICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic)),
                              Text('Admin Portal', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // NAVIGATION LINKS
                _buildNavItem(0, 'Overview', Icons.grid_view),
                _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Driver Profiles', Icons.people_outline),
                _buildNavItem(3, 'Vehicle Status', Icons.directions_car_outlined),
                _buildNavItem(4, 'System Users', Icons.admin_panel_settings_outlined),
                _buildNavItem(5, 'System Settings', Icons.settings_outlined),

                const Spacer(), // Pushes the logout button to the very bottom

                // LOGOUT BUTTON
                _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // 2. RIGHT SIDE CONTENT AREA
          // ---------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                // TOP APP BAR (White Area)
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // HAMBURGER MENU - Toggles the Sidebar
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                      ),
                      const Spacer(),
                      // USER PROFILE CHIP
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1)),
                                Text('Admin', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // ACTUAL PAGE CONTENT
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the buttons exactly like your screenshot
  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = _selectedIndex == index && !isLogout;

    return InkWell(
      onTap: () {
        if (!isLogout) {
          setState(() { _selectedIndex = index; });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          // Applies the blue background ONLY if it's the active tab
          color: isActive ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          // Applies the thin blue border ONLY if it's the active tab
          border: Border.all(
            color: isActive ? Colors.blue.shade400 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isActive ? Colors.white : Colors.white70, 
              size: 22
            ),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}