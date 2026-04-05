import 'package:flutter/material.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/fbla_app_bar.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FblaAppBar.standard(context, title: 'How to use this app'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroBanner(theme: theme),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.dashboard_rounded,
              iconColor: FblaColors.navy,
              title: 'Home',
              body:
                  'Your dashboard shows a quick welcome, stats (events, competitions, '
                  'points, and chapter rank), a short list of upcoming events, and the '
                  'latest announcement. Tap an event to open the calendar on that date. '
                  'Tap the announcement to read the full post.',
            ),
            _Section(
              icon: Icons.calendar_month_rounded,
              iconColor: FblaColors.goldDeep,
              title: 'Calendar',
              body:
                  'Browse chapter and FBLA-related dates. Use this to plan ahead for '
                  'meetings, deadlines, and conferences. Tap a day to see what is scheduled.',
            ),
            _Section(
              icon: Icons.campaign_rounded,
              iconColor: FblaColors.crimson,
              title: 'News',
              body:
                  'Read announcements pulled in for members. Open an item for details '
                  'and any link out to the full article on the web.',
            ),
            _Section(
              icon: Icons.emoji_events_rounded,
              iconColor: FblaColors.navy,
              title: 'Compete',
              body:
                  'Explore competitive events and materials. Register for what your '
                  'chapter offers and keep track of what you have signed up for.',
            ),
            _Section(
              icon: Icons.share_rounded,
              iconColor: FblaColors.goldDeep,
              title: 'Social',
              body:
                  'Connect to national, state, and chapter social accounts, and share '
                  'your achievements. Handles depend on what your chapter has configured.',
            ),
            _Section(
              icon: Icons.person_rounded,
              iconColor: FblaColors.navy,
              title: 'Profile',
              body:
                  'See your membership details, points, and rank. Update your state and '
                  'section, share progress, open Help, adjust Settings (including '
                  'accessibility), or sign out.',
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use the bottom navigation to switch sections at any time. '
                        'Your place in each tab is remembered while the app stays open.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  final ThemeData theme;

  const _IntroBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FblaColors.navy,
            FblaColors.navyDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FblaColors.navy.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick guide',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This app is organized around the bar at the bottom. Each area has a '
            'specific job—use this page when you are learning where everything lives.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
