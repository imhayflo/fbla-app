import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('FBLA website'),
              subtitle: const Text('fbla.org'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl('https://www.fbla.org/'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Contact FBLA'),
              subtitle: const Text('National center contact & resources'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl('https://www.fbla.org/about/contact/'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: const Text('FBLA CONNECT'),
              subtitle: const Text('Chapter & membership portal'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl('https://connect.fbla.org/'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frequently asked questions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _FaqTile(
            question: 'What is FBLA?',
            answer: 'Future Business Leaders of America (FBLA) is the largest business career and technical student organization in the world. It helps middle school, high school, and college students prepare for careers in business.',
          ),
          _FaqTile(
            question: 'How do I update my profile?',
            answer: 'Tap Profile in the bottom bar, then tap "Update Profile" under Actions. You can change your name, school, chapter, state, section, phone, and chapter Instagram.',
          ),
          _FaqTile(
            question: 'How do I share my achievements?',
            answer: 'Go to the Social tab and use "Share your achievements," or open Profile and tap the "Share" button on any achievement card. You can post to Instagram, Facebook, or any app via the share sheet.',
          ),
          _FaqTile(
            question: 'How do I register for events?',
            answer: 'Open the Events tab, find an event, and tap it to view details. Use the register button to sign up. Your registered events appear in your dashboard.',
          ),
          _FaqTile(
            question: 'Where do competitions come from?',
            answer: 'Competition listings are synced from the official FBLA website. Use the Compete tab to browse categories and view guidelines.',
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'App version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
