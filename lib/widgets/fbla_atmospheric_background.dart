import 'package:flutter/material.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';

class FblaAtmosphericBackground extends StatelessWidget {
  const FblaAtmosphericBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: FblaColors.navy,
      child: SizedBox.expand(),
    );
  }
}
