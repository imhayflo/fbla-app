// Scrapes FBLA high school and middle school competitive events from:
//   https://www.fbla.org/high-school/competitive-events/
//   https://www.fbla.org/middle-school/competitive-events/
//
// For each event: name, description, level, and the "Event Details & Guidelines"
// link (test competencies PDF). Run from project root: dart run scripts/scrape_competitions.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

const _highSchoolUrl = 'https://www.fbla.org/high-school/competitive-events/';
const _middleSchoolUrl = 'https://www.fbla.org/middle-school/competitive-events/';

final _headers = {
  'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

void main(List<String> args) async {
  final outputJson = args.contains('--json');
  final all = <Map<String, dynamic>>[];

  for (final entry in [
    ('High School', _highSchoolUrl),
    ('Middle School', _middleSchoolUrl),
  ]) {
    final level = entry.$1;
    final url = entry.$2;
    print('Fetching $level: $url');
    try {
      final resp = await http.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode != 200) {
        print('  Failed: ${resp.statusCode}\n');
        continue;
      }
      final doc = html_parser.parse(resp.body);
      final events = _parsePage(doc, level);
      print('  Events: ${events.length}');
      for (final e in events) {
        all.add(e);
        if (!outputJson && all.length <= 4) {
          print('  ---');
          print('  Name: ${e['name']}');
          print('  Description: ${(e['description'] as String).length > 80 ? '${(e['description'] as String).substring(0, 80)}...' : e['description']}');
          print('  Guidelines (test competencies): ${e['guidelinesUrl'] ?? '(none)'}');
        }
      }
      print('');
    } catch (e, st) {
      print('  Error: $e\n$st');
    }
  }

  print('Total events: ${all.length}');
  final withGuidelines = all.where((e) => e['guidelinesUrl'] != null && (e['guidelinesUrl'] as String).isNotEmpty).length;
  print('With Event Details & Guidelines link: $withGuidelines');

  if (outputJson) {
    print('\n--- JSON (first 2 events per level) ---');
    final byLevel = <String, List<Map<String, dynamic>>>{};
    for (final e in all) {
      final l = e['level'] as String;
      byLevel.putIfAbsent(l, () => []).add(e);
    }
    final sample = <Map<String, dynamic>>[];
    for (final list in byLevel.values) {
      sample.addAll(list.take(2));
    }
    print(const JsonEncoder.withIndent('  ').convert(sample));
  }
}

bool _isFilterOrResource(String name) {
  final lower = name.toLowerCase();
  return lower.contains('resources') ||
      lower.contains('clear filters') ||
      lower.contains('event category') ||
      lower.contains('event type') ||
      lower.contains('career cluster') ||
      lower.contains('nace competency') ||
      lower.contains('nace crosswalk') ||
      lower.contains('announcements') ||
      lower.contains('view resources') ||
      lower.contains('upcoming national') ||
      lower.contains('guidelines') ||
      lower.contains('all guidelines with rating sheets') ||
      lower.contains('choose your event') ||
      lower.contains('competitive event operations manual') ||
      lower.contains('competitive event topics') ||
      lower.contains('at-a-glance') ||
      lower.contains('competitive events changes') ||
      lower.contains('competitive events descriptions') ||
      lower.contains('competitive events list') ||
      lower.contains('production test reference') ||
      lower.contains('mba research') ||
      lower.contains('preparation resources') ||
      lower.contains('format guide') ||
      lower.contains('all rating sheets') ||
      lower.startsWith('filter') ||
      name == 'All Competitive Events' ||
      name == 'Chapter Events' ||
      name == 'Objective Tests' ||
      name == 'Presentation Events' ||
      name == 'Production Events' ||
      name == 'Role Play Events';
}

List<Map<String, dynamic>> _parsePage(Document doc, String level) {
  final list = <Map<String, dynamic>>[];
  final cards = doc.querySelectorAll('.fbla-competitive-event-card');

  for (final card in cards) {
    final titleEl = card.querySelector('.fbla-competitive-event-card--title');
    final name = titleEl?.text.trim() ?? '';
    if (name.isEmpty || _isFilterOrResource(name)) continue;

    // Skip resource cards: any element with "category" in class and text "Resource(s)".
    bool isResource = false;
    for (final el in card.querySelectorAll('[class*="category"]')) {
      final t = el.text.trim().toLowerCase();
      if (t == 'resource' || t == 'resources' || t.startsWith('resources ')) {
        isResource = true;
        break;
      }
    }
    if (isResource) continue;

    String description = '';
    String? guidelinesUrl;

    final modal = card.querySelector('.fbla-competitive-events-modal');
    if (modal != null) {
      final descEl = modal.querySelector('.fbla-competitive-events-modal--desc p');
      description = descEl?.text.trim() ?? '';

      final resources = modal.querySelector('.fbla-competitive-events-modal--resources');
      final link = resources?.querySelector('a[href]');
      final href = link?.attributes['href'];
      if (href != null && href.isNotEmpty) {
        guidelinesUrl = href.startsWith('http') ? href : 'https://www.fbla.org$href';
      }
    }

    if (description.isEmpty) {
      description = 'FBLA competitive event. See Event Details & Guidelines for full information.';
    }

    list.add({
      'name': name,
      'description': description,
      'level': level,
      'guidelinesUrl': guidelinesUrl,
    });
  }

  return list;
}
