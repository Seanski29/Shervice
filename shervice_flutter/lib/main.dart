import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'session_manager.dart';
import 'utils/tab_sync_stub.dart'
    if (dart.library.html) 'utils/tab_sync_web.dart';

// Import layouts and login
import 'layouts/admin/admin_layout.dart';
import 'layouts/driver/driver_layout.dart';
import 'layouts/oic/oic_layout.dart';
import 'layouts/staff/staff_layout.dart';
import 'login/login.dart';

// Global navigator key for cross-app navigation
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: '2455846521593896',
      cookie: true,
      xfbml: true,
      version: 'v17.0', 
    );
  }

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