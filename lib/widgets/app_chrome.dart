// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/fbla_colors.dart';

void showFblaPrototypeMenu(
  BuildContext context, {
  required ValueChanged<int> onNavigate,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close menu',
    barrierColor: Colors.black.withOpacity(0.28),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _FblaPrototypeMenuOverlay(onNavigate: onNavigate);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class FblaPrototypeHeaderMark extends StatelessWidget {
  const FblaPrototypeHeaderMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: Color(0xFFD5A84F), size: 42),
        Icon(Icons.emoji_events_outlined, color: Color(0xFFD5A84F), size: 25),
      ],
    );
  }
}

class _FblaPrototypeMenuOverlay extends StatelessWidget {
  const _FblaPrototypeMenuOverlay({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Competitions', 3, false),
      ('News', 2, false),
      ('Events', 1, false),
      ('Your Profile', 5, false),
      ('Calendar', 1, false),
      ('Messages', 4, false),
      ('Pin Trading Hub', 4, false),
      ('Guide', 0, false),
      ('Resources', 0, false),
      ('Settings', 5, true),
    ];

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.78,
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F8FD)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              border: Border.all(color: FblaColors.line),
              boxShadow: [
                BoxShadow(
                  color: FblaColors.navy.withOpacity(0.24),
                  blurRadius: 34,
                  offset: const Offset(-8, 18),
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
                        boxShadow: [
                          BoxShadow(
                            color: FblaColors.navy.withOpacity(0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: FblaColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'FBLA-LINK',
                        style: TextStyle(
                          color: FblaColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FblaColors.gold,
                        FblaColors.line,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map(
                  (item) => _FblaMenuItem(
                    label: item.$1,
                    dark: item.$3,
                    onTap: () => onNavigate(item.$2),
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

class _FblaMenuItem extends StatelessWidget {
  const _FblaMenuItem({
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : FblaColors.text;
    final secondary = dark ? Colors.white70 : FblaColors.muted;
    return Material(
      color: dark ? FblaColors.text : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: dark ? FblaColors.text : Colors.white.withOpacity(0.68),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? FblaColors.text : FblaColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.star_border,
                  color: dark ? FblaColors.gold : FblaColors.navy, size: 25),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Menu description.',
                      style: TextStyle(color: secondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Icon(Icons.home_outlined, color: foreground, size: 18),
              Text(
                'A',
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaintStrokeReveal extends StatelessWidget {
  const PaintStrokeReveal({
    super.key,
    required this.progress,
    this.color = FblaColors.navy,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PaintStrokePainter(
          progress: progress.clamp(0, 1),
          color: color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PaintStrokePainter extends CustomPainter {
  const _PaintStrokePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.44;

    final path = Path()
      ..moveTo(size.width * 0.18, -size.height * 0.08)
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.22,
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.46,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.72,
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.78,
        size.height * 1.1,
      );

    final metric = path.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(visible, paint);
  }

  @override
  bool shouldRepaint(covariant _PaintStrokePainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

class AppInstructionCard extends StatefulWidget {
  final String id;
  final String title;
  final List<String> tips;

  const AppInstructionCard({
    super.key,
    required this.id,
    required this.title,
    required this.tips,
  });

  @override
  State<AppInstructionCard> createState() => _AppInstructionCardState();
}

class AppHelpButton extends StatelessWidget {
  final String title;
  final List<String> tips;

  const AppHelpButton({
    super.key,
    required this.title,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help',
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FblaColors.navy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 20, color: FblaColors.goldDeep),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AppInstructionCardState extends State<AppInstructionCard> {
  static const _prefix = 'instruction_dismissed_';
  bool _loading = true;
  bool _dismissed = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool('$_prefix${widget.id}') ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${widget.id}', true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed || widget.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final atEnd = _index >= widget.tips.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF4D7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FblaColors.gold.withOpacity(0.55)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: FblaColors.gold.withOpacity(0.22),
                child: const Icon(Icons.lightbulb_outline,
                    color: FblaColors.goldDeep, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FblaColors.navy,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _dismiss,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.tips[_index],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF374151),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: _dismiss,
                child: const Text('Skip'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: atEnd ? _dismiss : () => setState(() => _index += 1),
                child: Text(atEnd ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FblaColors.text,
                  ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FblaColors.mist,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: FblaColors.navy.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: FblaColors.navy, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
