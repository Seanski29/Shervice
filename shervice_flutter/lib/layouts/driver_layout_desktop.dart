import 'package:flutter/material.dart';
import 'dart:html' as html; // The bridge to control the browser URL

import '../screens/driver/driver_dashboard.dart';
import '../screens/driver/driver_schedules.dart';
import '../screens/driver/driver_ratings.dart';
import '../screens/driver/driver_profile.dart';

class DriverLayoutDesktop extends StatefulWidget {
  const DriverLayoutDesktop({super.key});

  @override
  State<DriverLayoutDesktop> createState() => _DriverLayoutDesktopState();
}

class _DriverLayoutDesktopState extends State<DriverLayoutDesktop> {
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
      body: Row(
        children: [
          // 1. The Admin-Style Sidebar
          Container(
            width: 260,
            color: const Color(0xFF1E293B), 
            child: Column(
              children: [
                // Branding Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 36, height: 36, color: Colors.white,
                            child: const Icon(Icons.directions_car, color: Colors.green, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SHERVICE\nDRIVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, thickness: 1, height: 1),
                const SizedBox(height: 16),
                
                // Sidebar Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarItem(Icons.dashboard, 'Dashboard', 0),
                      _buildSidebarItem(Icons.calendar_month, 'My Schedule', 1),
                      _buildSidebarItem(Icons.star, 'Ratings & Metrics', 2),
                      _buildSidebarItem(Icons.person, 'Profile & Settings', 3),
                    ],
                  ),
                ),

                // LOGOUT BUTTON pinned to the bottom
                const Divider(color: Colors.white24, thickness: 1, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: InkWell(
                    onTap: () {
                      // Redirect out of Flutter back to React
                      html.window.location.href = 'http://localhost:3000';
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 22),
                          SizedBox(width: 16),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 2. The Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.notifications_none, color: Colors.grey),
                      const SizedBox(width: 24),
                      Text('Driver ID: DRV-001', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.shade100,
                        child: Text('RR', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                
                // Screen Content
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

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue.shade400 : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}