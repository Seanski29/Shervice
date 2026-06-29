import 'package:flutter/material.dart';
import '../../screens/staff/staff_dashboard.dart';
import '../../screens/staff/staff_vehicle.dart';
import '../../screens/staff/staff_schedules.dart';
import '../../screens/staff/staff_trips.dart';
import '../../screens/staff/staff_drivers.dart';
import '../../screens/staff/staff_attendance.dart';
import '../../screens/staff/staff_analytics.dart';
import '../../login/login.dart';

class StaffLayoutMobile extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String companyName;

  const StaffLayoutMobile({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.companyName,
  });

  @override
  State<StaffLayoutMobile> createState() => _StaffLayoutMobileState();
}

class _StaffLayoutMobileState extends State<StaffLayoutMobile> {
  int _selectedIndex = 0;

  // Shortened Titles for Bottom Nav to prevent text from overflowing
  final List<String> _shortTitles = [
    'Overview',
    'Fleet',
    'Requests',
    'History',
    'Drivers',
    'Attendance',
    'Analytics',
  ];

  // Icons matching each screen
  final List<IconData> _icons = [
    Icons.grid_view,
    Icons.directions_car_outlined,
    Icons.calendar_month_outlined,
    Icons.assignment_turned_in,
    Icons.people_outline,
    Icons.how_to_reg,
    Icons.analytics,
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      StaffDashboard(
        staffName: widget.staffName,
        companyName: widget.companyName,
      ),
      const StaffVehicle(),
      StaffSchedules(staffId: widget.staffId),
      StaffTrips(staffId: widget.staffId),
      const StaffDrivers(),
      const StaffAttendance(),
      const StaffAnalytics(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.directions_car, color: Colors.blue, size: 18));
                },
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/shervice - white.jpg',
              height: 25,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'SHERVICE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            onPressed: () => _confirmLogout(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: [
              screens[_selectedIndex],
              // Floating sliding welcome widget for mobile
              Positioned(
                top: 16,
                right: 16,
                child: SlideInWelcomeWidget(role: widget.staffName),
              ),
            ],
          ),
        ),
      ),
      
      // Custom horizontally scrollable Bottom Navigation Bar for 7 items
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ]
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_shortTitles.length, (index) {
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    // UX FIX: Dividing by 4.5 cuts the 5th icon in half,
                    // providing a visual cue to swipe left to see the remaining items.
                    width: MediaQuery.of(context).size.width / 4.5,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[index],
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

class _SlideInWelcomeWidgetState extends State<SlideInWelcomeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(1.5, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            Text('Welcome, ${widget.role}!', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}