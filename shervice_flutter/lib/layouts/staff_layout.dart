import 'package:flutter/material.dart';
import 'staff_layout_desktop.dart';
import 'staff_layout_mobile.dart';

class StaffLayout extends StatelessWidget {
  const StaffLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) return const StaffLayoutDesktop();
      return const StaffLayoutMobile();
    });
  }
}