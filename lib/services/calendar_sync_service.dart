import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/event.dart';

/// Scrapes FBLA calendar events from paginated list pages:
/// https://www.fbla.org/events/list/?tribe-bar-date=2026-01-01
/// Handles pagination by changing the date parameter
class CalendarSyncService {
  static final _headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Fetches all calendar events from FBLA by iterating through pages
  Future<List<Event>> fetchUpcomingFBLCalendar() async {
    final List<Event> allEvents = [];
    final seenIds = <String>{};
    
    final currentYear = DateTime.now().year;
    
    // Iterate through each month
    for (int month = 1; month <= 12; month++) {
      final dateStr = '$currentYear-${month.toString().padLeft(2, '0')}-01';
      final url = 'https://www.fbla.org/events/list/?tribe-bar-date=$dateStr';
      
      print('Fetching events for $dateStr...');
      
      try {
        // Add timeout for each request - max 5 seconds per month
        final response = await http.get(Uri.parse(url), headers: _headers).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Request timed out for $dateStr');
            return http.Response('Timeout', 408);
          },
        );
        
        // Skip processing if request timed out
        if (response.statusCode == 408) {
          print('Skipping $dateStr due to timeout');
          continue;
        }
        
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final events = _parsePage(document);
          
          print('Found ${events.length} events for $dateStr');
          
          for (final event in events) {
            // Only add if not seen before
            if (!seenIds.contains(event.id)) {
              seenIds.add(event.id);
              allEvents.add(event);
            }
          }
        } else {
          print('Failed to fetch $url: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching $url: $e');
      }
    }

    print('Total unique events fetched: ${allEvents.length}');
    return allEvents;
  }

  /// Parses a single page and extracts all events
  List<Event> _parsePage(Document document) {
    final List<Event> events = [];
    
    // Try various selectors for event items
    final selectors = [
      '.tribe-events-list-event',
      '.tribe-events-calendar-list-event', 
      '.type-tribe_events',
      '.tribe-event',
      '.tribe-events-item',
      '.tribe-events-list .tribe-events-event',
      '[class*="tribe-events-event"]',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        print('Found ${elements.length} events with selector: $selector');
        for (final element in elements) {
          final event = _parseEventElement(element);
          if (event != null) {
            events.add(event);
          }
        }
        if (events.isNotEmpty) break;
      }
    }
    
    return events;
  }

  /// Parses a single event element
  Event? _parseEventElement(Element element) {
    try {
      // Get title - try multiple selectors
      String? title;
      final titleSelectors = [
        '.tribe-events-list-event-title',
        '.tribe-events-calendar-list-event-title', 
        '.tribe-event-title',
        '.event-title',
        'h2', 'h3',
        '.tribe-events-event-title',
        '.tribe-events-title',
      ];
      
      for (final selector in titleSelectors) {
        final el = element.querySelector(selector);
        if (el != null && el.text.trim().isNotEmpty) {
          title = el.text.trim();
          break;
        }
      }
      
      // Try getting title from link inside
      if (title == null || title.isEmpty) {
        final link = element.querySelector('a[href]');
        title = link?.text.trim();
      }
      
      if (title == null || title.isEmpty || title.length < 3) return null;
      
      // Clean up title
      title = title.split('\n').first.trim();
      
      // Get start and end dates
      DateTime? startDate;
      DateTime? endDate;
      
      // Try to find date information
      final dateSelectors = [
        '.tribe-events-list-event-date',
        '.tribe-events-calendar-list-event-date',
        '.tribe-event-date',
        '.event-date',
        '.tribe-events-event-date',
        '.date',
        'time',
      ];
      
      for (final selector in dateSelectors) {
        final el = element.querySelector(selector);
        if (el != null && el.text.trim().isNotEmpty) {
          final dateText = el.text.trim();
          final parsed = _extractDateRange(dateText);
          if (parsed.$1 != null) {
            startDate = parsed.$1;
            endDate = parsed.$2;
            break;
          }
        }
        
        // Check datetime attribute
        if (selector == 'time') {
          final timeEl = element.querySelector(selector);
          final datetime = timeEl?.attributes['datetime'];
          if (datetime != null) {
            final dt = DateTime.tryParse(datetime);
            if (dt != null) {
              startDate = dt;
              break;
            }
          }
        }
      }
      
      // Default to current date if no date found
      startDate ??= DateTime.now();
      
      // Get description
      String description = '';
      final descSelectors = [
        '.tribe-events-list-event-description',
        '.tribe-events-event-description',
        '.tribe-events-calendar-list-event-description',
        '.event-description',
        '.entry-content',
      ];
      
      for (final selector in descSelectors) {
        final el = element.querySelector(selector);
        if (el != null && el.text.trim().isNotEmpty) {
          description = el.text.trim();
          break;
        }
      }
      
      // Get event link
      String? link;
      final linkEl = element.querySelector('a[href]');
      if (linkEl != null) {
        link = linkEl.attributes['href'];
      }
      
      // Get event type
      String type = 'FBLA Event';
      final typeSelectors = [
        '.tribe-events-event-category',
        '.tribe-event-category',
        '.event-category',
      ];
      
      for (final selector in typeSelectors) {
        final el = element.querySelector(selector);
        if (el != null && el.text.trim().isNotEmpty) {
          type = el.text.trim();
          break;
        }
      }
      
      return Event(
        id: 'fbla_${title.hashCode.abs()}',
        title: title,
        description: description,
        date: startDate,
        endDate: endDate,
        location: '',
        type: type,
        link: link,
      );
    } catch (e) {
      return null;
    }
  }

  /// Extracts start and end dates from date text
  (DateTime?, DateTime?) _extractDateRange(String dateText) {
    if (dateText.isEmpty) return (null, null);
    
    final currentYear = DateTime.now().year;
    
    // Try various date range patterns
    // Pattern: "January 15 - January 20, 2026" or "Jan 15 - 20, 2026"
    final rangePattern1 = RegExp(r'(\w+)\s+(\d+)\s*[-–]\s*(\w+)\s+(\d+),?\s*(\d{4})?');
    final match1 = rangePattern1.firstMatch(dateText);
    if (match1 != null) {
      try {
        final startMonthName = match1.group(1)!;
        final startDay = int.parse(match1.group(2)!);
        final endMonthName = match1.group(3)!;
        final endDay = int.parse(match1.group(4)!);
        
        int startMonth = _monthToNumber(startMonthName) ?? 1;
        int endMonth = _monthToNumber(endMonthName) ?? startMonth;
        int year = currentYear;
        
        if (match1.group(5) != null) {
          year = int.tryParse(match1.group(5)!) ?? currentYear;
        }
        
        return (
          DateTime(year, startMonth, startDay),
          DateTime(year, endMonth, endDay)
        );
      } catch (e) {
        // Continue to next pattern
      }
    }
    
    // Pattern: "January 15, 2026"
    final singlePattern = RegExp(r'(\w+)\s+(\d+),?\s*(\d{4})?');
    final match2 = singlePattern.firstMatch(dateText);
    if (match2 != null) {
      try {
        final monthName = match2.group(1)!;
        final day = int.parse(match2.group(2)!);
        final month = _monthToNumber(monthName);
        
        if (month != null) {
          int year = currentYear;
          if (match2.group(3) != null) {
            year = int.tryParse(match2.group(3)!) ?? currentYear;
          }
          return (DateTime(year, month, day), null);
        }
      } catch (e) {
        // Continue
      }
    }
    
    return (null, null);
  }

  int? _monthToNumber(String monthName) {
    final months = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };
    return months[monthName.toLowerCase()];
  }
}
