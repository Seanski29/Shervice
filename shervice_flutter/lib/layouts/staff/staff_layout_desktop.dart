import 'package:flutter/material.dart';
import '../../screens/staff/staff_dashboard.dart';
import '../../screens/staff/staff_vehicle.dart';
import '../../screens/staff/staff_schedules.dart';
import '../../screens/staff/staff_trips.dart';
import '../../screens/staff/staff_drivers.dart';
import '../../screens/staff/staff_attendance.dart';
import '../../screens/staff/staff_analytics.dart';
import '../../login/login.dart';
import '../../screens/staff/staff_settings.dart';

class StaffLayoutDesktop extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String companyName;

  const StaffLayoutDesktop({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.companyName,
  });

  @override
  State<StaffLayoutDesktop> createState() => _StaffLayoutDesktopState();
}

class _StaffLayoutDesktopState extends State<StaffLayoutDesktop> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  List<Widget> get _screens => [
    StaffDashboard(
      staffName: widget.staffName,
      companyName: widget.companyName,
    ),
    StaffVehicle(staffId: widget.staffId),
    StaffSchedules(staffId: widget.staffId),
    StaffTrips(staffId: widget.staffId),
    const StaffDrivers(),
    const StaffAttendance(),
    const StaffAnalytics(),

    StaffSettings(
      staffId: widget.staffId,
      staffName: widget.staffName,
      companyName: widget.companyName,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 260 : 76,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Consistent Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 24,
                        ),
                      );
                    },
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
                          alignment: Alignment.centerLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'SHERVICE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Staff Portal',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'Dashboard', Icons.grid_view),
                _buildNavItem(
                  1,
                  'Fleet Management',
                  Icons.directions_car_outlined,
                ),
                _buildNavItem(
                  2,
                  'Pending Requests',
                  Icons.calendar_month_outlined,
                ),
                _buildNavItem(
                  3,
                  'Dispatch History',
                  Icons.assignment_turned_in,
                ),
                _buildNavItem(4, 'Driver Records', Icons.people_outline),
                // _buildNavItem(5, 'Attendance', Icons.how_to_reg),
                // _buildNavItem(6, 'Predictive AI', Icons.analytics),
                _buildNavItem(7, 'Settings', Icons.settings_outlined),
              ],
            ),
          ),

          const Divider(color: Colors.white10, thickness: 1, height: 1),
          _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon, {
    bool isLogout = false,
  }) {
    bool isActive = _selectedIndex == index && !isLogout;
    return InkWell(
      onTap: () =>
          isLogout ? _confirmLogout() : setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: _isSidebarExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 20,
            ),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            onPressed: () =>
                setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
          const Spacer(),
          const SizedBox(width: 24),
          SlideInWelcomeWidget(role: widget.staffName),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED WELCOME WIDGET
// ============================================================================
class SlideInWelcomeWidget extends StatefulWidget {
  final String role;
  const SlideInWelcomeWidget({super.key, required this.role});

  @override
  State<SlideInWelcomeWidget> createState() => _SlideInWelcomeWidgetState();
}

class _SlideInWelcomeWidgetState extends State<SlideInWelcomeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _controller.reverse();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'Welcome, ${widget.role}!',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
