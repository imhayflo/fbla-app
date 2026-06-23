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
              : const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: _AppBarTorchMark(),
                )),
      title: Text(
        title,
        style: TextStyle(
          color: barFg,
          fontSize: 15,
          fontWeight: FontWeight.w700,
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

class _AppBarTorchMark extends StatelessWidget {
  const _AppBarTorchMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.emoji_events, color: FblaColors.goldDeep, size: 26),
          Positioned(
            top: 0,
            child: Icon(Icons.local_fire_department,
                color: FblaColors.gold, size: 18),
          ),
        ],
      ),
    );
  }
}
