import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fbla_member_app/screens/events_screen.dart';
import 'package:fbla_member_app/screens/announcements_screen.dart';
import 'package:fbla_member_app/screens/profile_screen.dart';
import 'package:fbla_member_app/screens/competitions_screen.dart';
import 'package:fbla_member_app/screens/social_screen.dart';
import 'package:fbla_member_app/screens/instructions_screen.dart';
import 'package:fbla_member_app/theme/app_theme.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/fbla_atmospheric_background.dart';
import '../services/database_service.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/announcement.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Start on Guide page instead of Home
  DateTime? _initialEventDate;
  String? _initialAnnouncementId;

  // Pre-build all tab screens to reduce first-tap delay
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Pre-create all screens so their StreamBuilders connect early
    _screens = [
      DashboardTab(navigateToTab: _onItemTapped),
      const InstructionsScreen(),
      EventsScreen(initialDate: _initialEventDate),
      AnnouncementsScreen(initialAnnouncementId: _initialAnnouncementId),
      const CompetitionsScreen(),
      const SocialScreen(),
      const ProfileScreen(),
    ];
    
    // Pre-warm Firestore connections in background
    _prewarmFirestore();
  }

  Future<void> _prewarmFirestore() async {
    final dbService = DatabaseService();
    // Pre-warm streams while user is on dashboard
    dbService.preLoadData();
    dbService.warmupStreams();
  }

  void _onItemTapped(int index, {DateTime? eventDate, String? announcementId}) {
    setState(() {
      _selectedIndex = index;
      _initialEventDate = eventDate;
      _initialAnnouncementId = announcementId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navBg = theme.colorScheme.surface;
    final navBorder = theme.colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FblaAtmosphericBackground(),
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: navBorder),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: navBg,
                indicatorColor: theme.colorScheme.primary.withOpacity(0.16),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(index),
                destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Guide',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.announcement_outlined),
            selectedIcon: Icon(Icons.announcement),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Compete',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final void Function(int index, {DateTime? eventDate, String? announcementId}) navigateToTab;

  const DashboardTab({super.key, required this.navigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = theme.fblaStats;
    final dbService = DatabaseService();
    final dateFormat = DateFormat('MMM d, yyyy');
    final isDark = theme.brightness == Brightness.dark;
    final dashBg = isDark ? colorScheme.surface : FblaColors.paper;
    final dashFg = isDark ? colorScheme.onSurface : FblaColors.navy;
    final sectionHeaderStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );

    return Scaffold(
      backgroundColor: dashBg,
      appBar: AppBar(
        backgroundColor: dashBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: dashFg,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/fbla_logo.png', fit: BoxFit.contain),
            ),
          ),
        ),
        title: Text(
          'FBLA Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            color: dashFg,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<Member?>(
              stream: dbService.memberStream,
              builder: (context, snapshot) {
                final member = snapshot.data;
                final name = member?.name.split(' ').first ?? 'Member';

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FblaColors.navy,
                        Color(0xFF0A4A7A),
                        FblaColors.navyDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $name!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stay connected with your chapter',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            StreamBuilder<List<Event>>(
              stream: dbService.eventsStream,
              builder: (context, snapshot) {
                final conference = _findConferenceEvent(snapshot.data ?? []);
                if (conference == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ConferenceModeCard(event: conference),
                );
              },
            ),

            Text('Your Activity', style: sectionHeaderStyle),
            const SizedBox(height: 16),
            StreamBuilder<Member?>(
              stream: dbService.memberStream,
              builder: (context, snapshot) {
                final member = snapshot.data;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Events',
                            value: '${member?.eventsAttended ?? 0}',
                            icon: Icons.event,
                            color: stats.events,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<List<String>>(
                            stream: dbService.userRegisteredCompetitionsStream,
                            builder: (context, regCompsSnapshot) {
                              final regCompCount = regCompsSnapshot.data?.length ?? 0;
                              return _StatCard(
                                title: 'Competitions',
                                value: '$regCompCount',
                                icon: Icons.emoji_events,
                                color: stats.competitions,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Points',
                            value: '${member?.points ?? 0}',
                            icon: Icons.star,
                            color: stats.points,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<List<Member>>(
                            stream: dbService.getAllMembersSortedByPoints(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return _StatCard(
                                  title: 'Rank',
                                  value: '-',
                                  icon: Icons.leaderboard,
                                  color: stats.rank,
                                );
                              }
                              final members = snapshot.data!;
                              // Find current user's rank
                              final currentUid = member?.uid;
                              int userRank = 0;
                              for (int i = 0; i < members.length; i++) {
                                if (members[i].uid == currentUid) {
                                  userRank = i + 1;
                                  break;
                                }
                              }
                              return _StatCard(
                                title: 'Rank',
                                value: userRank > 0 ? '#$userRank' : '-',
                                icon: Icons.leaderboard,
                                color: stats.rank,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Upcoming Events
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Events', style: sectionHeaderStyle),
                TextButton(
                  onPressed: () {
                    // Navigate to events tab
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(2);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: dbService.eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  );
                }

                final events = snapshot.data ?? [];
                final upcomingEvents = events
                    .where((e) => e.date.isAfter(DateTime.now()))
                    .take(2)
                    .toList();

                if (upcomingEvents.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No upcoming events',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: upcomingEvents
                      .map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                navigateToTab(2, eventDate: event.date);
                              },
                              child: _EventCard(
                                title: event.title,
                                date: event.endDate != null
                                    ? '${dateFormat.format(event.date)} - ${dateFormat.format(event.endDate!)}'
                                    : dateFormat.format(event.date),
                                type: event.type,
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent News
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent News', style: sectionHeaderStyle),
                TextButton(
                  onPressed: () {
                    // Navigate to news (announcements) tab
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(3);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Announcement>>(
              stream: dbService.announcementsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  );
                }

                final announcements = snapshot.data ?? [];

                if (announcements.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No announcements',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final latestAnnouncement = announcements.first;
                return Card(
                  child: InkWell(
                    onTap: () {
                      _showAnnouncementDetails(context, latestAnnouncement);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.campaign,
                            color: colorScheme.onPrimaryContainer),
                      ),
                      title: Text(
                        latestAnnouncement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        latestAnnouncement.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDetails(BuildContext context, Announcement announcement) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              if (announcement.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    announcement.imageUrl!,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(announcement.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(announcement.content, style: theme.textTheme.bodyMedium),
              if (announcement.externalUrl != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(announcement.externalUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Read Full Article'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white;
    return Card(
      color: fill,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String date;
  final String type;

  const _EventCard({
    required this.title,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Event? _findConferenceEvent(List<Event> events) {
  final now = DateTime.now();
  final conferences = events.where((event) {
    final text = '${event.title} ${event.type} ${event.description}'.toLowerCase();
    final isConference = text.contains('conference') ||
        text.contains('nlc') ||
        text.contains('slc') ||
        text.contains('leadership');
    final end = event.endDate ?? event.date;
    return isConference && end.isAfter(now.subtract(const Duration(days: 1)));
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (conferences.isEmpty) return null;
  return conferences.first;
}

class _ConferenceModeCard extends StatelessWidget {
  const _ConferenceModeCard({required this.event});

  final Event event;

  bool get _isActive {
    final now = DateTime.now();
    final start = DateTime(event.date.year, event.date.month, event.date.day);
    final endDate = event.endDate ?? event.date;
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');
    final dateText = event.endDate == null
        ? dateFormat.format(event.date)
        : '${dateFormat.format(event.date)} - ${dateFormat.format(event.endDate!)}';

    return Card(
      color: _isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer.withOpacity(0.72),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  foregroundColor: _isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondary,
                  child: Icon(_isActive ? Icons.bolt : Icons.event_available),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? 'Conference Mode Active' : 'Conference Mode Ready',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${event.title} • $dateText',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showConferenceMode(context, event),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Open Conference Mode'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConferenceMode(BuildContext context, Event event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ConferenceModeSheet(event: event),
    );
  }
}

class _ConferenceModeSheet extends StatefulWidget {
  const _ConferenceModeSheet({required this.event});

  final Event event;

  @override
  State<_ConferenceModeSheet> createState() => _ConferenceModeSheetState();
}

class _ConferenceModeSheetState extends State<_ConferenceModeSheet> {
  final Set<String> _checked = {};

  List<_TimelineItem> get _timeline {
    final start = widget.event.date;
    return [
      _TimelineItem(start.subtract(const Duration(days: 1)), 'Pack, print materials, and confirm travel.'),
      _TimelineItem(start, 'Check in, review schedule, and attend opening sessions.'),
      _TimelineItem(start.add(const Duration(days: 1)), 'Compete, attend workshops, and trade pins.'),
      _TimelineItem((widget.event.endDate ?? start).add(const Duration(days: 1)), 'Write thank-you notes and save feedback.'),
    ];
  }

  _TimelineItem get _nextItem {
    final now = DateTime.now();
    return _timeline.firstWhere(
      (item) => item.time.isAfter(now),
      orElse: () => _timeline.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conference Mode',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.event.title, style: theme.textTheme.titleMedium),
          Text(
            widget.event.endDate == null
                ? dateFormat.format(widget.event.date)
                : '${dateFormat.format(widget.event.date)} - ${dateFormat.format(widget.event.endDate!)}',
          ),
          const SizedBox(height: 20),
          _ConferenceSection(
            icon: Icons.next_plan_outlined,
            title: 'What is next',
            child: Text(
              '${DateFormat('MMM d').format(_nextItem.time)}: ${_nextItem.label}',
            ),
          ),
          _ConferenceSection(
            icon: Icons.schedule,
            title: 'Live schedule',
            child: Column(
              children: _timeline
                  .map((item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.circle, size: 10),
                        title: Text(item.label),
                        subtitle: Text(DateFormat('MMM d').format(item.time)),
                      ))
                  .toList(),
            ),
          ),
          _ConferenceSection(
            icon: Icons.checkroom_outlined,
            title: 'Dress code checklist',
            child: Column(
              children: [
                _checkTile('Business suit or blazer/slacks/skirt'),
                _checkTile('Dress shoes'),
                _checkTile('Name badge and conference credentials'),
                _checkTile('Presentation materials or laptop charger'),
              ],
            ),
          ),
          _ConferenceSection(
            icon: Icons.groups_outlined,
            title: 'Networking goals',
            child: Column(
              children: [
                _checkTile('Meet 3 members from other chapters'),
                _checkTile('Ask one officer or adviser for advice'),
                _checkTile('Trade or discuss pins with another state'),
                _checkTile('Save one LinkedIn/contact follow-up'),
              ],
            ),
          ),
          _ConferenceSection(
            icon: Icons.map_outlined,
            title: 'Map and location',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.event.location.isEmpty
                    ? 'Location not listed yet'
                    : widget.event.location),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openMap(widget.event),
                  icon: const Icon(Icons.map),
                  label: const Text('Open map'),
                ),
              ],
            ),
          ),
          _ConferenceSection(
            icon: Icons.health_and_safety_outlined,
            title: 'Emergency info',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find your adviser or chapter chaperone first.'),
                SizedBox(height: 4),
                Text('For urgent safety issues, call venue security or 911.'),
                SizedBox(height: 4),
                Text('Keep your badge, phone, and room key with you.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile(String label) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _checked.contains(label),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _checked.add(label);
          } else {
            _checked.remove(label);
          }
        });
      },
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Future<void> _openMap(Event event) async {
    final query = Uri.encodeComponent(
      event.location.isEmpty ? event.title : event.location,
    );
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ConferenceSection extends StatelessWidget {
  const _ConferenceSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  final DateTime time;
  final String label;

  const _TimelineItem(this.time, this.label);
}
