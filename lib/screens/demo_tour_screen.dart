// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/app_chrome.dart';

class DemoTourScreen extends StatefulWidget {
  const DemoTourScreen({super.key});

  @override
  State<DemoTourScreen> createState() => _DemoTourScreenState();
}

class _DemoTourScreenState extends State<DemoTourScreen> {
  int _stepIndex = 0;

  static const _steps = [
    _DemoStep(
      surface: _DemoSurface.landing,
      target: Rect.fromLTWH(0.16, 0.62, 0.68, 0.20),
      eyebrow: 'Step 1 of 10',
      title: 'Land, log in, or sign up',
      body:
          'FBLA-Link opens on a branded landing page. Members can sign in or create an account before entering the member hub.',
      cta: 'Proceed to dashboard',
      icon: Icons.login_rounded,
    ),
    _DemoStep(
      surface: _DemoSurface.dashboard,
      target: Rect.fromLTWH(0.06, 0.09, 0.88, 0.10),
      eyebrow: 'Step 2 of 10',
      title: 'A tutorial starts every screen',
      body:
          'The top tutorial strip explains what the current screen is for, so members know exactly what to do next.',
      cta: 'Show dashboard summary',
      icon: Icons.tips_and_updates_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.dashboard,
      target: Rect.fromLTWH(0.08, 0.27, 0.84, 0.38),
      eyebrow: 'Step 3 of 10',
      title: 'Dashboard at a glance',
      body:
          'The dashboard summarizes member activity, upcoming events, recent announcements, messages, and points in one clean view.',
      cta: 'Open calendar',
      icon: Icons.dashboard_customize_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.calendar,
      target: Rect.fromLTWH(0.08, 0.24, 0.84, 0.35),
      eyebrow: 'Step 4 of 10',
      title: 'Calendar channel',
      body:
          'Members can browse competitions, workshops, meetings, conferences, and deadlines pulled into one calendar.',
      cta: 'Click an event',
      icon: Icons.calendar_month_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.eventDetail,
      target: Rect.fromLTWH(0.12, 0.39, 0.76, 0.31),
      eyebrow: 'Step 5 of 10',
      title: 'Event details pop open',
      body:
          'Selecting a date and event reveals descriptions, dates, locations, and registration context without making members hunt.',
      cta: 'Explore competitions',
      icon: Icons.event_available_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.competitions,
      target: Rect.fromLTWH(0.09, 0.32, 0.82, 0.32),
      eyebrow: 'Step 6 of 10',
      title: 'Competitive event library',
      body:
          'The competitions tab explains events like Accounting and links members directly to official guidelines and resources.',
      cta: 'Go to news',
      icon: Icons.emoji_events_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.news,
      target: Rect.fromLTWH(0.08, 0.27, 0.84, 0.40),
      eyebrow: 'Step 7 of 10',
      title: 'Discoverable news feed',
      body:
          'Official FBLA posts live in one centralized feed, making announcements consistent, easy to find, and easy to revisit.',
      cta: 'Open social',
      icon: Icons.campaign_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.social,
      target: Rect.fromLTWH(0.08, 0.28, 0.84, 0.42),
      eyebrow: 'Step 8 of 10',
      title: 'Social, sharing, and messages',
      body:
          'Members can share achievements, open official national and state profiles, and connect with peers through messaging.',
      cta: 'Show pin trading',
      icon: Icons.people_alt_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.pins,
      target: Rect.fromLTWH(0.08, 0.32, 0.84, 0.38),
      eyebrow: 'Step 9 of 10',
      title: 'Pin trading without money',
      body:
          'Members create requests for pins they want, then offer one of their own so trading stays community-focused.',
      cta: 'Finish with profile',
      icon: Icons.push_pin_outlined,
    ),
    _DemoStep(
      surface: _DemoSurface.profile,
      target: Rect.fromLTWH(0.08, 0.25, 0.84, 0.48),
      eyebrow: 'Step 10 of 10',
      title: 'Profile, points, and settings',
      body:
          'Profiles show member info, activity history, points earned through engagement, and settings like dark mode and accessibility.',
      cta: 'Restart demo',
      icon: Icons.person_pin_outlined,
    ),
  ];

