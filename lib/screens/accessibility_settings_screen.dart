import 'package:flutter/material.dart';
import 'package:fbla_member_app/widgets/accessibility_scope.dart';
import 'package:fbla_member_app/widgets/fbla_app_bar.dart';
import 'package:fbla_member_app/widgets/fbla_screen_shell.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a11y = AccessibilityScope.of(context);

    return AnimatedBuilder(
      animation: a11y,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: FblaAppBar.standard(context, title: 'Accessibility'),
          body: FblaScreenShell(
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Visual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('High contrast'),
                      subtitle: const Text(
                        'Stronger text and borders for easier reading.',
                      ),
                      value: a11y.highContrast,
                      onChanged: (v) => a11y.setHighContrast(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Color distinction assist'),
                      subtitle: const Text(
                        'Uses blues, ambers, and purples so status colors '
                        'are easier to tell apart if you have color vision differences.',
                      ),
                      value: a11y.colorblindFriendly,
                      onChanged: (v) => a11y.setColorblindFriendly(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Bold section labels'),
                      subtitle: const Text(
                        'Makes headings and key labels heavier where supported.',
                      ),
                      value: a11y.boldLabels,
                      onChanged: (v) => a11y.setBoldLabels(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Text size',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('Default'),
                      value: 0,
                      groupValue: a11y.textScaleIndex,
                      onChanged: (v) {
                        if (v != null) a11y.setTextScaleIndex(v);
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Larger'),
                      value: 1,
                      groupValue: a11y.textScaleIndex,
                      onChanged: (v) {
                        if (v != null) a11y.setTextScaleIndex(v);
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Largest'),
                      value: 2,
                      groupValue: a11y.textScaleIndex,
                      onChanged: (v) {
                        if (v != null) a11y.setTextScaleIndex(v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'System settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'You can also use your device\'s display settings '
                    '(Display & brightness, Larger text, Bold text, '
                    'Reduce transparency) together with the options above.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}
