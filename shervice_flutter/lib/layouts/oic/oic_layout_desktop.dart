import 'dart:async';

import 'package:flutter/material.dart';
import '../../../screens/oic/oic_dashboard.dart';
import '../../../screens/oic/oic_schedules.dart';
import '../../../screens/oic/oic_trips.dart';
import '../../../screens/oic/oic_settings.dart';
import '../../../login/login.dart';

class OicLayoutDesktop extends StatefulWidget {
  final String oicId;
  final String oicName;
  final String companyName;

  const OicLayoutDesktop({
    super.key,
    required this.oicId,
    required this.oicName,
    required this.companyName,
  });

  @override
  State<OicLayoutDesktop> createState() => _OicLayoutDesktopState();
}

class _OicLayoutDesktopState extends State<OicLayoutDesktop> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    // List of screens available to the OIC
    final List<Widget> screens = [
      OicDashboard(
        oicName: widget.oicName,
        companyName: widget.companyName,
        oicId: widget.oicId,
      ),
      OicSchedules(oicId: widget.oicId),
      OicTrips(oicId: widget.oicId),
      // 👈 Added OicSettings here
      OicSettings(
        oicId: widget.oicId,
        oicName: widget.oicName,
        companyName: widget.companyName,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: screens[_selectedIndex]),
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
                        child: Icon(Icons.directions_car, color: Colors.blue, size: 24),
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
                          alignment: Alignment.centerLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('SHERVICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                          },
                        ),
                        const Text('OIC Portal', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                _buildNavItem(0, 'Manage', Icons.dashboard),
                _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Trip Logs', Icons.list_alt),
                _buildNavItem(3, 'Settings', Icons.settings),
              ],
            ),
          ),
          _buildNavItem(99, 'Log Out', Icons.logout, isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = _selectedIndex == index && !isLogout;
    return InkWell(
      onTap: () => isLogout ? _confirmLogout(context) : setState(() => _selectedIndex = index),
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
              Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        height: 70,
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.menu, color: Colors.grey), onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded)),
            const Spacer(),
            SlideInWelcomeWidget(role: widget.oicName),
            const SizedBox(width: 16),
          ],
        ),
      );

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
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
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(1.5, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();

    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _offsetAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade200), borderRadius: BorderRadius.circular(30)),
          child: Row(children: [Icon(Icons.check_circle, color: Colors.green.shade600, size: 18), const SizedBox(width: 8), Text('Welcome, ${widget.role}!', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold))]),
        ),
      );
}