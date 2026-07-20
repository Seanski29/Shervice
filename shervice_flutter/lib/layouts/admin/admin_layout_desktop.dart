import 'package:flutter/material.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_schedules.dart';
import '../../screens/admin/admin_drivers.dart';
import '../../screens/admin/admin_vehicles.dart';
import '../../screens/admin/admin_users.dart';
import '../../screens/admin/admin_settings.dart';
import '../../screens/admin/admin_feedbacks.dart';
import '../../login/login.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/shervice_floating_stack.dart';
import '../../constant.dart';
import '../../session_manager.dart';
import '../../widgets/legal_policies_button.dart';

class AdminDesktopLayout extends StatefulWidget {
  final String adminId;
  const AdminDesktopLayout({super.key, required this.adminId});

  @override
  State<AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends State<AdminDesktopLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  List<Widget> get _screens => [
        const AdminDashboard(),
        const AdminSchedules(),
        const AdminDriver(),
        const AdminFleet(),
        const AdminUsers(),
        AdminSettings(adminId: widget.adminId),
      ];

  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return SherviceFloatingStack(
      userRole: 'Admin',
      userName: 'System Admin',
      localIp: localIp,
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

  // ─── SIDEBAR ───
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
                // Logo
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
                      children: [
                        Image.asset(
                          'assets/shervice - white.jpg',
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Admin Portal',
                          style: TextStyle(
                            color: Colors.white,
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
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'Overview', Icons.grid_view),
                _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Driver Profiles', Icons.people_outline),
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

  // ─── HEADER (now 5% off‑white) ───
  Widget _buildHeader() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2), // 5% off-white (was medium gray)
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
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
          const WelcomeMessage(role: 'Admin'),
          const Spacer(),
          NotificationBell(
            role: 'Admin',
            userId: widget.adminId,
            userName: 'Admin',
            companyName: '',
            iconSize: 28,
          ),
          const SizedBox(width: 16),
          const LegalPoliciesButton(
          iconColor: Colors.grey, // matches notification bell color
        ),
        ],
      ),
    );
  }

  // ─── NAVIGATION ITEM ───
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
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Confirm Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await SessionManager.clearSession();
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
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
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 20,
            ),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── WELCOME MESSAGE (auto‑disappears after 5 seconds) ───
class WelcomeMessage extends StatefulWidget {
  final String role;
  const WelcomeMessage({super.key, required this.role});

  @override
  State<WelcomeMessage> createState() => _WelcomeMessageState();
}

class _WelcomeMessageState extends State<WelcomeMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Text(
          'Welcome, ${widget.role}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}