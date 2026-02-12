import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/competition.dart';

/// Scrapes FBLA competitive events from the official high school and middle
/// school pages. For each event we store description and the "Event Details &
/// Guidelines" PDF link (test competencies), which is the first link in the
/// modal opened by "Event Details & Guidelines".
///
/// Official competition lists (for reference):
/// - High School: 25-26 High School CE At-A-Glance (S3/Connect)
/// - Middle School: https://www.fbla.org/media/2025/08/25-26-MS-CE-List.pdf
class CompetitionsSyncService {
  /// High school competitive events (same content as with #fbla-ce-resources).
  static const String _highSchoolUrl =
      'https://www.fbla.org/high-school/competitive-events/';
  static const String _middleSchoolUrl =
      'https://www.fbla.org/middle-school/competitive-events/';

  static final _headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Fetches competitive events from both High School and Middle School FBLA pages.
  /// For each event: name, description, category, level, and the Event Details &
  /// Guidelines link (PDF that includes test competencies for objective tests).
  Future<List<Competition>> fetchFBLACompetitions() async {
    final List<Competition> allCompetitions = [];
    final seenIds = <String>{};

    for (final url in [_highSchoolUrl, _middleSchoolUrl]) {
      try {
        final response = await http.get(Uri.parse(url), headers: _headers);

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final level = url.contains('middle-school')
              ? 'Middle School'
              : 'High School';
          final events = _parseCompetitionsPage(document, level);

          for (final comp in events) {
            if (!seenIds.contains(comp.id)) {
              seenIds.add(comp.id);
              allCompetitions.add(comp);
            }
          }
        } else {
          print(
              'Failed to fetch competitions from $url: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching competitions from $url: $e');
      }
    }

    return allCompetitions;
  }

  /// Parses the FBLA competitive events page: event cards with hidden modals
  /// containing description and "Event Details & Guidelines" (PDF) link.
  List<Competition> _parseCompetitionsPage(Document document, String level) {
    final List<Competition> competitions = [];

    final cards = document.querySelectorAll('.fbla-competitive-event-card');

    for (final card in cards) {
      try {
        final comp = _parseEventCard(card, level);
        if (comp != null) competitions.add(comp);
      } catch (e) {
        continue;
      }
    }

    return competitions;
  }

  Competition? _parseEventCard(Element card, String level) {
    final titleEl = card.querySelector('.fbla-competitive-event-card--title');
    final name = titleEl?.text.trim() ?? '';
    if (name.isEmpty || _isResourceOrFilter(name)) return null;

    String description = '';
    String? guidelinesUrl;

    final modal = card.querySelector('.fbla-competitive-events-modal');
    if (modal != null) {
      final descEl = modal.querySelector('.fbla-competitive-events-modal--desc p');
      description = descEl?.text.trim() ?? '';

      // First link in resources is "Event Details & Guidelines" → test competencies PDF.
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

    // Only add real competitions. Resource cards have category text "Resources".
    // Check every element with "category" in class (card uses --category, modal uses --category too).
    final categoryEls = card.querySelectorAll('[class*="category"]');
    String categoryText = '';
    for (final el in categoryEls) {
      final t = el.text.trim();
      final lower = t.toLowerCase();
      if (lower == 'resource' || lower == 'resources' || lower.startsWith('resources ')) {
        return null; // This card is a resource, not a competition.
      }
      // Use the card's category (not the modal's) for display — prefer --card--category.
      if (categoryText.isEmpty && (el.attributes['class'] ?? '').contains('fbla-competitive-event-card')) {
        categoryText = t;
      }
    }
    if (categoryText.isEmpty) {
      final categoryEl = card.querySelector('.fbla-competitive-event-card--category') ??
          card.querySelector('.fbla-competitive-event-card-category');
      categoryText = categoryEl?.text.trim() ?? '';
    }
    final category = _inferCategoryFromEventType(categoryText);

    final maxTeamSize = categoryText.toLowerCase().contains('team') ? 3 : 1;
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
      guidelinesUrl: guidelinesUrl,
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
        text == 'All Competitive Events' ||
        text == 'Chapter Events' ||
        text == 'Objective Tests' ||
        text == 'Presentation Events' ||
        text == 'Production Events' ||
        text == 'Role Play Events';
  }

  String _inferCategoryFromEventType(String eventType) {
    final t = eventType.toLowerCase();
    if (t.contains('objective test')) return 'Objective Tests';
    if (t.contains('presentation')) return 'Presentation Events';
    if (t.contains('role play')) return 'Role Play Events';
    if (t.contains('production')) return 'Production Events';
    if (t.contains('chapter')) return 'Chapter Events';
    return 'Objective Tests'; // Default to Objective Tests for unrecognized types
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
