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
    final barBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      leading: leading ??
          (canPop
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 14, top: 9, bottom: 9),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FblaColors.gold.withOpacity(0.7),
                      ),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Image.asset('assets/fbla_logo.png',
                        fit: BoxFit.contain),
                  ),
                )),
      title: Text(
        title,
        style: TextStyle(
          color: barFg,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: barBg,
      foregroundColor: barFg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: actions,
    );
  }
}
