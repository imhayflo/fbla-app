import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../models/competition.dart';
import '../widgets/fbla_app_bar.dart';
import '../widgets/fbla_screen_shell.dart';
import '../widgets/app_chrome.dart';

class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FblaAppBar.standard(
        context,
        title: 'Competitions',
        actions: const [
          AppHelpButton(
            title: 'Explore competitive events',
            tips: [
              'Use filter pills to browse event types, then tap a card to see details.',
              'Try the event finder if you are not sure which competition best fits your strengths.',
            ],
          ),
        ],
      ),
      body: FblaScreenShell(
        child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Competition>>(
              stream: _dbService.competitionsStream,
              builder: (context, compSnapshot) {
                if (compSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (compSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${compSnapshot.error}'),
                      ],
                    ),
                  );
                }

                final competitions = compSnapshot.data ?? [];
                final filteredCompetitions = _selectedCategory == 'All'
                    ? competitions
                    : competitions
                        .where((c) => c.category == _selectedCategory)
                        .toList();

                return StreamBuilder<List<String>>(
                  stream: _dbService.userRegisteredCompetitionsStream,
                  builder: (context, regSnapshot) {
                    final registeredIds = regSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          filteredCompetitions.isEmpty ? 4 : filteredCompetitions.length + 3,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const AppInstructionCard(
                            id: 'compete',
                            title: 'Explore competitive events',
                            tips: [
                              'Use the filter pills to browse event types, then tap a card to see details and mark it as your competition.',
                              'Try the event finder if you are not sure which competition best fits your strengths.',
                            ],
                          );
                        }
                        if (index == 1) {
                          return _EventFinderCard(
                            onTap: () => _showEventFinder(context, competitions),
                          );
                        }
                        if (index == 2) {
                          return _CategoryFilters(
                            selectedCategory: _selectedCategory,
                            onChanged: (category) {
                              setState(() => _selectedCategory = category);
                            },
                          );
                        }
                        if (filteredCompetitions.isEmpty) {
                          return _NoCompetitionsCard(category: _selectedCategory);
                        }

                        final competition = filteredCompetitions[index - 3];
                        final isRegistered =
                            registeredIds.contains(competition.id);
                        return _CompetitionCard(
                          competition: competition,
                          isRegistered: isRegistered,
                          onTap: () => _showCompetitionDetails(
                              context, competition, isRegistered),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showEventFinder(BuildContext context, List<Competition> competitions) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CompetitionFinderSheet(
        competitions: competitions,
        onOpenCompetition: (competition) {
          Navigator.pop(context);
          _showCompetitionDetails(context, competition, false);
        },
      ),
    );
  }

  void _showCompetitionDetails(
      BuildContext context, Competition competition, bool isRegistered) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CompetitionDetailsSheet(
        competition: competition,
        isRegistered: isRegistered,
        dbService: _dbService,
      ),
    );
  }
}

