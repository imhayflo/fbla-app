import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/fbla_colors.dart';

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
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FblaColors.gold.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: FblaColors.navy.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                onPressed: atEnd
                    ? _dismiss
                    : () => setState(() => _index += 1),
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
                    color: const Color(0xFF111827),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary, size: 30),
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
