import 'package:flutter/material.dart';
import '../../screens/oic/oic_dashboard.dart';
import '../../screens/oic/oic_schedules.dart';
import '../../screens/oic/oic_trips.dart';
import '../../login/login.dart';

class OicLayoutMobile extends StatefulWidget {
  final String oicId;
  final String oicName;
  final String companyName;

  const OicLayoutMobile({
    super.key,
    required this.oicId,
    required this.oicName,
    required this.companyName,
  });

  @override
  State<OicLayoutMobile> createState() => _OicLayoutMobileState();
}

class _OicLayoutMobileState extends State<OicLayoutMobile> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Manage', 'Schedules', 'Logs'];

  @override
  Widget build(BuildContext context) {
    // Define screens here so we can access widget.oicName and widget.oicId
    final List<Widget> screens = [
      // FIXED: Passed the required oicId constructor parameter down to the dashboard instance
      OicDashboard(
        oicName: widget.oicName, 
        companyName: widget.companyName,
        oicId: widget.oicId,
      ),
      OicSchedules(oicId: widget.oicId),
      OicTrips(oicId: widget.oicId),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1E293B)),
              child: Center(
                child: Text(
                  'OIC PORTAL',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...List.generate(
                    3,
                    (i) => ListTile(
                      title: Text(_titles[i]),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(child: screens[_selectedIndex]),
    );
  }
}