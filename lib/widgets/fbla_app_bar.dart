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
      icon: const Icon(Icons.menu, size: 30, color: FblaColors.text),
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
      title: Text(
        title,
        style: const TextStyle(
          color: FblaColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: FblaColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: [
        ...?actions,
        if (showPrototypeMenu) menuAction,
        const SizedBox(width: 18),
      ],
    );
  }
}
