import 'package:flutter/material.dart';

/// Plain content layer matching the clean prototype screens.
class FblaScreenShell extends StatelessWidget {
  final Widget child;

  const FblaScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: child,
    );
  }
}
