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
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title),
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              FblaColors.paper,
              theme.colorScheme.primaryContainer.withOpacity(0.42),
            ],
          ),
        ),
      ),
    );
  }
}
