import 'package:flutter/material.dart';
import 'staff_layout_desktop.dart';
import 'staff_layout_mobile.dart';

class StaffLayout extends StatelessWidget {
  final String staffName;
  final String companyName;

  const StaffLayout({
    super.key,
    required this.staffName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return StaffLayoutDesktop(
            staffName: staffName,
            companyName: companyName,
          );
        }
        return StaffLayoutMobile(
          staffName: staffName,
          companyName: companyName,
        );
      },
    );
  }
}
