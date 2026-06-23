import 'package:flutter/material.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_schedules.dart';
import '../screens/admin/admin_drivers.dart';
import '../screens/admin/admin_vehicles.dart';
import '../screens/admin/admin_users.dart';
import '../screens/admin/admin_settings.dart';
import '../screens/admin/admin_feedbacks.dart';


class AdminDesktopLayout extends StatefulWidget {
  const AdminDesktopLayout({super.key});

  @override
  State<AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminSchedules(),
    const AdminDriver(),
    const AdminFleet(),
    const AdminUsers(),
    const AdminSettings(),
    const AdminFeedbacks(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Row(
          children: [
            // Animated sidebar container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarExpanded ? 260 : 76,
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header Logo and Title section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'logo.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Colors.white,
                                child: const Icon(Icons.directions_car, color: Colors.green),
                              );
                            },
                          ),
                        ),
                        if (_isSidebarExpanded) ...[
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SHERVICE', 
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Admin Portal', 
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Expanded ListView isolates scrolling and prevents bottom overflow
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildNavItem(0, 'Overview', Icons.grid_view),
                        _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                        _buildNavItem(2, 'Driver Profiles', Icons.people_outline),
                        _buildNavItem(3, 'Vehicle Status', Icons.directions_car_outlined),
                        _buildNavItem(4, 'System Users', Icons.admin_panel_settings_outlined),
                        _buildNavItem(5, 'System Settings', Icons.settings_outlined),
                      ],
                    ),
                  ),
                  
                  // Static footer item
                  _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Main App Content Window
            Expanded(
              child: Column(
                children: [
                  // Top Navbar Header
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _isSidebarExpanded = !_isSidebarExpanded;
                            });
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue,
                                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1)),
                                  Text('Admin', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  // Render targeted module
                  Expanded(
                    child: _screens[_selectedIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = _selectedIndex == index && !isLogout;

    return InkWell(
      onTap: () {
        if (isLogout) {
          // Redirect the browser back to the React Login screen
          html.window.location.href = 'http://localhost:3000'; 
        } else {
          setState(() { _selectedIndex = index; });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}