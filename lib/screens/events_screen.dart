import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/calendar_sync_service.dart';
import '../services/database_service.dart';
import '../models/event.dart';
import '../widgets/fbla_app_bar.dart';
import '../widgets/fbla_screen_shell.dart';
import '../widgets/app_chrome.dart';
import '../models/competition.dart';

class EventsScreen extends StatefulWidget {
  final DateTime? initialDate;

  const EventsScreen({super.key, this.initialDate});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final CalendarSyncService _calendarSyncService = CalendarSyncService();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FblaAppBar.standard(
        context,
        title: 'Calendar',
        actions: [
          const AppHelpButton(
            title: 'Use your FBLA calendar',
            tips: [
              'Dots show days with FBLA events. Tap a date to see what is happening that day.',
              'Use Generate prep advice to get a preparation plan for upcoming events and competitions.',
            ],
          ),
          TextButton.icon(
            onPressed: () => _showAiPrepAdvice(
              context,
              events: const [],
              competitions: const [],
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _dbService.syncFBLACalendar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing calendar...')),
              );
            },
          ),
        ],
      ),
      body: FblaScreenShell(
        child: StreamBuilder<List<Event>>(
        stream: _dbService.eventsStream,
        builder: (context, eventSnapshot) {
          // Only show loading if we're waiting for data AND there's no cached data
          if (eventSnapshot.connectionState == ConnectionState.waiting &&
              (eventSnapshot.data == null || eventSnapshot.data!.isEmpty) &&
              DatabaseService.isCalendarSyncing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Loading Calendar...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Fetching events from FBLA'),
                ],
              ),
            );
          }
          return StreamBuilder<List<Competition>>(
            stream: _dbService.competitionsStream,
            builder: (context, compSnapshot) {
              final events = _withNlcSchedule(eventSnapshot.data ?? []);
              final competitions = compSnapshot.data ?? [];

              // Get registered events to determine marker colors
              return StreamBuilder<List<String>>(
                stream: _dbService.userRegisteredEventsStream,
                builder: (context, regEventsSnapshot) {
                  return StreamBuilder<List<String>>(
                    stream: _dbService.userRegisteredCompetitionsStream,
                    builder: (context, regCompsSnapshot) {
                      final regEventIds = regEventsSnapshot.data ?? [];
                      final regCompIds = regCompsSnapshot.data ?? [];
                      
                      // Get all events for showing markers (black dots)
                      // Only show events, not competitions (competitions don't have real dates)
                      final allEventDates = _getEventDates(events, []);

                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: AppInstructionCard(
                              id: 'calendar',
                              title: 'Use your FBLA calendar',
                              tips: [
                                'Dots show days with FBLA events. Tap a date to see what is happening that day.',
                                'Use Generate prep advice to get a preparation plan for upcoming events and competitions.',
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _showAiPrepAdvice(
                                  context,
                                  events: events,
                                  competitions: competitions,
                                ),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Generate AI prep advice'),
                              ),
                            ),
                          ),
                          TableCalendar<dynamic>(
                            firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                            lastDay: DateTime.utc(DateTime.now().year + 2, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            calendarFormat: _calendarFormat,
                            eventLoader: (day) {
                              final dateKey = DateTime(day.year, day.month, day.day);
                              return allEventDates[dateKey] ?? [];
                            },
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                // Check if there's any registered event on this day
                                final dateKey = DateTime(day.year, day.month, day.day);
                                final events = allEventDates[dateKey] ?? [];
                                
                                // Check if any event is registered
                                final hasRegisteredEvent = events.any((event) => 
                                  _isEventRegistered(event, regEventIds, regCompIds));
                                
                                if (hasRegisteredEvent) {
                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }
                                return null; // Use default appearance
                              },
                              markerBuilder: (context, date, events) {
                                if (events.isEmpty) return null;
                                // Check if any event is registered
                                final hasRegisteredEvent = events.any((event) => 
                                  _isEventRegistered(event, regEventIds, regCompIds));
                                
                                // Only show dots for non-registered events (in black)
                                final nonRegisteredEvents = events.where((event) => 
                                  !_isEventRegistered(event, regEventIds, regCompIds)).toList();
                                
                                if (nonRegisteredEvents.isEmpty && hasRegisteredEvent) {
                                  // All events are registered - no dots needed since cell is red
                                  return null;
                                }
                                
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ...nonRegisteredEvents.map((event) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() => _calendarFormat = format);
                            },
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 3,
                              markerSize: 8,
                              markerDecoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _SelectedDayEventsList(
                              selectedDay: _selectedDay,
                              events: events,
                              competitions: competitions,
                              dbService: _dbService,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  Map<DateTime, List<dynamic>> _getEventDates(
    List<Event> events,
    List<Competition> competitions,
  ) {
    final Map<DateTime, List<dynamic>> result = {};

    for (final event in events) {
      var date = event.date;
      final endDate = event.endDate ?? event.date;
      while (!date.isAfter(endDate)) {
        final key = DateTime(date.year, date.month, date.day);
        result.putIfAbsent(key, () => []).add(event);
        date = date.add(const Duration(days: 1));
      }
    }

    for (final comp in competitions) {
      final key = DateTime(comp.date.year, comp.date.month, comp.date.day);
      result.putIfAbsent(key, () => []).add(comp);
    }

    return result;
  }

  List<Event> _withNlcSchedule(List<Event> events) {
    final byId = <String, Event>{for (final event in events) event.id: event};
    for (final event
        in _calendarSyncService.nationalLeadershipConferenceSchedule2026()) {
      byId[event.id] = event;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  bool _isEventRegistered(dynamic event, List<String> regEventIds, List<String> regCompIds) {
    if (event is Event) {
      return regEventIds.contains(event.id);
    } else if (event is Competition) {
      return regCompIds.contains(event.id);
    }
    return false;
  }

  Future<void> _showAiPrepAdvice(
    BuildContext context, {
    required List<Event> events,
    required List<Competition> competitions,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AiPrepAdviceSheet(
        events: events,
        competitions: competitions,
      ),
    );
  }
}

class _AiPrepAdvice {
  final String summary;
  final List<String> tips;
  final List<String> deadlines;
  final List<String> weeklyPlan;
  final bool usedAi;

  const _AiPrepAdvice({
    required this.summary,
    required this.tips,
    required this.deadlines,
    required this.weeklyPlan,
    required this.usedAi,
  });

  factory _AiPrepAdvice.fromMap(Map<String, dynamic> map) {
    List<String> readList(String key) {
      return (map[key] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    return _AiPrepAdvice(
      summary: map['summary'] as String? ?? 'Here is a preparation plan.',
      tips: readList('tips'),
      deadlines: readList('deadlines'),
      weeklyPlan: readList('weeklyPlan'),
      usedAi: map['usedAi'] as bool? ?? true,
    );
  }
}

class _AiPrepAdviceSheet extends StatefulWidget {
  final List<Event> events;
  final List<Competition> competitions;

  const _AiPrepAdviceSheet({
    required this.events,
    required this.competitions,
  });

  @override
  State<_AiPrepAdviceSheet> createState() => _AiPrepAdviceSheetState();
}

class _AiPrepAdviceSheetState extends State<_AiPrepAdviceSheet> {
  _AiPrepAdvice? _advice;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  List<dynamic> get _upcomingItems {
    final now = DateTime.now();
    final items = <dynamic>[
      ...widget.events.where((event) => !event.date.isBefore(now)),
      ...widget.competitions.where((competition) => !competition.date.isBefore(now)),
    ];
    items.sort((a, b) {
      final aDate = a is Event ? a.date : (a as Competition).date;
      final bDate = b is Event ? b.date : (b as Competition).date;
      return aDate.compareTo(bDate);
    });
    return items.take(6).toList();
  }

  Future<void> _loadAdvice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final advice = await _loadBackendAdvice();
      if (mounted) {
        setState(() => _advice = advice);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _advice = _fallbackAdvice();
          _error =
              'AI request failed. This built-in prep plan is showing until the backend key is deployed.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<_AiPrepAdvice> _loadBackendAdvice() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'getCalendarPrepAdvice',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call<Map<String, dynamic>>({
      'items': _upcomingItems.map((item) {
        if (item is Event) {
          return {
            'title': item.title,
            'type': item.type,
            'level': 'Event',
            'date': DateFormat.yMMMd().format(item.date),
          };
        }

        final competition = item as Competition;
        return {
          'title': competition.name,
          'type': competition.category,
          'level': competition.level,
          'date': DateFormat.yMMMd().format(competition.date),
        };
      }).toList(),
    });

    return _AiPrepAdvice.fromMap(Map<String, dynamic>.from(result.data));
  }

  _AiPrepAdvice _fallbackAdvice() {
    final focus = _upcomingItems.isEmpty
        ? 'your next FBLA event'
        : _upcomingItems.first is Event
            ? (_upcomingItems.first as Event).title
            : (_upcomingItems.first as Competition).name;

    return _AiPrepAdvice(
      summary:
          'Build a steady preparation rhythm for $focus. Work backward from the event date instead of waiting until the last week.',
      tips: const [
        'Review the official event guidelines and scoring rubric.',
        'Make a short checklist of materials, attire, forms, and deadlines.',
        'Schedule at least two practice runs with an adviser or teammate.',
        'Use one session for content and one session for timing and delivery.',
      ],
      deadlines: const [
        '6 weeks before: read rules and choose your prep resources.',
        '4 weeks before: finish your outline, slides, or study guide.',
        '2 weeks before: complete a timed mock run.',
        '1 week before: polish materials and confirm travel/logistics.',
      ],
      weeklyPlan: const [
        'Week 1: understand the event and scoring criteria.',
        'Week 2: build your main content or study notes.',
        'Week 3: practice and collect feedback.',
        'Week 4: final review, confidence practice, and logistics.',
      ],
      usedAi: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
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
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Preparation Advice',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Planning help for upcoming FBLA events and competitions.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _loadAdvice,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(_advice == null ? 'Generate advice' : 'Refresh advice'),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_advice != null) ...[
            const SizedBox(height: 20),
            Text(_advice!.summary, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            _AdviceSection(title: 'Prep tips', items: _advice!.tips),
            _AdviceSection(title: 'Example deadlines', items: _advice!.deadlines),
            _AdviceSection(title: 'Weekly plan', items: _advice!.weeklyPlan),
            if (!_advice!.usedAi) ...[
              const SizedBox(height: 8),
              Text(
                'Live Gemini advice comes from the Firebase backend once GEMINI_API_KEY is deployed.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AdviceSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _AdviceSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayEventsList extends StatelessWidget {
  final DateTime selectedDay;
  final List<Event> events;
  final List<Competition> competitions;
  final DatabaseService dbService;

  const _SelectedDayEventsList({
    required this.selectedDay,
    required this.events,
    required this.competitions,
    required this.dbService,
  });

  List<dynamic> _getItemsForDay() {
    final selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final List<dynamic> items = [];

    for (final event in events) {
      var d = event.date;
      final end = event.endDate ?? event.date;
      while (!d.isAfter(end)) {
        if (DateTime(d.year, d.month, d.day) == selected) {
          items.add(_CalendarItem(event: event));
          break;
        }
        d = d.add(const Duration(days: 1));
      }
    }

    for (final comp in competitions) {
      if (DateTime(comp.date.year, comp.date.month, comp.date.day) == selected) {
        items.add(_CalendarItem(competition: comp));
      }
    }

    items.sort((a, b) {
      final aItem = a as _CalendarItem;
      final bItem = b as _CalendarItem;
      final aSchedule = aItem.event?.type == 'NLC Schedule';
      final bSchedule = bItem.event?.type == 'NLC Schedule';
      if (aSchedule != bSchedule) return aSchedule ? -1 : 1;
      return aItem.date.compareTo(bItem.date);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItemsForDay();
    final dateFormat = DateFormat('EEEE, MMMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            dateFormat.format(selectedDay),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events or competitions on this day',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: dbService.userRegisteredEventsStream,
              builder: (context, regEventsSnapshot) {
                return StreamBuilder<List<String>>(
                  stream: dbService.userRegisteredCompetitionsStream,
                  builder: (context, regCompsSnapshot) {
                    final regEvents = regEventsSnapshot.data ?? [];
                    final regComps = regCompsSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index] as _CalendarItem;
                        if (item.event != null) {
                          return _EventCalendarCard(
                            event: item.event!,
                            isRegistered: regEvents.contains(item.event!.id),
                            dbService: dbService,
                            onTap: () => _showEventDetails(
                              context,
                              item.event!,
                              regEvents.contains(item.event!.id),
                            ),
                          );
                        } else {
                          return _CompetitionCalendarCard(
                            competition: item.competition!,
                            isRegistered: regComps.contains(item.competition!.id),
                            dbService: dbService,
                            onTap: () => _showCompetitionDetails(
                              context,
                              item.competition!,
                              regComps.contains(item.competition!.id),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _showEventDetails(
    BuildContext context,
    Event event,
    bool isRegistered,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EventDetailsSheet(
        event: event,
        isRegistered: isRegistered,
        dbService: dbService,
      ),
    );
  }

  void _showCompetitionDetails(
    BuildContext context,
    Competition competition,
    bool isRegistered,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CompetitionDetailsSheet(
        competition: competition,
        isRegistered: isRegistered,
        dbService: dbService,
      ),
    );
  }
}

class _CalendarItem {
  final Event? event;
  final Competition? competition;

  _CalendarItem({this.event, this.competition})
      : assert(event != null || competition != null);

  DateTime get date =>
      event?.date ?? competition!.date;
}

class _EventCalendarCard extends StatelessWidget {
  final Event event;
  final bool isRegistered;
  final DatabaseService dbService;
  final VoidCallback onTap;

  const _EventCalendarCard({
    required this.event,
    required this.isRegistered,
    required this.dbService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
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
                            event.type,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isRegistered) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Marked',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.endDate != null && event.endDate != event.date
                          ? '${dateFormat.format(event.date)} - ${dateFormat.format(event.endDate!)}'
                          : dateFormat.format(event.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompetitionCalendarCard extends StatelessWidget {
  final Competition competition;
  final bool isRegistered;
  final DatabaseService dbService;
  final VoidCallback onTap;

  const _CompetitionCalendarCard({
    required this.competition,
    required this.isRegistered,
    required this.dbService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber,
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
                            competition.category,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        if (isRegistered) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Marked',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      competition.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(competition.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailsSheet extends StatefulWidget {
  final Event event;
  final bool isRegistered;
  final DatabaseService dbService;

  const _EventDetailsSheet({
    required this.event,
    required this.isRegistered,
    required this.dbService,
  });

  @override
  State<_EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<_EventDetailsSheet> {
  bool _isLoading = false;
  late bool _isRegistered;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
  }

  Future<void> _toggleRegistration() async {
    setState(() => _isLoading = true);
    try {
      if (_isRegistered) {
        await widget.dbService.unregisterFromEvent(widget.event.id);
      } else {
        await widget.dbService.registerForEvent(widget.event.id);
      }
      setState(() => _isRegistered = !_isRegistered);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegistered ? 'Marked on calendar!' : 'Unmarked'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.event.type,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(height: 16),
            Text(
              widget.event.title,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: widget.event.endDate != null
                  ? '${dateFormat.format(widget.event.date)} - ${dateFormat.format(widget.event.endDate!)}'
                  : dateFormat.format(widget.event.date),
            ),
            if (widget.event.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.event.description, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _toggleRegistration,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isRegistered ? Icons.check : Icons.event_available),
                label: Text(_isRegistered ? 'Marked' : 'Mark on My Calendar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isRegistered ? Colors.red : null,
                ),
              ),
            ),
          ],
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
  State<_CompetitionDetailsSheet> createState() => _CompetitionDetailsSheetState();
}

class _CompetitionDetailsSheetState extends State<_CompetitionDetailsSheet> {
  bool _isLoading = false;
  late bool _isRegistered;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
  }

  Future<void> _register() async {
    if (_isRegistered) return;
    setState(() => _isLoading = true);
    try {
      await widget.dbService.registerForCompetition(widget.competition.id);
      setState(() => _isRegistered = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked on calendar!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.competition.name,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
              value: widget.competition.participants,
            ),
            const SizedBox(height: 24),
            Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.competition.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading || _isRegistered ? null : _register,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isRegistered ? Icons.check : Icons.add),
                label: Text(_isRegistered ? 'Marked' : 'Mark on My Calendar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isRegistered ? Colors.red : null,
                ),
              ),
            ),
          ],
        ),
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
              Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
