import 'package:flutter/material.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_schedules.dart';
import '../../screens/admin/admin_drivers.dart';
import '../../screens/admin/admin_vehicles.dart';
import '../../screens/admin/admin_users.dart';
import '../../screens/admin/admin_settings.dart';
import '../../screens/admin/admin_feedbacks.dart';
import '../../login/login.dart';

class AdminDesktopLayout extends StatefulWidget {
  final String adminId; // 👇 Add this
  const AdminDesktopLayout({super.key, required this.adminId});

  @override
  State<AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  late final List<Widget> _screens = [
    // Note the "late final" so we can access widget.adminId
    const AdminDashboard(),
    const AdminSchedules(),
    const AdminDriver(),
    const AdminFleet(),
    const AdminUsers(),
    AdminSettings(
      adminId: widget.adminId,
    ), // 👇 Pass the ID into the settings page
    const AdminFeedbacks(), // (Remove this line from Mobile layout if you took it out earlier)
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
                        // Perfectly circular logo container with white background
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
                                // White text logo image
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
                                        fontSize: 16,
                                        letterSpacing: 1.0,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Admin Portal',
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

                  // Expanded ListView isolates scrolling and prevents bottom overflow
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildNavItem(0, 'Overview', Icons.grid_view),
                        _buildNavItem(
                          1,
                          'Schedules',
                          Icons.calendar_month_outlined,
                        ),
                        _buildNavItem(
                          2,
                          'Driver Profiles',
                          Icons.people_outline,
                        ),
                        _buildNavItem(
                          3,
                          'Vehicle Status',
                          Icons.directions_car_outlined,
                        ),
                        _buildNavItem(
                          4,
                          'System Users',
                          Icons.admin_panel_settings_outlined,
                        ),
                        _buildNavItem(
                          5,
                          'System Settings',
                          Icons.settings_outlined,
                        ),
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
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
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
                        const SlideInWelcomeWidget(role: 'Admin'),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  // Render targeted module
                  Expanded(child: _screens[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
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
      onTap: () {
        if (isLogout) {
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
                      Navigator.pop(dialogContext);
                    },
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
        } else {
          setState(() {
            _selectedIndex = index;
          });
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
