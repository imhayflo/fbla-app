import 'package:flutter/material.dart';

/// Plain content layer matching the clean prototype screens.
class FblaScreenShell extends StatelessWidget {
  final Widget child;

  const FblaScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF9FBFF),
            Color(0xFFEEF4FC),
            Color(0xFFFAF9F6),
          ],
          stops: [0, 0.34, 1],
        ),
      ),
      child: child,
    );
  }
}
