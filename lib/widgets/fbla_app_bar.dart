import 'package:flutter/material.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';

class FblaAppBar {
  FblaAppBar._();

  static AppBar standard(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barFg = isDark ? Colors.white : FblaColors.navy;
    final barBg = isDark ? const Color(0xFF1C1C1E) : FblaColors.paper;
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: barFg,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: barBg,
      foregroundColor: barFg,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black12,
      scrolledUnderElevation: 2,
      leading: leading,
      actions: actions,
    );
  }
}