class _EventFinderCard extends StatelessWidget {
  const _EventFinderCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.primaryContainer.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.psychology_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find my competitive event',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take a quick quiz to match your strengths with events.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onTap,
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Objective Tests',
      'Presentation Events',
      'Role Play Events',
      'Chapter Events',
      'Production Events',
    ];
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories
            .map(
              (eventType) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(eventType),
                  selected: selectedCategory == eventType,
                  onSelected: (_) => onChanged(eventType),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NoCompetitionsCard extends StatelessWidget {
  const _NoCompetitionsCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            category == 'All' ? 'No competitions yet' : 'No $category competitions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionFinderSheet extends StatefulWidget {
  const _CompetitionFinderSheet({
    required this.competitions,
    required this.onOpenCompetition,
  });

  final List<Competition> competitions;
  final ValueChanged<Competition> onOpenCompetition;

  @override
  State<_CompetitionFinderSheet> createState() => _CompetitionFinderSheetState();
}

class _CompetitionFinderSheetState extends State<_CompetitionFinderSheet> {
  int _step = 0;
  String? _interest;
  String? _format;
  String? _workStyle;
  String? _strength;

  List<_FinderQuestion> get _questions => [
        _FinderQuestion(
          prompt: 'What sounds most interesting?',
          options: const [
            'Business strategy',
            'Technology',
            'Finance',
            'Marketing',
            'Public speaking',
            'Leadership',
          ],
          value: _interest,
          onSelected: (value) => setState(() => _interest = value),
        ),
        _FinderQuestion(
          prompt: 'What competition format feels best?',
          options: const [
            'Test',
            'Presentation',
            'Role play',
            'Project',
            'Writing or production',
          ],
          value: _format,
          onSelected: (value) => setState(() => _format = value),
        ),
        _FinderQuestion(
          prompt: 'How do you like to compete?',
          options: const [
            'Solo',
            'With a partner',
            'Team project',
            'Chapter-wide',
          ],
          value: _workStyle,
          onSelected: (value) => setState(() => _workStyle = value),
        ),
        _FinderQuestion(
          prompt: 'Pick your strongest skill.',
          options: const [
            'Analyzing information',
            'Building or designing',
            'Persuading people',
            'Organizing details',
            'Thinking fast',
          ],
          value: _strength,
          onSelected: (value) => setState(() => _strength = value),
        ),
      ];

  bool get _complete => _questions.every((question) => question.value != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, controller) {
          final question = _questions[_step];
          final matches = _complete ? _rankMatches() : <_CompetitionMatch>[];

          return ListView(
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
                  Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Competition Matchmaker',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Answer a few quick questions and get event recommendations.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: (_step + 1) / _questions.length),
              const SizedBox(height: 16),
              _ChatBubble(
                text: question.prompt,
                mine: false,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: question.options
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option),
                        selected: question.value == option,
                        onSelected: (_) {
                          question.onSelected(option);
                          if (_step < _questions.length - 1) {
                            setState(() => _step += 1);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _step == 0 ? null : () => setState(() => _step -= 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              if (_complete) ...[
                const SizedBox(height: 24),
                Text(
                  'Recommended events',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (matches.isEmpty)
                  const _FinderEmptyState()
                else
                  ...matches.take(5).map(
                        (match) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${match.score}%'),
                            ),
                            title: Text(match.competition.name),
                            subtitle: Text(match.reason),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onOpenCompetition(match.competition),
                          ),
                        ),
                      ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _reset() {
    setState(() {
      _step = 0;
      _interest = null;
      _format = null;
      _workStyle = null;
      _strength = null;
    });
  }

  List<_CompetitionMatch> _rankMatches() {
    final matches = widget.competitions.map((competition) {
      final text = '${competition.name} ${competition.category} '
              '${competition.description} ${competition.level}'
          .toLowerCase();
      var score = 30;
      final reasons = <String>[];

      void addIf(bool condition, int points, String reason) {
        if (!condition) return;
        score += points;
        reasons.add(reason);
      }

      addIf(_format == 'Test' && competition.category.contains('Objective'), 20,
          'matches your test preference');
      addIf(_format == 'Presentation' && competition.category.contains('Presentation'),
          20, 'matches your presentation preference');
      addIf(_format == 'Role play' && competition.category.contains('Role Play'), 20,
          'matches your role play preference');
      addIf(_format == 'Project' &&
          (competition.category.contains('Chapter') ||
              text.contains('project') ||
              text.contains('design')), 18, 'fits project-based work');
      addIf(_format == 'Writing or production' &&
          (competition.category.contains('Production') ||
              text.contains('word') ||
              text.contains('spreadsheet') ||
              text.contains('publication')), 18, 'fits production work');

      addIf(_interest == 'Technology' &&
          (text.contains('technology') ||
              text.contains('computer') ||
              text.contains('coding') ||
              text.contains('app') ||
              text.contains('digital')), 18, 'connects to technology');
      addIf(_interest == 'Finance' &&
          (text.contains('finance') ||
              text.contains('accounting') ||
              text.contains('banking') ||
              text.contains('securities')), 18, 'connects to finance');
      addIf(_interest == 'Marketing' &&
          (text.contains('marketing') ||
              text.contains('advertising') ||
              text.contains('sales')), 18, 'connects to marketing');
      addIf(_interest == 'Business strategy' &&
          (text.contains('business') ||
              text.contains('management') ||
              text.contains('entrepreneurship')), 18, 'connects to business strategy');
      addIf(_interest == 'Public speaking' &&
          (text.contains('speaking') ||
              text.contains('presentation') ||
              text.contains('public')), 18, 'uses public speaking');
      addIf(_interest == 'Leadership' &&
          (text.contains('leadership') ||
              text.contains('chapter') ||
              text.contains('community')), 18, 'connects to leadership');

      addIf(_workStyle == 'Solo' && competition.maxTeamSize == 1, 10,
          'works well solo');
      addIf(_workStyle == 'With a partner' && competition.maxTeamSize <= 2, 10,
          'works well with a partner');
      addIf(_workStyle == 'Team project' && competition.maxTeamSize >= 3, 10,
          'supports team competition');
      addIf(_workStyle == 'Chapter-wide' && competition.category.contains('Chapter'),
          12, 'fits chapter-wide involvement');

      addIf(_strength == 'Analyzing information' &&
          (competition.category.contains('Objective') ||
              text.contains('analysis') ||
              text.contains('case')), 12, 'rewards analysis');
      addIf(_strength == 'Building or designing' &&
          (text.contains('design') ||
              text.contains('app') ||
              text.contains('website') ||
              text.contains('production')), 12, 'uses building/design skills');
      addIf(_strength == 'Persuading people' &&
          (competition.category.contains('Presentation') ||
              text.contains('marketing') ||
              text.contains('sales')), 12, 'rewards persuasion');
      addIf(_strength == 'Organizing details' &&
          (text.contains('management') ||
              text.contains('planning') ||
              text.contains('administrative')), 12, 'rewards organization');
      addIf(_strength == 'Thinking fast' &&
          (competition.category.contains('Role Play') ||
              text.contains('impromptu') ||
              text.contains('case')), 12, 'rewards quick thinking');

      return _CompetitionMatch(
        competition: competition,
        score: score.clamp(1, 99).toInt(),
        reason: reasons.take(3).join(', '),
      );
    }).toList();

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }
}

class _FinderQuestion {
  final String prompt;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;

  const _FinderQuestion({
    required this.prompt,
    required this.options,
    required this.value,
    required this.onSelected,
  });
}

class _CompetitionMatch {
  final Competition competition;
  final int score;
  final String reason;

  const _CompetitionMatch({
    required this.competition,
    required this.score,
    required this.reason,
  });
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }
}

class _FinderEmptyState extends StatelessWidget {
  const _FinderEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text('Sync competitions first, then try the finder.')),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final Competition competition;
  final bool isRegistered;
  final VoidCallback onTap;

  const _CompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final statusColor = isRegistered ? Colors.green : Colors.blue;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      competition.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Registered',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      competition.level,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                competition.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                competition.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(competition.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Team: ${competition.participants}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
}

class _CompetitionDetailsSheet extends StatefulWidget {
  final Competition competition;
  final bool isRegistered;
  final DatabaseService dbService;

  const _CompetitionDetailsSheet({
    required this.competition,
    required this.isRegistered,
    required this.dbService,
  });

  @override
  State<_CompetitionDetailsSheet> createState() =>
      _CompetitionDetailsSheetState();
}

class _CompetitionDetailsSheetState extends State<_CompetitionDetailsSheet> {
  bool _isLoading = false;
  late bool _isRegistered;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
  }

  Future<void> _openGuidelinesUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $url')),
      );
    }
  }

  Future<void> _register() async {
    if (_isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already registered for this competition')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.dbService.registerForCompetition(widget.competition.id);
      setState(() => _isRegistered = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered for competition!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unregister() async {
    if (!_isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not registered for this competition')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.dbService.unregisterFromCompetition(widget.competition.id);
      setState(() => _isRegistered = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unregistered from competition')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final statusColor = _isRegistered ? Colors.green : Colors.blue;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.competition.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isRegistered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Registered',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.competition.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.competition.level,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: dateFormat.format(widget.competition.date),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.people,
                    label: 'Team Size',
                    value: 'Team: ${widget.competition.participants}',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.competition.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (widget.competition.usesJudges) ...[
                    const SizedBox(height: 24),
                    _JudgeSimulatorPrompt(
                      competition: widget.competition,
                      onTap: () => _showJudgeSimulator(context),
                    ),
                  ],
                  if (widget.competition.guidelinesUrl != null &&
                      widget.competition.guidelinesUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Event Details & Guidelines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openGuidelinesUrl(
                          context, widget.competition.guidelinesUrl!),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View guidelines & test competencies (PDF)',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : (_isRegistered ? _unregister : _register),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_isRegistered ? Icons.close : Icons.add),
                      label: Text(
                        _isRegistered ? 'Unmark as my Competition' : 'Mark as my Competition',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isRegistered ? Colors.red : null,
                      ),
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

  void _showJudgeSimulator(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _JudgeSimulatorSheet(
        competition: widget.competition,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JudgeSimulatorPrompt extends StatelessWidget {
  const _JudgeSimulatorPrompt({
    required this.competition,
    required this.onTap,
  });

  final Competition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresentation =
        competition.category.toLowerCase().contains('presentation');
    return Card(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.65),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          child: const Icon(Icons.record_voice_over),
        ),
        title: const Text('AI Judge Simulator'),
        subtitle: Text(
          isPresentation
              ? 'Practice likely judge questions and get scored feedback.'
              : 'Practice explaining your event like you are in front of judges.',
        ),
        trailing: FilledButton.tonal(
          onPressed: onTap,
          child: const Text('Practice'),
        ),
      ),
    );
  }
}

class _JudgeSimulatorSheet extends StatefulWidget {
  const _JudgeSimulatorSheet({required this.competition});

  final Competition competition;

  @override
  State<_JudgeSimulatorSheet> createState() => _JudgeSimulatorSheetState();
}

class _JudgeSimulatorSheetState extends State<_JudgeSimulatorSheet> {
  final TextEditingController _answerController = TextEditingController();
  int _questionIndex = 0;
  _JudgeScore? _score;

  List<String> get _questions {
    final name = widget.competition.name;
    final category = widget.competition.category.toLowerCase();
    final base = <String>[
      'Give us a quick overview of your $name project or preparation.',
      'What problem are you solving, and why does it matter?',
      'What was your strongest decision, and what evidence supports it?',
      'What would you improve if you had two more weeks?',
      'How does your work connect to real business or leadership impact?',
    ];

    if (category.contains('presentation')) {
      return [
        'Start your presentation pitch for $name in 45 seconds.',
        'What makes your idea or solution stand out from others?',
        'How did you divide work, practice delivery, and prepare for questions?',
        ...base.take(3),
      ];
    }
    if (category.contains('role play')) {
      return [
        'Walk through how you would handle a surprise business scenario.',
        'What information would you ask for before making a recommendation?',
        'How would you persuade a customer or manager to accept your solution?',
        ...base.take(3),
      ];
    }
    return base;
  }

  String get _currentQuestion => _questions[_questionIndex % _questions.length];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _scoreAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    setState(() => _score = _JudgeScore.fromAnswer(answer));
  }

  void _nextQuestion() {
    setState(() {
      _questionIndex += 1;
      _score = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
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
                Icon(Icons.record_voice_over, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Judge Simulator',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.competition.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _JudgeBubble(text: _currentQuestion),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                hintText: 'Type how you would answer the judge...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scoreAnswer,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Score answer'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Next question',
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            if (_score != null) ...[
              const SizedBox(height: 20),
              _ScoreCard(score: _score!),
            ],
          ],
        ),
      ),
    );
  }
}

class _JudgeBubble extends StatelessWidget {
  const _JudgeBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final _JudgeScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judge feedback: ${score.overall}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ScoreBar(label: 'Clarity', value: score.clarity),
            _ScoreBar(label: 'Confidence', value: score.confidence),
            _ScoreBar(label: 'Completeness', value: score.completeness),
            const SizedBox(height: 12),
            Text('Better sample answer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 6),
            Text(score.sampleAnswer),
            const SizedBox(height: 12),
            Text('Next improvement',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 6),
            Text(score.tip),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: LinearProgressIndicator(value: value / 100)),
          const SizedBox(width: 8),
          Text('$value%'),
        ],
      ),
    );
  }
}

