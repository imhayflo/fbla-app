import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';

class NewsSyncService {
  static const String _fblaNewsroomUrl = 'https://www.fbla.org/newsroom/';
  static const int _maxPagesToSync = 3; // Sync first 3 pages of news

  /// Fetches and parses news articles from FBLA newsroom
  Future<List<Announcement>> fetchFBLANews() async {
    final List<Announcement> newsItems = [];

    try {
      // Fetch multiple pages of news
      for (int page = 1; page <= _maxPagesToSync; page++) {
        final url = page == 1
            ? _fblaNewsroomUrl
            : '$_fblaNewsroomUrl/page/$page/';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (compatible; FBLA-Member-App/1.0)',
          },
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final articles = _parseNewsPage(document);
          newsItems.addAll(articles);

          // If we got fewer articles than expected, we've reached the end
          if (articles.length < 10) {
            break;
          }
        } else {
          print('Failed to fetch FBLA news page $page: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching FBLA news: $e');
    }

    return newsItems;
  }

  /// Parses a single newsroom page HTML document
  List<Announcement> _parseNewsPage(Document document) {
    final List<Announcement> articles = [];

    // Find all article entries - they appear to be in a structure with images and content
    // Looking for article containers that have titles, dates, and links
    final articleElements = document.querySelectorAll('article, .post, .entry');

    // If no articles found with those selectors, try finding by structure
    if (articleElements.isEmpty) {
      // Look for h3 tags with links (these are article titles)
      final titleLinks = document.querySelectorAll('h3 a, h3 a[href*="/"]');

      for (final titleLink in titleLinks) {
        try {
          final title = titleLink.text.trim();
          if (title.isEmpty) continue;

          final articleUrl = titleLink.attributes['href'] ?? '';
          if (articleUrl.isEmpty) continue;

          // Find the parent container to get other details
          Element? container = titleLink.parent;
          while (container != null &&
              !container.classes.contains('post') &&
              !container.classes.contains('entry') &&
              container.localName != 'article') {
            container = container.parent;
          }

          if (container == null) {
            // Try to find nearby elements
            container = titleLink.parent;
          }

          // Extract category
          String category = 'National Center News';
          final categoryLink = container?.querySelector('a[href*="/category/"]');
          if (categoryLink != null) {
            category = categoryLink.text.trim();
          }

          // Extract date
          DateTime date = DateTime.now();
          final dateText = container != null 
              ? _extractDateFromContainer(container)
              : null;
          if (dateText != null) {
            date = _parseDate(dateText);
          }

          // Extract author
          String author = 'FBLA National';
          final authorLink = container?.querySelector('a[href*="/author/"]');
          if (authorLink != null) {
            author = authorLink.text.trim();
          } else {
            // Try to find author from gravatar or other indicators
            final authorElement = container?.querySelector('.author, [class*="author"]');
            if (authorElement != null) {
              author = authorElement.text.trim();
            }
          }

          // Extract content/excerpt
          String content = '';
          final excerptElement = container?.querySelector('p, .excerpt, [class*="excerpt"]');
          if (excerptElement != null) {
            content = excerptElement.text.trim();
          } else {
            // Try to find any paragraph near the title
            final paragraphs = container?.querySelectorAll('p');
            if (paragraphs != null && paragraphs.isNotEmpty) {
              content = paragraphs.first.text.trim();
            }
          }

          // Extract image URL
          String? imageUrl;
          final imgElement = container?.querySelector('img[src]');
          if (imgElement != null) {
            imageUrl = imgElement.attributes['src'];
            // Convert relative URLs to absolute
            if (imageUrl != null && !imageUrl.startsWith('http')) {
              imageUrl = 'https://www.fbla.org$imageUrl';
            }
          }

          // Generate a unique ID from the URL
          final id = articleUrl
              .replaceAll('https://www.fbla.org/', '')
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

          // Determine priority based on category
          String priority = 'medium';
          if (category.contains('National Center News')) {
            priority = 'high';
          } else if (category.contains('Spotlight')) {
            priority = 'medium';
          } else {
            priority = 'low';
          }

          articles.add(Announcement(
            id: 'fbla_$id',
            title: title,
            content: content.isNotEmpty ? content : 'Read more on FBLA.org',
            date: date,
            author: author,
            category: category,
            priority: priority,
            externalUrl: articleUrl.startsWith('http')
                ? articleUrl
                : 'https://www.fbla.org$articleUrl',
            imageUrl: imageUrl,
          ));
        } catch (e) {
          print('Error parsing article: $e');
          continue;
        }
      }
    } else {
      // Parse articles found with article/post/entry selectors
      for (final article in articleElements) {
        try {
          final titleLink = article.querySelector('h3 a, h2 a, h1 a, .entry-title a');
          if (titleLink == null) continue;

          final title = titleLink.text.trim();
          final articleUrl = titleLink.attributes['href'] ?? '';

          if (title.isEmpty || articleUrl.isEmpty) continue;

          // Extract other details
          String category = 'National Center News';
          final categoryLink = article.querySelector('a[href*="/category/"]');
          if (categoryLink != null) {
            category = categoryLink.text.trim();
          }

          DateTime date = DateTime.now();
          final dateText = _extractDateFromContainer(article);
          if (dateText != null) {
            date = _parseDate(dateText);
          }

          String author = 'FBLA National';
          final authorLink = article.querySelector('a[href*="/author/"]');
          if (authorLink != null) {
            author = authorLink.text.trim();
          }

          String content = '';
          final excerptElement = article.querySelector('p, .excerpt');
          if (excerptElement != null) {
            content = excerptElement.text.trim();
          }

          String? imageUrl;
          final imgElement = article.querySelector('img[src]');
          if (imgElement != null) {
            imageUrl = imgElement.attributes['src'];
            if (imageUrl != null && !imageUrl.startsWith('http')) {
              imageUrl = 'https://www.fbla.org$imageUrl';
            }
          }

          final id = articleUrl
              .replaceAll('https://www.fbla.org/', '')
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

          String priority = 'medium';
          if (category.contains('National Center News')) {
            priority = 'high';
          }

          articles.add(Announcement(
            id: 'fbla_$id',
            title: title,
            content: content.isNotEmpty ? content : 'Read more on FBLA.org',
            date: date,
            author: author,
            category: category,
            priority: priority,
            externalUrl: articleUrl.startsWith('http')
                ? articleUrl
                : 'https://www.fbla.org$articleUrl',
            imageUrl: imageUrl,
          ));
        } catch (e) {
          print('Error parsing article: $e');
          continue;
        }
      }
    }

    return articles;
  }

