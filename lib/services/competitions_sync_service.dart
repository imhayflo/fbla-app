import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/competition.dart';

class CompetitionsSyncService {
  static const String _highSchoolUrl =
      'https://www.fbla.org/high-school/competitive-events/';
  static const String _middleSchoolUrl =
      'https://www.fbla.org/middle-school/competitive-events/';

  /// Fetches competitive events from both High School and Middle School pages
  Future<List<Competition>> fetchFBLACompetitions() async {
    final List<Competition> allCompetitions = [];
    final seenIds = <String>{};

    for (final url in [_highSchoolUrl, _middleSchoolUrl]) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; FBLA-Member-App/1.0)',
          },
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final level = url.contains('middle-school') ? 'Middle School' : 'High School';
          final events = _parseCompetitionsPage(document, level);

          for (final comp in events) {
            if (!seenIds.contains(comp.id)) {
              seenIds.add(comp.id);
              allCompetitions.add(comp);
            }
          }
        } else {
          print('Failed to fetch competitions from $url: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching competitions from $url: $e');
      }
    }

    return allCompetitions;
  }

  List<Competition> _parseCompetitionsPage(Document document, String level) {
    final List<Competition> competitions = [];

    // Look for event cards - FBLA typically uses cards or list items
    final cards = document.querySelectorAll(
      '.fbla-ce-card, .competitive-event, .ce-card, [class*="competitive"], [class*="ce-"]',
    );

    if (cards.isNotEmpty) {
      for (final card in cards) {
        try {
          final comp = _parseCompetitionCard(card, level);
          if (comp != null) competitions.add(comp);
        } catch (e) {
          continue;
        }
      }
    }

    // Fallback: look for structured content with h3/h4 + description pattern
    if (competitions.isEmpty) {
      final headings = document.querySelectorAll('h3, h4');
      for (final heading in headings) {
        try {
          final text = heading.text.trim();
          if (text.isEmpty || text.length > 100) continue;
          if (_isResourceOrFilter(text)) continue;

          // Get description from next sibling or parent's paragraphs
          String description = '';
          Element? next = heading.nextElementSibling;
          int attempts = 0;
          while (next != null && attempts < 5) {
            if (next.localName == 'p') {
              description = next.text.trim();
              if (description.length > 50) break;
            }
            next = next.nextElementSibling;
            attempts++;
          }

          if (description.isEmpty) {
            final parent = heading.parent;
            if (parent != null) {
              final p = parent.querySelector('p');
              if (p != null) description = p.text.trim();
            }
          }

          // Determine category from event type (check for Event Type line)
          String category = _inferCategory(text);
          String eventType = 'Competition';

          // Look for Event Type in nearby text
          final parentText = heading.parent?.text ?? '';
          if (parentText.contains('Objective Tests')) {
            eventType = 'Objective Tests';
            category = category.isEmpty ? 'Academic' : category;
          } else if (parentText.contains('Presentation')) {
            eventType = 'Presentation';
            category = category.isEmpty ? 'Leadership' : category;
          } else if (parentText.contains('Role Play')) {
            eventType = 'Role Play';
            category = category.isEmpty ? 'Business' : category;
          } else if (parentText.contains('Production')) {
            eventType = 'Production';
            category = category.isEmpty ? 'Technology' : category;
          } else if (parentText.contains('Chapter Events')) {
            eventType = 'Chapter';
            category = category.isEmpty ? 'Leadership' : category;
          }

          if (category.isEmpty) category = 'General';

          final maxTeamSize = parentText.contains('Team') ? 3 : 1;
          final id = _generateId(text, level);

          competitions.add(Competition(
            id: id,
            name: text,
            category: category,
            description: description.isNotEmpty ? description : 'FBLA competitive event. See FBLA.org for details.',
            level: level,
            date: DateTime(DateTime.now().year, 6, 1), // NLC season placeholder
            maxTeamSize: maxTeamSize,
            registeredCount: 0,
          ));
        } catch (e) {
          continue;
        }
      }
    }

    // Alternative: parse from cards/containers with data attributes or specific structure
    if (competitions.isEmpty) {
      // Look for elements that have both a title and description - common card pattern
      final potentialCards = document.querySelectorAll(
        'div[class*="card"], div[class*="event"], article, .entry, .post',
      );
      for (final card in potentialCards) {
        final titleEl = card.querySelector('h3, h4, h5, .event-title, [class*="title"]');
        final name = titleEl?.text.trim() ?? '';
        if (name.isEmpty || name.length > 100 || _isResourceOrFilter(name)) continue;

        final descEl = card.querySelector('p');
        final description = descEl?.text.trim() ?? '';
        final fullText = card.text;
        final category = _inferCategoryFromText(fullText);
        final maxTeamSize = fullText.contains('Team') ? 3 : 1;
        final id = _generateId(name, level);
        if (competitions.any((c) => c.id == id)) continue;

        competitions.add(Competition(
          id: id,
          name: name,
          category: category,
          description: description.length > 30 ? description : 'FBLA competitive event. Visit FBLA.org for full guidelines.',
          level: level,
          date: DateTime(DateTime.now().year, 6, 1),
          maxTeamSize: maxTeamSize,
          registeredCount: 0,
        ));
      }
    }

    // Last resort: regex-based extraction from body text
    if (competitions.isEmpty) {
      final bodyText = document.body?.innerHtml ?? '';
      final eventPattern = RegExp(
        r'<h[34][^>]*>([^<]+)</h[34]>',
        caseSensitive: false,
      );
      final matches = eventPattern.allMatches(bodyText);
      final seen = <String>{};
      for (final m in matches) {
        final name = m.group(1)?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
        if (name.isEmpty || name.length > 80 || name.length < 3) continue;
        if (_isResourceOrFilter(name)) continue;
        // Exclude section headers (Resources, Announcements, etc.)
        if (name.contains('2025') || name.contains('Resources') || name.contains('Guidelines')) continue;
        if (seen.contains(name)) continue;
        seen.add(name);

        final id = _generateId(name, level);
        competitions.add(Competition(
          id: id,
          name: name,
          category: _inferCategory(name),
          description: 'FBLA competitive event. Visit FBLA.org for full guidelines and details.',
          level: level,
          date: DateTime(DateTime.now().year, 6, 1),
          maxTeamSize: 1,
          registeredCount: 0,
        ));
      }
    }

    return competitions;
  }

  Competition? _parseCompetitionCard(Element card, String level) {
    final titleEl = card.querySelector('h3, h4, .title, [class*="title"]');
    final name = titleEl?.text.trim() ?? '';
    if (name.isEmpty) return null;

    final descEl = card.querySelector('p, .description, [class*="desc"]');
    final description = descEl?.text.trim() ?? 'FBLA competitive event. See FBLA.org for details.';

    final fullText = card.text;
    String category = 'General';
    if (fullText.contains('Objective Tests')) category = 'Academic';
    else if (fullText.contains('Presentation')) category = 'Leadership';
    else if (fullText.contains('Role Play')) category = 'Business';
    else if (fullText.contains('Production')) category = 'Technology';
    else if (fullText.contains('Chapter')) category = 'Leadership';

    final maxTeamSize = fullText.contains('Team') ? 3 : 1;
    final id = _generateId(name, level);

    return Competition(
      id: id,
      name: name,
      category: category,
      description: description,
      level: level,
      date: DateTime(DateTime.now().year, 6, 1),
      maxTeamSize: maxTeamSize,
      registeredCount: 0,
    );
  }

  bool _isResourceOrFilter(String text) {
    final lower = text.toLowerCase();
    return lower.contains('resources') ||
        lower.contains('clear filters') ||
        lower.contains('event category') ||
        lower.contains('event type') ||
        lower.contains('career cluster') ||
        lower.contains('nace competency') ||
        lower.contains('announcements') ||
        lower.contains('view resources') ||
        lower.contains('upcoming national') ||
        lower.contains('guidelines') ||
        lower.startsWith('filter');
  }

  String _inferCategoryFromText(String text) {
    final t = text.toLowerCase();
    if (t.contains('objective tests')) return 'Academic';
    if (t.contains('presentation')) return 'Leadership';
    if (t.contains('role play')) return 'Business';
    if (t.contains('production')) return 'Technology';
    if (t.contains('chapter events')) return 'Leadership';
    return _inferCategory(text);
  }

  String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('accounting') || n.contains('finance') || n.contains('economics') ||
        n.contains('banking') || n.contains('insurance')) return 'Business';
    if (n.contains('coding') || n.contains('programming') || n.contains('computer') ||
        n.contains('cyber') || n.contains('data') || n.contains('digital') ||
        n.contains('technology') || n.contains('animation') || n.contains('website')) return 'Technology';
    if (n.contains('leadership') || n.contains('management') || n.contains('parliamentary') ||
        n.contains('speaking') || n.contains('interview') || n.contains('ethics')) return 'Leadership';
    if (n.contains('marketing') || n.contains('advertising') || n.contains('retail')) return 'Business';
    if (n.contains('journalism') || n.contains('broadcast') || n.contains('communication')) return 'Leadership';
    return 'General';
  }

  String _generateId(String name, String level) {
    final safe = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final levelPrefix = level == 'High School' ? 'hs' : 'ms';
    return 'fbla_${levelPrefix}_$safe';
  }
}
