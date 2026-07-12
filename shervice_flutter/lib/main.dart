import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/tab_sync_stub.dart'
    if (dart.library.html) 'utils/tab_sync_web.dart';

// Import your Session Manager
import 'session_manager.dart';

import 'layouts/admin/admin_layout.dart';
import 'layouts/driver/driver_layout.dart';
import 'layouts/oic/oic_layout.dart';
import 'layouts/staff/staff_layout.dart';
import 'login/login.dart';

// 1. CREATE A GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  bool loggedIn = await SessionManager.isLoggedIn();
  Map<String, String?> userData = {};

  if (loggedIn) {
    userData = await SessionManager.getUserData();
  }

  runApp(SherviceApp(isLoggedIn: loggedIn, userData: userData));
}

class SherviceApp extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, String?> userData;

  const SherviceApp({
    super.key,
    required this.isLoggedIn,
    required this.userData,
  });

  @override
  State<SherviceApp> createState() => _SherviceAppState();
}

class _SherviceAppState extends State<SherviceApp> {
  @override
  void initState() {
    super.initState();

    // Calls the web file if on a browser, or the dummy file if on mobile!
    setupTabSync(() {
      globalNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final String? testRole = uri.queryParameters['role'];

    Widget getInitialScreen() {
      if (widget.isLoggedIn) {
        final role = widget.userData['role'];
        final userId = widget.userData['userId'] ?? '';
        final userName = widget.userData['userName'] ?? 'User';
        final company = widget.userData['companyName'] ?? 'GT LANTIN';

        if (role == 'admin') {
          return AdminLayout(adminId: userId);
        } else if (role == 'oic') {
          return OicLayout(
            oicId: userId,
            oicName: userName,
            companyName: company,
          );
        } else if (role == 'staff') {
          return StaffLayout(
            staffId: userId,
            staffName: userName,
            companyName: company,
          );
        } else if (role == 'driver') {
          return DriverLayout(
            driverId: userId,
            driverName: userName,
            companyName: company,
          );
        }
      }

      // Fallback for URL testing (if needed)
      if (testRole == 'admin') {
        return const AdminLayout(
          adminId: '00000000-0000-0000-0000-000000000000',
        );
      } else if (testRole == 'driver') {
        return const DriverLayout(
          driverId: '00000000-0000-0000-0000-000000000000',
          driverName: 'System Driver',
          companyName: 'Test Company',
        );
      }

      return const LoginScreen();
    }

    return MaterialApp(
      // 4. ATTACH THE GLOBAL KEY HERE
      navigatorKey: globalNavigatorKey,

      title: 'Shervice Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: getInitialScreen(),
    );
  }
}
