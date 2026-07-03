import 'package:flutter/material.dart';
import '../../../screens/oic/oic_dashboard.dart';
import '../../../screens/oic/oic_schedules.dart';
import '../../../screens/oic/oic_trips.dart';
import '../../../screens/oic/oic_settings.dart';
import '../../../login/login.dart';
import '../../../widgets/shervice_floating_stack.dart';
import '../../../constant.dart';

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

  final List<String> _titles = ['Manage', 'Schedules', 'Logs', 'Settings'];
  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.calendar_month_outlined,
    Icons.list_alt,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      OicDashboard(
        oicName: widget.oicName,
        companyName: widget.companyName,
        oicId: widget.oicId,
      ),
      OicSchedules(oicId: widget.oicId),
      OicTrips(oicId: widget.oicId),
      OicSettings(
        oicId: widget.oicId,
        oicName: widget.oicName,
        companyName: widget.companyName,
      ),
    ];

    return SherviceFloatingStack(
      userRole: 'OIC',
      userName: widget.oicName,
      localIp: localIp,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.white),
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
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.directions_car, color: Colors.blue, size: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/shervice - white.jpg',
                height: 14,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'SHERVICE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
          actions: [
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
            child: Stack(
              children: [
                screens[_selectedIndex],
                Positioned(
                  top: 16,
                  right: 16,
                  child: SlideInWelcomeWidget(role: widget.oicName),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
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
                            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _titles[index],
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
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(1.5, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
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
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'Welcome, ${widget.role}!',
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}