  void _next() => setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);

  void _back() {
    setState(() => _stepIndex = (_stepIndex - 1 + _steps.length) % _steps.length);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final size = MediaQuery.sizeOf(context);
    final spotlight = Rect.fromLTWH(
      step.target.left * size.width,
      step.target.top * size.height,
      step.target.width * size.width,
      step.target.height * size.height,
    );
    final calloutTop = (spotlight.bottom + 18 < size.height * 0.72
            ? spotlight.bottom + 18
            : (spotlight.top - 214).clamp(96.0, size.height - 250))
        .toDouble();

    return Scaffold(
      backgroundColor: FblaColors.navyDark,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _DemoPreview(
                surface: step.surface,
                key: ValueKey(step.surface),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _SpotlightClipper(spotlight.inflate(8), 28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    color: FblaColors.navyDark.withOpacity(0.60),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SpotlightPainter(spotlight.inflate(8)),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: calloutTop,
              child: _DemoCallout(
                step: step,
                index: _stepIndex,
                total: _steps.length,
                onBack: _back,
                onNext: _next,
                onClose: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  const FblaPrototypeHeaderMark(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'FBLA-Link Live Demo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Close demo',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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

class _DemoStep {
  const _DemoStep({
    required this.surface,
    required this.target,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
  });

  final _DemoSurface surface;
  final Rect target;
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final IconData icon;
}

enum _DemoSurface {
  landing,
  dashboard,
  calendar,
  eventDetail,
  competitions,
  news,
  social,
  pins,
  profile,
}

class _DemoCallout extends StatelessWidget {
  const _DemoCallout({
    required this.step,
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onClose,
  });

  final _DemoStep step;
  final int index;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FblaColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: FblaColors.navy,
                  foregroundColor: Colors.white,
                  child: Icon(step.icon, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.eyebrow,
                    style: const TextStyle(
                      color: FblaColors.goldDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(onPressed: onClose, child: const Text('Exit')),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.title,
              style: const TextStyle(
                color: FblaColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.body,
              style: const TextStyle(
                color: FblaColors.text,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (index + 1) / total,
                minHeight: 7,
                backgroundColor: FblaColors.mist,
                valueColor: const AlwaysStoppedAnimation(FblaColors.gold),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Previous step',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: Icon(index == total - 1
                        ? Icons.replay_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(step.cta),
                    style: FilledButton.styleFrom(
                      backgroundColor: FblaColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

class _SpotlightClipper extends CustomClipper<Path> {
  const _SpotlightClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(_SpotlightClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.radius != radius;
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = FblaColors.gold.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final border = Paint()
      ..color = FblaColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(rrect, glow);
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => oldDelegate.rect != rect;
}

class _DemoPreview extends StatelessWidget {
  const _DemoPreview({super.key, required this.surface});

  final _DemoSurface surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(surface),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08276E), Color(0xFF123E98), FblaColors.porcelain],
        ),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.sizeOf(context).width.clamp(320, 430).toDouble(),
          height: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 70, 14, 12),
          decoration: BoxDecoration(
            color: FblaColors.porcelain,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: _SurfaceBody(surface: surface),
          ),
        ),
      ),
    );
  }
}

class _SurfaceBody extends StatelessWidget {
  const _SurfaceBody({required this.surface});

  final _DemoSurface surface;

  @override
  Widget build(BuildContext context) {
    switch (surface) {
      case _DemoSurface.landing:
        return const _LandingMock();
      case _DemoSurface.dashboard:
        return const _DashboardMock();
      case _DemoSurface.calendar:
        return const _CalendarMock(showDetail: false);
      case _DemoSurface.eventDetail:
        return const _CalendarMock(showDetail: true);
      case _DemoSurface.competitions:
        return const _CompetitionsMock();
      case _DemoSurface.news:
        return const _NewsMock();
      case _DemoSurface.social:
        return const _SocialMock();
      case _DemoSurface.pins:
        return const _PinsMock();
      case _DemoSurface.profile:
        return const _ProfileMock();
    }
  }
}

class _MockScaffold extends StatelessWidget {
  const _MockScaffold({
    required this.title,
    required this.icon,
    required this.tutorial,
    required this.children,
    this.selectedIndex = 0,
  });

  final String title;
  final IconData icon;
  final String tutorial;
  final List<Widget> children;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          color: Colors.white,
          child: Row(
            children: [
              const FblaPrototypeHeaderMark(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FblaColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
              ),
              Icon(icon, color: FblaColors.navy, size: 28),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _TutorialStrip(text: tutorial),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
        _MockNav(selectedIndex: selectedIndex),
      ],
    );
  }
}

class _TutorialStrip extends StatelessWidget {
  const _TutorialStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FblaColors.navy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.gold.withOpacity(0.75)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: FblaColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingMock extends StatelessWidget {
  const _LandingMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, FblaColors.mist, FblaColors.porcelain],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: FblaColors.navy.withOpacity(0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset('assets/fbla_logo.png', height: 108),
            ),
            const SizedBox(height: 18),
            const Text(
              'FBLA Link',
              style: TextStyle(
                color: FblaColors.navy,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Ready for what is next',
              style: TextStyle(
                color: FblaColors.goldDeep,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            const _MockButton(
              label: 'Sign In',
              icon: Icons.login_rounded,
              filled: true,
            ),
            const SizedBox(height: 12),
            const _MockButton(
              label: 'Create Account',
              icon: Icons.person_add_alt_1_outlined,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DashboardMock extends StatelessWidget {
  const _DashboardMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIndex: 0,
      tutorial:
          'Start here: review activity, upcoming events, news, messages, and points.',
      children: [
        _HeroCard(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatPill(
                label: 'Points',
                value: '420',
                icon: Icons.stars_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                label: 'Rank',
                value: '#8',
                icon: Icons.leaderboard_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Recent Announcement',
          body: 'National Fall Leadership Conference registration is open.',
          icon: Icons.campaign_outlined,
        ),
        _InfoCard(
          title: 'Upcoming Event',
          body: 'Accounting workshop today at 2:00 PM.',
          icon: Icons.event_outlined,
        ),
      ],
    );
  }
}

class _CalendarMock extends StatelessWidget {
  const _CalendarMock({required this.showDetail});

  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    return _MockScaffold(
      title: 'Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIndex: 1,
      tutorial: 'Tap a date, then choose an event to view the details.',
      children: [
        const _CalendarGrid(),
        const SizedBox(height: 12),
        const _InfoCard(
          title: 'Today',
          body: 'State Leadership Conference - competitions and workshops',
          icon: Icons.location_on_outlined,
        ),
        if (showDetail) const _EventDetailCard(),
      ],
    );
  }
}

class _CompetitionsMock extends StatelessWidget {
  const _CompetitionsMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'Competitions',
      icon: Icons.emoji_events_outlined,
      selectedIndex: 3,
      tutorial: 'Filter events, open one, and jump to official guidelines.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(label: 'All'),
            _Chip(label: 'Objective Tests'),
            _Chip(label: 'Presentation'),
          ],
        ),
        SizedBox(height: 12),
        _CompetitionDialogMock(),
      ],
    );
  }
}

class _NewsMock extends StatelessWidget {
  const _NewsMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'News',
      icon: Icons.campaign_outlined,
      selectedIndex: 2,
      tutorial: 'Browse official FBLA updates in one consistent feed.',
      children: [
        _NewsTile(
          title: 'FBLA Announces National Officers',
          tag: 'National Center News',
        ),
        _NewsTile(
          title: 'Scholarship deadline approaching',
          tag: 'Opportunity',
        ),
        _NewsTile(title: 'Conference packing checklist', tag: 'Conference'),
      ],
    );
  }
}

