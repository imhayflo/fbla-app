import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  static const List<Announcement> _announcements = [
    Announcement(
      title: 'State Leadership Conference Registration Open',
      content: 'Registration for the State Leadership Conference is now open. All members are encouraged to register early to secure their spot. The conference will feature workshops, competitions, and networking opportunities.',
      date: '2024-02-15',
      author: 'FBLA Chapter Advisor',
      category: 'Event',
      priority: 'high',
    ),
    Announcement(
      title: 'Monthly Chapter Meeting Reminder',
      content: 'Don\'t forget about our monthly chapter meeting on February 20th at 3:00 PM in Room 205. We will be discussing upcoming events and competition preparation.',
      date: '2024-02-18',
      author: 'Chapter President',
      category: 'Meeting',
      priority: 'medium',
    ),
    Announcement(
      title: 'Business Skills Workshop Sign-up',
      content: 'Sign up for our upcoming Business Skills Workshop on February 28th. Learn essential skills including public speaking, resume writing, and interview techniques. Limited spots available!',
      date: '2024-02-10',
      author: 'VP of Membership',
      category: 'Workshop',
      priority: 'medium',
    ),
    Announcement(
      title: 'Community Service Project Opportunity',
      content: 'Join us for a community service project at the local food bank on March 5th. This is a great opportunity to give back to the community and earn service hours.',
      date: '2024-02-12',
      author: 'Community Service Coordinator',
      category: 'Service',
      priority: 'low',
    ),
    Announcement(
      title: 'Competition Results Available',
      content: 'Results from the Regional Business Competition are now available. Congratulations to all participants! Check your email for detailed results and feedback.',
      date: '2024-02-05',
      author: 'Competition Coordinator',
      category: 'Results',
      priority: 'low',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _AnnouncementCard(
            announcement: announcement,
            onTap: () => _showAnnouncementDetails(context, announcement),
          );
        },
      ),
    );
  }

  void _showAnnouncementDetails(BuildContext context, Announcement announcement) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final parsedDate = DateTime.parse(announcement.date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(announcement.priority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                announcement.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getPriorityColor(announcement.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(announcement.title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                announcement.content,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    announcement.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(parsedDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final parsedDate = DateTime.parse(announcement.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      announcement.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(announcement.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(parsedDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    announcement.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class Announcement {
  final String title;
  final String content;
  final String date;
  final String author;
  final String category;
  final String priority;

  const Announcement({
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.category,
    required this.priority,
  });
}
