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
          color: FblaColors.mist,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: FblaColors.navy.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.menu, size: 24, color: FblaColors.text),
      ),
    );

    return AppBar(
      toolbarHeight: 86,
      leading: leading ??
          (canPop
              ? null
              : const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: FblaPrototypeHeaderMark(),
                )),
      leadingWidth: canPop ? null : 96,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FblaColors.text,
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
      backgroundColor: Colors.white,
      foregroundColor: FblaColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE8EDF4)),
      ),
      actions: [
        ...?actions,
        if (showPrototypeMenu) menuAction,
        const SizedBox(width: 18),
      ],
    );
  }
}
