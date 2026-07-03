import 'package:flutter/material.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_schedules.dart';
import '../../screens/admin/admin_drivers.dart';
import '../../screens/admin/admin_vehicles.dart';
import '../../screens/admin/admin_users.dart';
import '../../screens/admin/admin_settings.dart';
import '../../screens/admin/admin_feedbacks.dart';
import '../../login/login.dart';
// 1. Import the Ploop wrapper
import '../../widgets/shervice_floating_stack.dart';
import '../../constant.dart';

class AdminDesktopLayout extends StatefulWidget {
  final String adminId; 
  const AdminDesktopLayout({super.key, required this.adminId});

  @override
  State<AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  // 2. Initializing screens inside the state or getter ensures access to widget.adminId
  List<Widget> get _screens => [
    const AdminDashboard(),
    const AdminSchedules(),
    const AdminDriver(),
    const AdminFleet(),
    const AdminUsers(),
    AdminSettings(adminId: widget.adminId),
  ];

  @override
  Widget build(BuildContext context) {
    // 3. Apply the "Ploop" here! The chatbot is now handled globally.
    return SherviceFloatingStack(
      userRole: 'Admin',
      userName: 'System Admin',
      localIp: localIp, // Ensure this is imported from constant.dart
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Row(
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
        ),
      ),
    );
  }

  // ... (Keep your existing _buildSidebar and _buildHeader methods below)
  // ... existing code ...
  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 260 : 76,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                      return const Center(child: Icon(Icons.directions_car, color: Colors.blue, size: 24));
                    },
                  ),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/shervice - white.jpg', height: 25, fit: BoxFit.contain),
                        const SizedBox(height: 4),
                        const Text('Admin Portal', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
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
                _buildNavItem(0, 'Overview', Icons.grid_view),
                _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Driver Profiles', Icons.people_outline),
                _buildNavItem(3, 'Vehicle Status', Icons.directions_car_outlined),
                _buildNavItem(4, 'System Users', Icons.admin_panel_settings_outlined),
                _buildNavItem(5, 'System Settings', Icons.settings_outlined),
              ],
            ),
          ),
          _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
          const SizedBox(height: 20),
        ],
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
            onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
          const Spacer(),
          const SlideInWelcomeWidget(role: 'Admin'),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = _selectedIndex == index && !isLogout;
    return InkWell(
      onTap: () {
        if (isLogout) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        } else {
          setState(() => _selectedIndex = index);
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
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}

class SlideInWelcomeWidget extends StatefulWidget {
  final String role;
  const SlideInWelcomeWidget({super.key, required this.role});

  @override
  State<SlideInWelcomeWidget> createState() => _SlideInWelcomeWidgetState();
}

class _SlideInWelcomeWidgetState extends State<SlideInWelcomeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
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
      child: Text(
        'Welcome, ${widget.role}',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


// Keep your SlideInWelcomeWidget class here...