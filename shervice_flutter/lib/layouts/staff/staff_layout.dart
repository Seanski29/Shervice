import 'package:flutter/material.dart';
import 'staff_layout_desktop.dart';

class StaffLayout extends StatelessWidget {
  final String staffId; // 👈 1. Receive the ID
  final String staffName;
  final String companyName;

  const StaffLayout({
    super.key,
    required this.staffId, // 👈 2. Require it
    required this.staffName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return StaffLayoutDesktop(
            staffId: staffId,
            staffName: staffName,
            companyName: companyName,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