class _JudgeScore {
  final int clarity;
  final int confidence;
  final int completeness;
  final String sampleAnswer;
  final String tip;

  const _JudgeScore({
    required this.clarity,
    required this.confidence,
    required this.completeness,
    required this.sampleAnswer,
    required this.tip,
  });

  int get overall => ((clarity + confidence + completeness) / 3).round();

  factory _JudgeScore.fromAnswer(String answer) {
    final words = answer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final sentences = RegExp(r'[.!?]').allMatches(answer).length;
    final lower = answer.toLowerCase();
    var clarity = 45 + (sentences >= 2 ? 18 : 0) + (words >= 45 ? 20 : words ~/ 3);
    var confidence = 50;
    if (lower.contains('i believe') || lower.contains('we recommend')) confidence += 15;
    if (lower.contains('because') || lower.contains('therefore')) confidence += 12;
    if (lower.contains('maybe') || lower.contains('i guess')) confidence -= 10;
    var completeness = 40;
    for (final marker in ['problem', 'solution', 'result', 'evidence', 'customer', 'business']) {
      if (lower.contains(marker)) completeness += 8;
    }

    clarity = clarity.clamp(1, 100).toInt();
    confidence = confidence.clamp(1, 100).toInt();
    completeness = completeness.clamp(1, 100).toInt();

    return _JudgeScore(
      clarity: clarity,
      confidence: confidence,
      completeness: completeness,
      sampleAnswer:
          'A stronger answer starts with the main point, gives one specific example, explains the business impact, and ends with what you would do next.',
      tip: words < 40
          ? 'Add more specifics: name the audience, problem, decision, and result.'
          : 'Tighten the ending with one confident recommendation or lesson learned.',
    );
  }
}
