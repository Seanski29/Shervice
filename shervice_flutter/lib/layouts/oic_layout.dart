import 'package:flutter/material.dart';
import 'oic_layout_desktop.dart';
import 'oic_layout_mobile.dart';

class OicLayout extends StatelessWidget {
  final String oicName;
  final String companyName;

  const OicLayout({
    super.key,
    required this.oicName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return OicLayoutDesktop(oicName: oicName, companyName: companyName);
        }
        return OicLayoutMobile(oicName: oicName, companyName: companyName);
      },
    );
  }
}
