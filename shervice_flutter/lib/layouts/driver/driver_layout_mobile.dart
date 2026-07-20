import 'package:flutter/material.dart';
import '../../screens/driver/driver_dashboard.dart';
import '../../screens/driver/driver_schedules.dart';
import '../../screens/driver/driver_ratings.dart';
import '../../screens/driver/driver_profile.dart';
import '../../login/login.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/shervice_floating_stack.dart';
import '../../constant.dart';
import '../../session_manager.dart';

class DriverLayoutMobile extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String companyName;

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

  // The 4 Screens for the Driver
  List<Widget> get _screens => [
    DriverDashboard(driverName: widget.driverName, driverId: widget.driverId),
    DriverSchedules(driverId: widget.driverId),
    DriverProfile(driverName: widget.driverName, driverId: widget.driverId),
  ];

  final List<String> _titles = ['Dashboard', 'Schedule', 'Profile'];

  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.calendar_month_outlined,
    Icons.settings_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return SherviceFloatingStack(
      userRole: 'Driver',
      userName: widget.driverName,
      localIp: localIp,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/shervice - white.jpg',
                height: 25,
                fit: BoxFit.contain,
              ),
            ],
          ),
          actions: [
            NotificationBell(
              role: 'Driver',
              userId: widget.driverId,
              userName: widget.driverName,
              companyName: widget.companyName,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
              onPressed: () => _confirmLogout(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _screens[_selectedIndex],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_titles.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
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
                        _titles[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
            onPressed: () async {
              await SessionManager.clearSession();
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
