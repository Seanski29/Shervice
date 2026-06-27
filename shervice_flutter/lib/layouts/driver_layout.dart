import 'package:flutter/material.dart';
import 'driver_layout_desktop.dart';
import 'driver_layout_mobile.dart';

class DriverLayout extends StatelessWidget {
  final String driverId; // 👈 1. Add this
  final String driverName;
  final String companyName;

  const DriverLayout({
    super.key,
    required this.driverId, // 👈 2. Require this
    required this.driverName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return DriverLayoutDesktop(
            driverId: driverId, // 👈 3. Pass it down
            driverName: driverName,
            companyName: companyName,
          );
        }
        return DriverLayoutMobile(
          driverId: driverId, // 👈 3. Pass it down
          driverName: driverName,
          companyName: companyName,
        );
      },
    );
  }
}
