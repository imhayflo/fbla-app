import 'package:flutter/material.dart';
import 'package:fbla_member_app/models/state_competition_result.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/utils/constants.dart';

class StatePlacementBadge extends StatelessWidget {
  final StateCompetitionResult result;
  final bool compact;

  const StatePlacementBadge({
    super.key,
    required this.result,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _badgeColors(result.placement);
    final stateName = stateCodeToName(result.stateCode);
    final month = _monthName(result.conferenceMonth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.placementOrdinal.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.eventShortLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$stateName · $month ${result.conferenceYear}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<Color> _badgeColors(int placement) {
    switch (placement) {
      case 1:
        return [const Color(0xFFFFD54F), FblaColors.goldDeep];
      case 2:
        return [const Color(0xFFE8E8E8), const Color(0xFF9E9E9E)];
      case 3:
        return [const Color(0xFFE6A86E), const Color(0xFF8B5A2B)];
      default:
        return [FblaColors.navy, const Color(0xFF0A4A7A)];
    }
  }

  static String _monthName(int? month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month == null || month < 1 || month > 12) return '';
    return names[month];
  }
}

class StatePlacementDetailCard extends StatelessWidget {
  final StateCompetitionResult result;

  const StatePlacementDetailCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateName = stateCodeToName(result.stateCode);
    final month = StatePlacementBadge._monthName(result.conferenceMonth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatePlacementBadge(result: result, compact: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.eventName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.placementOrdinal} place · $stateName State FBLA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$month ${result.conferenceYear} · ${result.conferenceLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
