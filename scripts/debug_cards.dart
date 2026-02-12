// Debug: print structure of first few cards and one that looks like a resource.
// Run from project root: dart run scripts/debug_cards.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  final r = await http.get(
    Uri.parse('https://www.fbla.org/middle-school/competitive-events/'),
    headers: {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'},
  );
  if (r.statusCode != 200) {
    print('Failed: ${r.statusCode}');
    return;
  }
  final doc = html_parser.parse(r.body);
  final cards = doc.querySelectorAll('.fbla-competitive-event-card');
  print('Total cards: ${cards.length}\n');

  for (var i = 0; i < cards.length && i < 5; i++) {
    _dumpCard(cards[i], i, 'first');
  }
  // Find a card whose title contains "NACE" or "Guidelines" (likely resource)
  for (var i = 0; i < cards.length; i++) {
    final title = cards[i].querySelector('.fbla-competitive-event-card--title')?.text.trim() ?? '';
    if (title.contains('NACE') || title.contains('Guidelines') || title.contains('Choose Your Event')) {
      _dumpCard(cards[i], i, 'resource-like');
      break;
    }
  }

  // Also dump raw HTML snippet around "Resources" section
  final body = r.body;
  final idx = body.toLowerCase().indexOf('fbla-competitive-event-card');
  if (idx != -1) {
    final snippet = body.substring(idx, body.length.clamp(0, idx + 800));
    File('scripts/card_snippet.html').writeAsStringSync(snippet);
    print('\nWrote scripts/card_snippet.html (first card HTML)');
  }
}

void _dumpCard(dynamic card, int index, String label) {
  print('=== Card $index ($label) ===');
  final title = card.querySelector('.fbla-competitive-event-card--title')?.text.trim();
  print('Title: $title');

  // All elements with "category" in class
  for (final el in card.querySelectorAll('[class*="category"]')) {
    print('  [class*="category"]: class="${el.attributes['class']}" text="${el.text.trim().replaceAll('\n', ' ')}"');
  }
  // All elements with "type" in class
  for (final el in card.querySelectorAll('[class*="type"]')) {
    print('  [class*="type"]: class="${el.attributes['class']}" text="${el.text.trim().replaceAll('\n', ' ')}"');
  }
  // Direct children
  for (final child in card.children) {
    final tag = child.localName;
    final cls = child.attributes['class'] ?? '';
    final t = child.text.trim().replaceAll(RegExp(r'\s+'), ' ');
final text = t.length > 80 ? t.substring(0, 80) : t;
    print('  child: <$tag class="$cls"> "$text"');
  }
  // Walk parent chain
  var p = card.parent;
  var depth = 0;
  while (p != null && depth < 5) {
    print('  parent$depth: <${p.localName}> id="${p.id}" class="${p.attributes['class']}"');
    p = p.parent;
    depth++;
  }
  print('');
}
