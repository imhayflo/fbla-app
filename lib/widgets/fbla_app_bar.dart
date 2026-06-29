// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fbla_member_app/screens/home_screen.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/app_chrome.dart';

class FblaAppBar {
  FblaAppBar._();

  static AppBar standard(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showPrototypeMenu = true,
  }) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final menuAction = IconButton(
      tooltip: 'Open menu',
      onPressed: () {
        showFblaPrototypeMenu(
          context,
          onNavigate: (index) {
            Navigator.pop(context);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(initialIndex: index),
              ),
            );
          },
        );
      },
      icon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : FblaColors.mist,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.26 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(Icons.menu, size: 24, color: scheme.onSurface),
      ),
    );

    return AppBar(
      toolbarHeight: 86,
      leading: leading ??
          (canPop
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(initialIndex: 0),
                        ),
                      );
                    },
                    child: const FblaPrototypeHeaderMark(),
                  ),
                )),
      leadingWidth: canPop ? null : 96,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: FblaColors.gold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant),
      ),
      actions: [
        ...?actions,
        if (showPrototypeMenu) menuAction,
        const SizedBox(width: 18),
      ],
    );
  }
}