  /// Extracts date text from a container element
  String? _extractDateFromContainer(Element container) {
    // Try various date selectors
    final dateSelectors = [
      'time[datetime]',
      '.date',
      '[class*="date"]',
      'a[href*="/202"]', // Links often contain dates
    ];

    for (final selector in dateSelectors) {
      final element = container.querySelector(selector);
      if (element != null) {
        final dateText = element.text.trim();
        if (dateText.isNotEmpty) {
          return dateText;
        }
        // Check datetime attribute
        final datetime = element.attributes['datetime'];
        if (datetime != null && datetime.isNotEmpty) {
          return datetime;
        }
      }
    }

    // Try to find date in text content (look for patterns like "January 13, 2026")
    final text = container.text;
    final datePattern = RegExp(r'[A-Za-z]+\s+\d{1,2},\s+\d{4}');
    final match = datePattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Parses a date string into a DateTime object
  DateTime _parseDate(String dateText) {
    try {
      // Try common date formats
      final formats = [
        DateFormat('MMMM d, yyyy'),
        DateFormat('MMM d, yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('MM/dd/yyyy'),
      ];

      for (final format in formats) {
        try {
          return format.parse(dateText);
        } catch (e) {
          continue;
        }
      }

      // Try ISO format
      return DateTime.parse(dateText);
    } catch (e) {
      print('Error parsing date: $dateText - $e');
      return DateTime.now();
    }
  }
}
