import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/event.dart';
import '../models/competition.dart';

class EventsScreen extends StatefulWidget {
  final DateTime? initialDate;

  const EventsScreen({super.key, this.initialDate});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final DatabaseService _dbService = DatabaseService();
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
      appBar: AppBar(
        title: const Text('Calendar'),
        elevation: 0,
        actions: [
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
      body: StreamBuilder<List<Event>>(
        stream: _dbService.eventsStream,
        builder: (context, eventSnapshot) {
          // Show loading while syncing or waiting or if events are empty
          if (DatabaseService.isCalendarSyncing ||
              eventSnapshot.connectionState == ConnectionState.waiting ||
              (eventSnapshot.data?.isEmpty ?? true)) {
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
              final events = eventSnapshot.data ?? [];
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
                      final allEventDates = _getEventDates(events, competitions);

                      return Column(
                        children: [
                          TableCalendar<dynamic>(
                            firstDay: DateTime.utc(2026, 1, 1),
                            lastDay: DateTime.utc(2026, 12, 31),
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
                                    decoration: BoxDecoration(
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
                              markerDecoration: BoxDecoration(
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

  bool _isEventRegistered(dynamic event, List<String> regEventIds, List<String> regCompIds) {
    if (event is Event) {
      return regEventIds.contains(event.id);
    } else if (event is Competition) {
      return regCompIds.contains(event.id);
    }
    return false;
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
      final aDate = (a as _CalendarItem).date;
      final bDate = (b as _CalendarItem).date;
      return aDate.compareTo(bDate);
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

// Reuse existing sheet components - simplified inline versions
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
