import 'package:flutter/material.dart';

/// Plain content layer matching the clean prototype screens.
class FblaScreenShell extends StatelessWidget {
  final Widget child;

  const FblaScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF08111F),
                  Color(0xFF0F172A),
                  Color(0xFF111827),
                ]
              : const [
                  Color(0xFFF9FBFF),
                  Color(0xFFEEF4FC),
                  Color(0xFFFAF9F6),
                ],
          stops: const [0, 0.34, 1],
        ),
      ),
      child: child,
    );
  }
}
