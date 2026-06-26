import 'package:flutter/material.dart';
import 'oic_layout_desktop.dart';
import 'oic_layout_mobile.dart';

class OicLayout extends StatelessWidget {
  const OicLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) return const OicLayoutDesktop();
      return const OicLayoutMobile();
    });
  }
}