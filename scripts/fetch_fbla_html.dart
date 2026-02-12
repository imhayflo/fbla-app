// Standalone script to inspect FBLA page HTML (no Flutter/Firebase deps).
// The app uses CompetitionsSyncService which parses .fbla-competitive-event-card
// and extracts description + Event Details & Guidelines link per event.
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  final r = await http.get(
    Uri.parse('https://www.fbla.org/high-school/competitive-events/'),
    headers: {'User-Agent': 'Mozilla/5.0'},
  );
  final doc = html_parser.parse(r.body);
  final cards = doc.querySelectorAll('.fbla-competitive-event-card');
  print('High School event cards: ${cards.length}');
  if (cards.isNotEmpty) {
    final card = cards.first;
    final title = card.querySelector('.fbla-competitive-event-card--title')?.text.trim();
    final modal = card.querySelector('.fbla-competitive-events-modal');
    final desc = modal?.querySelector('.fbla-competitive-events-modal--desc p')?.text.trim();
    final link = modal?.querySelector('.fbla-competitive-events-modal--resources a[href]');
    final href = link?.attributes['href'];
    print('Example: $title');
    print('  description: ${desc?.substring(0, desc.length > 60 ? 60 : desc.length)}...');
    print('  guidelinesUrl: $href');
  }
}