class _SocialMock extends StatelessWidget {
  const _SocialMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'Social',
      icon: Icons.people_alt_outlined,
      selectedIndex: 4,
      tutorial:
          'Share achievements, follow official accounts, and message members.',
      children: [
        _MockButton(
          label: 'Share your achievements',
          icon: Icons.ios_share_rounded,
          filled: true,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialNetwork(
                label: 'Instagram',
                icon: Icons.camera_alt_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SocialNetwork(
                label: 'LinkedIn',
                icon: Icons.business_center_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _MessagePreview(),
      ],
    );
  }
}

class _PinsMock extends StatelessWidget {
  const _PinsMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'Pin Trading',
      icon: Icons.push_pin_outlined,
      selectedIndex: 4,
      tutorial: 'Post what you want, then offer a pin of your own.',
      children: [
        _MockButton(label: 'Create pin request', icon: Icons.add, filled: true),
        SizedBox(height: 12),
        _PinTradeCard(
          wanted: 'Looking for California 2026',
          offer: 'Offering: Arizona torch pin - Good',
        ),
        _PinTradeCard(
          wanted: 'Looking for National officer pin',
          offer: 'Offering: chapter anniversary pin - Mint',
        ),
      ],
    );
  }
}

class _ProfileMock extends StatelessWidget {
  const _ProfileMock();

