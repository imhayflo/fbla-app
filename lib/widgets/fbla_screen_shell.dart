import 'package:flutter/material.dart';
import 'package:fbla_member_app/widgets/fbla_atmospheric_background.dart';

/// Decorative background with a solid content layer so text and controls stay readable.
class FblaScreenShell extends StatelessWidget {
  final Widget child;

  const FblaScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        const FblaAtmosphericBackground(),
        ColoredBox(
          color: surface,
          child: child,
        ),
      ],
    );
  }
}