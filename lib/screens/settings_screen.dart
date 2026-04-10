import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'accessibility_settings_screen.dart';
import '../widgets/fbla_app_bar.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _eventReminders = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: FblaAppBar.standard(context, title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Display',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Switch between light and dark themes'),
              value: isDark,
              onChanged: (value) {
                themeModeNotifier.toggle();
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Accessibility',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.accessibility_new, color: theme.colorScheme.primary),
              title: const Text('Display & reading'),
              subtitle: const Text(
                'Contrast, color distinction, text size, and bold labels',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AccessibilitySettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Push notifications'),
              subtitle: const Text('Updates about events and announcements'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Notifications enabled' : 'Notifications disabled',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Event reminders'),
              subtitle: const Text('Remind me before registered events'),
              value: _eventReminders,
              onChanged: (value) {
                setState(() => _eventReminders = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Event reminders on' : 'Event reminders off',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset password'),
              subtitle: const Text('Send a password reset link to your email'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final email = _authService.currentUser?.email;
                if (email == null || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No email on file')),
                  );
                  return;
                }
                try {
                  await _authService.resetPassword(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent. Check your inbox.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App version'),
              subtitle: const Text('1.0.0'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: '1.0.0'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version copied')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