  @override
  Widget build(BuildContext context) {
    return const _MockScaffold(
      title: 'Profile',
      icon: Icons.person_outline,
      selectedIndex: 5,
      tutorial:
          'Track personal information, activity, points, and accessibility settings.',
      children: [
        _ProfileHeaderMock(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatPill(
                label: 'Articles',
                value: '12',
                icon: Icons.article_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                label: 'Points',
                value: '420',
                icon: Icons.stars_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _SettingsPreview(),
      ],
    );
  }
}

class _MockNav extends StatelessWidget {
  const _MockNav({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_outlined, 'Home'),
      (Icons.calendar_today_outlined, 'Calendar'),
      (Icons.campaign_outlined, 'News'),
      (Icons.emoji_events_outlined, 'Compete'),
      (Icons.people_alt_outlined, 'Social'),
      (Icons.person_outline, 'Profile'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: i == selectedIndex ? FblaColors.navy : FblaColors.muted,
                    size: 20,
                  ),
                  Text(
                    items[i].$2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == selectedIndex ? FblaColors.navy : FblaColors.muted,
                      fontSize: 9,
                      fontWeight: i == selectedIndex ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [FblaColors.navy, FblaColors.blue]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back, Hayden',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'See what you missed.',
            style: TextStyle(
              color: FblaColors.gold,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: FblaColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: FblaColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: FblaColors.mist,
            child: Icon(icon, color: FblaColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FblaColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: FblaColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  const _MockButton({
    required this.label,
    required this.icon,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: filled ? FblaColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: filled ? FblaColors.navy : FblaColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: filled ? Colors.white : FblaColors.navy),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : FblaColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    final days = List.generate(21, (index) => index + 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FblaColors.line),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        children: [
          for (final day in days)
            Container(
              decoration: BoxDecoration(
                color: day == 14
                    ? FblaColors.gold
                    : day == 18
                        ? FblaColors.mist
                        : FblaColors.porcelain,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: day == 14 ? FblaColors.goldDeep : FblaColors.line,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  color: day == 14 ? FblaColors.navy : FblaColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventDetailCard extends StatelessWidget {
  const _EventDetailCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FblaColors.gold, width: 2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State Leadership Conference',
            style: TextStyle(
              color: FblaColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Today â€¢ 9:00 AM - 4:00 PM',
            style: TextStyle(
              color: FblaColors.goldDeep,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Competitions, workshops, awards, networking, and chapter programming in one place.',
            style: TextStyle(color: FblaColors.text, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: FblaColors.mist,
      side: BorderSide.none,
    );
  }
}

class _CompetitionDialogMock extends StatelessWidget {
  const _CompetitionDialogMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FblaColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, color: FblaColors.navy),
              SizedBox(width: 8),
              Text(
                'Accounting',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Objective test covering financial statements, journal entries, payroll, and accounting concepts.',
          ),
          SizedBox(height: 12),
          _MockButton(
            label: 'Open event guidelines',
            icon: Icons.open_in_new,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.title, required this.tag});

  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: FblaColors.goldDeep,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: FblaColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Synced from FBLA and saved where members can find it later.',
            style: TextStyle(color: FblaColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SocialNetwork extends StatelessWidget {
  const _SocialNetwork({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: FblaColors.navy),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      title: 'Message request',
      body: 'Maya wants to connect about Business Ethics practice.',
      icon: Icons.forum_outlined,
    );
  }
}

class _PinTradeCard extends StatelessWidget {
  const _PinTradeCard({required this.wanted, required this.offer});

  final String wanted;
  final String offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: FblaColors.mist,
            child: Icon(Icons.push_pin_outlined, color: FblaColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wanted, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  offer,
                  style: const TextStyle(color: FblaColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            'Offer',
            style: TextStyle(
              color: FblaColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderMock extends StatelessWidget {
  const _ProfileHeaderMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FblaColors.line),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: FblaColors.navy,
            child: Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hayden Carter',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Westview FBLA â€¢ Arizona',
                  style: TextStyle(color: FblaColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPreview extends StatelessWidget {
  const _SettingsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FblaColors.line),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: FblaColors.navy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dark mode toggle',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Switch(value: true, onChanged: null),
            ],
          ),
          Divider(),
          Row(
            children: [
              Icon(Icons.accessibility_new_outlined, color: FblaColors.navy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Accessibility options',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }
}
