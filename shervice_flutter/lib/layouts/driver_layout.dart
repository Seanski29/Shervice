import 'package:flutter/material.dart';
import 'driver_layout_desktop.dart';
import 'driver_layout_mobile.dart';

class DriverLayout extends StatelessWidget {
  final String driverName; // 1. Added the property definition

  // 2. Updated constructor to require the driverName parameter
  const DriverLayout({super.key, required this.driverName});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen width is less than 600 pixels, show the Mobile layout
        if (constraints.maxWidth < 600) {
          return DriverLayoutMobile(
            driverName: driverName,
          ); // 3. Passed name down
        }
        // Otherwise, show the Desktop layout
        else {
          return DriverLayoutDesktop(
            driverName: driverName,
          ); // 3. Passed name down
        }
      },
    );
  }
}
