import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/event.dart';

/// Pulls public FBLA events from fbla.org and normalizes them for the app calendar.
class CalendarSyncService {
  static final _headers = {
    'Accept': 'application/json,text/calendar,text/html;q=0.9,*/*;q=0.8',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
  };

  static final _jsonUrls = [
    'https://www.fbla.org/wp-json/tribe/events/v1/events?per_page=50',
    'https://www.fbla.org/wp-json/tribe/events/v1/events?per_page=50&start_date=' +
        DateTime.now().year.toString() +
        '-01-01',
  ];

  static final _icalUrls = [
    'https://www.fbla.org/events/?ical=1',
    'https://www.fbla.org/calendar/?ical=1',
  ];

  static final _htmlUrls = [
    'https://www.fbla.org/events/list/',
    'https://www.fbla.org/calendar/',
    'https://www.fbla.org/events/',
  ];

  Future<List<Event>> fetchUpcomingFBLCalendar() async {
    final byId = <String, Event>{};

    for (final url in _jsonUrls) {
      final events = await _fetchJsonEvents(url);
      _mergeEvents(byId, events);
      if (byId.isNotEmpty) return _sortedUpcoming(byId.values);
    }

    for (final url in _icalUrls) {
      final events = await _fetchIcalEvents(url);
      _mergeEvents(byId, events);
      if (byId.isNotEmpty) return _sortedUpcoming(byId.values);
    }

    for (final url in _htmlUrls) {
      final events = await _fetchHtmlEvents(url);
      _mergeEvents(byId, events);
    }

    if (byId.isEmpty) {
      _mergeEvents(byId, _officialFallbackEvents());
    }

    return _sortedUpcoming(byId.values);
  }

