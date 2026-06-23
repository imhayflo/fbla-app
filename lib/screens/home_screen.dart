// ignore_for_file: deprecated_member_use, unused_element, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fbla_member_app/screens/events_screen.dart';
import 'package:fbla_member_app/screens/announcements_screen.dart';
import 'package:fbla_member_app/screens/profile_screen.dart';
import 'package:fbla_member_app/screens/competitions_screen.dart';
import 'package:fbla_member_app/screens/social_screen.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/app_chrome.dart';
import '../services/database_service.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/announcement.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _initialEventDate;
  String? _initialAnnouncementId;

  // Pre-build all tab screens to reduce first-tap delay
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Pre-create all screens so their StreamBuilders connect early
    _screens = [
      DashboardTab(navigateToTab: _onItemTapped),
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
    return Scaffold(
      backgroundColor: FblaColors.paper,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _selectedIndex == 0
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                boxShadow: [
                  BoxShadow(
                    color: FblaColors.navy.withOpacity(0.10),
                    blurRadius: 22,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today_rounded),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign_rounded),
                    label: 'News',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    selectedIcon: Icon(Icons.emoji_events_rounded),
                    label: 'Compete',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt_rounded),
                    label: 'Social',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  final void Function(int index, {DateTime? eventDate, String? announcementId})
      navigateToTab;

  const DashboardTab({super.key, required this.navigateToTab});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _scrollController = ScrollController();
  final _contentKey = GlobalKey();
  final _dbService = DatabaseService();
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToContent() {
    final context = _contentKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openMenu() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black.withOpacity(0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _DashboardMenuOverlay(onNavigate: (index) {
          Navigator.pop(context);
          widget.navigateToTab(index);
        });
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FblaColors.paper,
      appBar: AppBar(
        toolbarHeight: 86,
        backgroundColor: FblaColors.porcelain,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FblaColors.navy,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: FblaColors.navy.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: FblaColors.gold,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FBLA Link',
                  style: TextStyle(
                    color: FblaColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Member dashboard',
                  style: TextStyle(
                    color: FblaColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open menu',
            onPressed: _openMenu,
            icon: const Icon(Icons.menu, size: 30, color: Color(0xFF2D2B2B)),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: StreamBuilder<Member?>(
        stream: _dbService.memberStream,
        builder: (context, snapshot) {
          final member = snapshot.data;
          final name = member?.name.split(' ').first ?? 'User';
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHero(name: name, onLetsGo: _scrollToContent),
                Container(
                  key: _contentKey,
                  color: FblaColors.porcelain,
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 4),
                  child: const _MessagesPreview(),
                ),
                _BlueFeedSection(
                  title: 'Recent News',
                  icon: Icons.campaign_outlined,
                  child: _RecentNews(
                    dbService: _dbService,
                    onViewNews: () => widget.navigateToTab(2),
                  ),
                ),
                _BlueFeedSection(
                  title: 'Upcoming Events',
                  icon: Icons.event_available_outlined,
                  child: _UpcomingEvents(
                    dbService: _dbService,
                    dateFormat: _dateFormat,
                    onViewCalendar: () => widget.navigateToTab(1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _DashboardStats(member: member, dbService: _dbService),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAnnouncementDetails(
      BuildContext context, Announcement announcement) {
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
                color:
                    _getPriorityColor(announcement.priority).withOpacity(0.2),
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
                  Icon(Icons.calendar_today,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
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

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.name, required this.onLetsGo});

  final String name;
  final VoidCallback onLetsGo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 510),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FblaColors.navyDark,
            FblaColors.navy,
            FblaColors.blue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FblaColors.navy.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
              child: CustomPaint(painter: _HeroLinePainter())),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.17)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: FblaColors.gold, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'Ready for what is next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Image.asset('assets/fbla_logo.png', height: 76),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back,\n$name',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "See what you've missed.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: FblaColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroPill(icon: Icons.campaign_outlined, label: 'News'),
                  _HeroPill(
                      icon: Icons.event_available_outlined, label: 'Events'),
                  _HeroPill(icon: Icons.groups_outlined, label: 'Social'),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 210,
                height: 58,
                child: FilledButton.icon(
                  onPressed: onLetsGo,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: FblaColors.gold.withOpacity(0.35),
                    elevation: 8,
                    foregroundColor: FblaColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: const Text(
                    "Let's Go",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLinePainter extends CustomPainter {
  const _HeroLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (var i = 0; i < 4; i++) {
      final dy = size.height * (0.12 + i * 0.2);
      final path = Path()
        ..moveTo(-24, dy)
        ..cubicTo(
          size.width * 0.28,
          dy - 56,
          size.width * 0.65,
          dy + 58,
          size.width + 24,
          dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MessagesPreview extends StatelessWidget {
  const _MessagesPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  color: FblaColors.ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: FblaColors.line),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, color: FblaColors.navy, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '3 new',
                    style: TextStyle(
                      color: FblaColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Latest chapter conversations and member check-ins.',
          style: TextStyle(
            color: FblaColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        const _PrototypeMessageCard(
          text: 'Hey, what have you been using to study for Data Science & AI?',
          accent: FblaColors.sky,
        ),
        const _PrototypeMessageCard(
          text: 'Did you have the time to go and get your California pin?',
          accent: FblaColors.goldDeep,
        ),
        const _PrototypeMessageCard(
          text: 'I placed 3rd at States for my competition.',
          accent: FblaColors.crimson,
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _PrototypeMessageCard extends StatelessWidget {
  const _PrototypeMessageCard({
    required this.text,
    required this.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _AestheticSurface(
      margin: const EdgeInsets.only(bottom: 18),
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: FblaColors.ink,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: accent.withOpacity(0.14),
                child: Icon(Icons.person, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chapter member',
                  style: TextStyle(
                    color: FblaColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, color: accent, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlueFeedSection extends StatelessWidget {
  const _BlueFeedSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FblaColors.blue, FblaColors.cobalt],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: Icon(icon, color: FblaColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _RecentNews extends StatelessWidget {
  const _RecentNews({required this.dbService, required this.onViewNews});

  final DatabaseService dbService;
  final VoidCallback onViewNews;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: dbService.announcementsStream,
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        final title = announcements.isEmpty
            ? 'News synced with FBLA website'
            : announcements.first.title;
        final author =
            announcements.isEmpty ? 'Author' : announcements.first.author;
        return _PrototypeFeedCard(
          title: title,
          name: author.isEmpty ? 'Author' : author,
          onTap: onViewNews,
        );
      },
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents({
    required this.dbService,
    required this.dateFormat,
    required this.onViewCalendar,
  });

  final DatabaseService dbService;
  final DateFormat dateFormat;
  final VoidCallback onViewCalendar;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: dbService.eventsStream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final upcoming = (snapshot.data ?? [])
            .where((event) => event.date.isAfter(now))
            .take(1)
            .toList();
        final title = upcoming.isEmpty
            ? 'An Upcoming Event synced with the FBLA website'
            : upcoming.first.title;
        final name = upcoming.isEmpty
            ? 'Author'
            : dateFormat.format(upcoming.first.date);
        return _PrototypeFeedCard(
            title: title, name: name, onTap: onViewCalendar);
      },
    );
  }
}

class _PrototypeFeedCard extends StatelessWidget {
  const _PrototypeFeedCard({
    required this.title,
    required this.name,
    required this.onTap,
  });

  final String title;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _AestheticSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D2B2B),
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFDCEAF7),
                  child: Icon(Icons.person, color: FblaColors.navy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: FblaColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AestheticSurface extends StatelessWidget {
  const _AestheticSurface({
    required this.child,
    this.margin,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FblaColors.line.withOpacity(0.86)),
        boxShadow: [
          BoxShadow(
            color: FblaColors.navy.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accent != null) ...[
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.member, required this.dbService});

  final Member? member;
  final DatabaseService dbService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppInstructionCard(
          id: 'home',
          title: 'Welcome to your dashboard',
          tips: [
            'Scroll through messages, news, and events like the prototype.',
            'Use the top-right menu to jump to other FBLA Link features.',
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Events',
                value: '${member?.eventsAttended ?? 0}',
                icon: Icons.event_available_outlined,
                color: FblaColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: dbService.userRegisteredCompetitionsStream,
                builder: (context, snapshot) {
                  return _StatCard(
                    title: 'Competitions',
                    value: '${snapshot.data?.length ?? 0}',
                    icon: Icons.emoji_events_outlined,
                    color: FblaColors.goldDeep,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardMenuOverlay extends StatelessWidget {
  const _DashboardMenuOverlay({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Competitions',
        'Events, results, and registration',
        Icons.emoji_events_outlined,
        3,
        false
      ),
      ('News', 'Official FBLA updates', Icons.campaign_outlined, 2, false),
      ('Calendar', 'Meetings and deadlines', Icons.event_outlined, 1, false),
      (
        'Your Profile',
        'Points, rank, and details',
        Icons.person_outline,
        5,
        false
      ),
      ('Messages', 'Chapter conversations', Icons.forum_outlined, 4, false),
      (
        'Pin Trading Hub',
        'Connect with members',
        Icons.push_pin_outlined,
        4,
        false
      ),
      ('Guide', 'Tips and walkthroughs', Icons.explore_outlined, 0, false),
      (
        'Resources',
        'Helpful links and forms',
        Icons.folder_open_outlined,
        0,
        false
      ),
      ('Settings', 'Preferences and account', Icons.settings_outlined, 5, true),
    ];

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.80,
            margin: const EdgeInsets.fromLTRB(0, 18, 0, 18),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, FblaColors.porcelain],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              border: Border.all(color: FblaColors.line),
              boxShadow: [
                BoxShadow(
                  color: FblaColors.navy.withOpacity(0.20),
                  blurRadius: 34,
                  offset: const Offset(-8, 16),
                ),
              ],
            ),
            child: ListView(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: FblaColors.navy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: FblaColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FBLA Link',
                            style: TextStyle(
                              color: FblaColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                          Text(
                            'Navigate your chapter hub',
                            style: TextStyle(
                              color: FblaColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map(
                  (item) => _MenuItem(
                    label: item.$1,
                    description: item.$2,
                    icon: item.$3,
                    dark: item.$5,
                    onTap: () => onNavigate(item.$4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : FblaColors.ink;
    final secondary = dark ? Colors.white70 : FblaColors.muted;
    return Material(
      color: dark ? FblaColors.navyDark : Colors.white.withOpacity(0.74),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? FblaColors.navyDark : FblaColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(color: secondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foreground, size: 18),
            ],
          ),
        ),
      ),
    );
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
    final text =
        '${event.title} ${event.type} ${event.description}'.toLowerCase();
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
                        _isActive
                            ? 'Conference Mode Active'
                            : 'Conference Mode Ready',
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
      _TimelineItem(start.subtract(const Duration(days: 1)),
          'Pack, print materials, and confirm travel.'),
      _TimelineItem(
          start, 'Check in, review schedule, and attend opening sessions.'),
      _TimelineItem(start.add(const Duration(days: 1)),
          'Compete, attend workshops, and trade pins.'),
      _TimelineItem(
          (widget.event.endDate ?? start).add(const Duration(days: 1)),
          'Write thank-you notes and save feedback.'),
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
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
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
