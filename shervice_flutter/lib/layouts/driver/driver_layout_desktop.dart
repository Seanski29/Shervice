import 'package:flutter/material.dart';
import '../../screens/driver/driver_dashboard.dart';
import '../../screens/driver/driver_schedules.dart';
import '../../screens/driver/driver_profile.dart';
import '../../login/login.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/shervice_floating_stack.dart';
import '../../constant.dart';
import '../../session_manager.dart';

class DriverLayoutDesktop extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String companyName;

  const DriverLayoutDesktop({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.companyName,
  });

  @override
  State<DriverLayoutDesktop> createState() => _DriverLayoutDesktopState();
}

class _DriverLayoutDesktopState extends State<DriverLayoutDesktop> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  }

  List<Widget> get _screens => [
        DriverDashboard(driverName: widget.driverName, driverId: widget.driverId),
        DriverSchedules(driverId: widget.driverId),
        DriverProfile(driverName: widget.driverName, driverId: widget.driverId),
      ];

  @override
  Widget build(BuildContext context) {
    return SherviceFloatingStack(
      userRole: 'Driver',
      userName: widget.driverName,
      localIp: localIp,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarExpanded ? 260 : 76,
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  // Branding Header (with toggle button when expanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_isSidebarExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/shervice - white.jpg',
                                  height: 25,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Text(
                                    'SHERVICE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Driver Portal',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ─── TOGGLE BUTTON (inside sidebar when expanded) ───
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white70),
                            onPressed: _toggleSidebar,
                            tooltip: 'Collapse',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, thickness: 1, height: 1),
                  const SizedBox(height: 16),

                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildSidebarItem(
                          Icons.dashboard_outlined,
                          'Dashboard',
                          0,
                        ),
                        _buildSidebarItem(
                          Icons.calendar_month_outlined,
                          'My Schedule',
                          1,
                        ),
                        _buildSidebarItem(Icons.person_outline, 'Profile', 2),
                      ],
                    ),
                  ),

                  // Footer Logout
                  const Divider(color: Colors.white10, thickness: 1, height: 1),
                  _buildSidebarItem(
                    Icons.logout,
                    'Log Out',
                    99,
                    isLogout: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // ─── HEADER (white, contains toggle when sidebar collapsed) ───
                  Container(
                    height: 70,
                    color: Colors.white, // remained white (not off‑white)
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // ─── TOGGLE BUTTON (only when sidebar is collapsed) ───
                        if (!_isSidebarExpanded)
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            onPressed: _toggleSidebar,
                            tooltip: 'Expand',
                          ),
                        if (!_isSidebarExpanded) const SizedBox(width: 4),
                        const Spacer(),
                        NotificationBell(
                          role: 'Driver',
                          userId: widget.driverId,
                          userName: widget.driverName,
                          companyName: widget.companyName,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  Expanded(child: _screens[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index, {
    bool isLogout = false,
  }) {
    final isSelected = _selectedIndex == index && !isLogout;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => isLogout
            ? _confirmLogout(context)
            : setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 20,
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () async {
              await SessionManager.clearSession();
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}