  Future<List<Event>> _fetchJsonEvents(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      final rawEvents = decoded is Map<String, dynamic>
          ? decoded['events']
          : decoded is List
              ? decoded
              : const [];
      if (rawEvents is! List) return [];

      return rawEvents
          .whereType<Map<String, dynamic>>()
          .map(_eventFromJson)
          .whereType<Event>()
          .toList();
    } catch (e) {
      print('Error fetching FBLA JSON calendar: $e');
      return [];
    }
  }

  Event? _eventFromJson(Map<String, dynamic> data) {
    final title = _cleanText(data['title']?.toString() ?? '');
    final startDetails = data['start_date_details'];
    final startText = data['start_date']?.toString() ??
        (startDetails is Map ? startDetails['date']?.toString() : null) ??
        '';
    final startDate = DateTime.tryParse(startText);
    if (title.isEmpty || startDate == null) return null;

    final endText = data['end_date']?.toString() ?? '';
    final endDate = DateTime.tryParse(endText);
    final venue = data['venue'];
    final location = venue is Map
        ? [venue['venue'], venue['city'], venue['stateprovince']]
            .where((part) => part != null && part.toString().trim().isNotEmpty)
            .join(', ')
        : '';
    final categories = data['categories'];
    final type = categories is List &&
            categories.isNotEmpty &&
            categories.first is Map
        ? categories.first['name']?.toString() ?? 'FBLA Event'
        : 'FBLA Event';

    return Event(
      id: _eventId(title, startDate, data['url']?.toString()),
      title: title,
      description: _cleanText(data['description']?.toString() ??
          data['excerpt']?.toString() ??
          'FBLA calendar event'),
      date: startDate,
      endDate: endDate,
      location: location,
      type: _cleanText(type),
      link: data['url']?.toString() ?? data['website']?.toString(),
    );
  }

  Future<List<Event>> _fetchIcalEvents(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || !response.body.contains('BEGIN:VEVENT')) {
        return [];
      }
      return _parseIcal(response.body);
    } catch (e) {
      print('Error fetching FBLA iCal calendar: $e');
      return [];
    }
  }

  List<Event> _parseIcal(String body) {
    final unfolded = body.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final blocks = RegExp(r'BEGIN:VEVENT([\s\S]*?)END:VEVENT')
        .allMatches(unfolded)
        .map((match) => match.group(1) ?? '');
    final events = <Event>[];

    for (final block in blocks) {
      final title = _decodeIcal(_field(block, 'SUMMARY'));
      final startDate = _parseIcalDate(_field(block, 'DTSTART'));
      if (title.isEmpty || startDate == null) continue;

      final link = _decodeIcal(_field(block, 'URL'));
      final description = _decodeIcal(_field(block, 'DESCRIPTION'));
      events.add(Event(
        id: _eventId(title, startDate, link.isEmpty ? null : link),
        title: title,
        description: description.isEmpty ? 'FBLA calendar event' : description,
        date: startDate,
        endDate: _parseIcalDate(_field(block, 'DTEND')),
        location: _decodeIcal(_field(block, 'LOCATION')),
        type: 'FBLA Event',
        link: link.isEmpty ? null : link,
      ));
    }

    return events;
  }

  String _field(String block, String name) {
    final match = RegExp('^' + name + r'(?:;[^:]*)?:(.*)', multiLine: true)
        .firstMatch(block);
    return match?.group(1)?.trim() ?? '';
  }

  DateTime? _parseIcalDate(String value) {
    if (value.isEmpty) return null;
    final clean = value.trim().replaceAll('Z', '');
    if (RegExp(r'^\d{8}$').hasMatch(clean)) {
      return DateTime(
        int.parse(clean.substring(0, 4)),
        int.parse(clean.substring(4, 6)),
        int.parse(clean.substring(6, 8)),
      );
    }
    if (RegExp(r'^\d{8}T\d{6}$').hasMatch(clean)) {
      return DateTime(
        int.parse(clean.substring(0, 4)),
        int.parse(clean.substring(4, 6)),
        int.parse(clean.substring(6, 8)),
        int.parse(clean.substring(9, 11)),
        int.parse(clean.substring(11, 13)),
        int.parse(clean.substring(13, 15)),
      );
    }
    return DateTime.tryParse(value);
  }

  Future<List<Event>> _fetchHtmlEvents(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final document = html_parser.parse(response.body);
      final events = _parseHtmlPage(document);
      if (events.isNotEmpty) return events;
      return _parsePlainTextEvents(document.body?.text ?? document.text);
    } catch (e) {
      print('Error fetching FBLA HTML calendar: $e');
      return [];
    }
  }

  List<Event> _parseHtmlPage(Document document) {
    final selectors = [
      '[data-js="tribe-events-view"] article',
      '.tribe-events-calendar-list__event',
      '.tribe-events-list-event',
      '.type-tribe_events',
      '[class*="tribe-events-calendar-list__event"]',
    ];

    final events = <Event>[];
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        final event = _parseHtmlEvent(element);
        if (event != null) events.add(event);
      }
      if (events.isNotEmpty) break;
    }
    return events;
  }

  List<Event> _parsePlainTextEvents(String text) {
    final cleaned = _cleanText(text);
    final events = <Event>[];

    final nlcMatch = RegExp(
      r'(2026 FBLA Middle School and High School National Leadership Conference).*?June\s+29\s*-\s*July\s+2.*?San Antonio,\s*Texas',
      caseSensitive: false,
    ).firstMatch(cleaned);
    final orientationMatch = RegExp(
      r'(2026 FBLA Middle School and High School NLC Orientation).*?June\s+11\s*@\s*12:00\s*pm\s*-\s*1:00\s*pm',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (orientationMatch != null) {
      events.add(_nlcOrientation2026());
    }
    if (nlcMatch != null) {
      events.add(_nationalLeadershipConference2026());
    }

    return events;
  }

  Event? _parseHtmlEvent(Element element) {
    final titleEl = element.querySelector(
      '.tribe-events-calendar-list__event-title a, .tribe-events-event-title a, h2 a, h3 a, a[href*="/event/"]',
    );
    final title = _cleanText(
      titleEl?.text ?? element.querySelector('h2, h3')?.text ?? '',
    );
    if (title.isEmpty) return null;

    final timeEl = element.querySelector('time[datetime]');
    final date = DateTime.tryParse(timeEl?.attributes['datetime'] ?? '') ??
        _extractDate(element.text);
    if (date == null) return null;

    final description = _cleanText(element
            .querySelector('.tribe-events-calendar-list__event-description, .tribe-events-content, .entry-summary, p')
            ?.text ??
        'FBLA calendar event');
    final location = _cleanText(element
            .querySelector('.tribe-events-calendar-list__event-venue, .tribe-events-venue-details, [class*="venue"]')
            ?.text ??
        '');
    final link = titleEl?.attributes['href'];

    return Event(
      id: _eventId(title, date, link),
      title: title,
      description: description.isEmpty ? 'FBLA calendar event' : description,
      date: date,
      location: location,
      type: 'FBLA Event',
      link: link,
    );
  }

  DateTime? _extractDate(String text) {
    final currentYear = DateTime.now().year;
    final match = RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\.?\s+(\d{1,2})(?:,\s*(\d{4}))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final month = _monthToNumber(match.group(1)!);
    final day = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3) ?? '') ?? currentYear;
    if (month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  void _mergeEvents(Map<String, Event> byId, Iterable<Event> events) {
    for (final event in events) {
      if (!event.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        byId[event.id] = event;
      }
    }
  }

  List<Event> _officialFallbackEvents() {
    return [
      _nlcOrientation2026(),
      _nationalLeadershipConference2026(),
    ];
  }

  Event _nlcOrientation2026() {
    const title = '2026 FBLA Middle School and High School NLC Orientation';
    final startDate = DateTime(2026, 6, 11, 12);
    return Event(
      id: _eventId(title, startDate, 'https://www.fbla.org/events/'),
      title: title,
      description:
          'Orientation webinar for the 2026 FBLA Middle School and High School National Leadership Conference.',
      date: startDate,
      endDate: DateTime(2026, 6, 11, 13),
      location: 'Online',
      type: 'Member Webinar',
      link: 'https://www.fbla.org/events/',
    );
  }

  Event _nationalLeadershipConference2026() {
    const title =
        '2026 FBLA Middle School and High School National Leadership Conference';
    final startDate = DateTime(2026, 6, 29);
    return Event(
      id: _eventId(title, startDate, 'https://www.fbla.org/events/'),
      title: title,
      description:
          'The 2026 Middle School & High School National Leadership Conference will take place in San Antonio, Texas on June 29-July 2.',
      date: startDate,
      endDate: DateTime(2026, 7, 2),
      location: 'San Antonio, Texas',
      type: 'Conferences',
      link: 'https://www.fbla.org/events/',
    );
  }

  List<Event> _sortedUpcoming(Iterable<Event> events) {
    final sorted = events.toList()..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  String _eventId(String title, DateTime date, String? link) {
    final raw = ((link ?? title) + '_' + date.toIso8601String().substring(0, 10))
        .toLowerCase();
    final normalized = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'fbla_' + normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _cleanText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _decodeIcal(String value) {
    return value
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', '\\')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int? _monthToNumber(String monthName) {
    const months = {
      'january': 1,
      'jan': 1,
      'february': 2,
      'feb': 2,
      'march': 3,
      'mar': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'june': 6,
      'jun': 6,
      'july': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sep': 9,
      'sept': 9,
      'october': 10,
      'oct': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'dec': 12,
    };
    return months[monthName.toLowerCase().replaceAll('.', '')];
  }
}
