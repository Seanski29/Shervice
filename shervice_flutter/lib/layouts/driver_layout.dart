import 'package:flutter/material.dart';
import 'driver_layout_desktop.dart';
import 'driver_layout_mobile.dart';

class DriverLayout extends StatelessWidget {
  const DriverLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen width is less than 600 pixels, show the Mobile layout
        if (constraints.maxWidth < 600) {
          return const DriverLayoutMobile();
        } 
        // Otherwise, show the Desktop layout
        else {
          return const DriverLayoutDesktop();
        }
      },
    );
  }
}