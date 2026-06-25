import 'package:flutter/material.dart';
import '../../screens/oic/oic_dashboard.dart';
import '../../screens/oic/oic_schedules.dart';
import '../../screens/oic/oic_trips.dart';
import '../../login/login.dart';

class OicLayoutDesktop extends StatefulWidget {
  const OicLayoutDesktop({super.key});

  @override
  State<OicLayoutDesktop> createState() => _OicLayoutDesktopState();
}

class _OicLayoutDesktopState extends State<OicLayoutDesktop> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Widget> _screens = [const OicDashboard(), const OicSchedules(), const OicTrips()];

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
                Expanded( // This Expanded is MANDATORY
                  child: _screens[_selectedIndex],
                ),
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
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('logo.jpg', width: 40, height: 40, fit: BoxFit.cover)),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 16),
                  const Expanded(child: Text('SHERVICE\nOIC Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic))),
                ]
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded( // The ListView is inside an Expanded, no shrinkWrap needed
            child: ListView(
              children: [
                _buildNavItem(0, 'Manage', Icons.dashboard),
                _buildNavItem(1, 'Schedules', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Trip Logs', Icons.list_alt),
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
        decoration: BoxDecoration(color: isActive ? Colors.blue.shade600 : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
            if (_isSidebarExpanded) ...[const SizedBox(width: 16), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() => Container(height: 70, decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [IconButton(icon: const Icon(Icons.menu), onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded)), const Spacer(), const Text('OIC User')]));

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Logout'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Logout'))]));
  }
}