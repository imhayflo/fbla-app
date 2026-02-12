import 'package:cloud_firestore/cloud_firestore.dart';

/// Server-driven config for social/Instagram: national handle, state→handle map,
/// and optional featured post URLs to display (curated from National/State/Chapter).
class SocialConfig {
  /// National FBLA Instagram username (https://www.instagram.com/fbla_national/).
  final String nationalInstagramHandle;
  /// Map of state code/name → Instagram username (e.g. "CA" → "californiafbla").
  final Map<String, String> stateInstagramHandles;
  /// Default state handle when state is not in the map.
  final String defaultStateInstagramHandle;

  const SocialConfig({
    this.nationalInstagramHandle = 'fbla_national',
    this.stateInstagramHandles = const {},
    this.defaultStateInstagramHandle = 'fbla_national',
  });

  factory SocialConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const SocialConfig();
    final stateMap = data['stateInstagramHandles'];
    Map<String, String> stateHandles = {};
    if (stateMap is Map) {
      for (final e in stateMap.entries) {
        if (e.key != null && e.value != null) {
          stateHandles['${e.key}'] = '${e.value}';
        }
      }
    }
    return SocialConfig(
      nationalInstagramHandle: data['nationalInstagramHandle'] as String? ?? 'fbla_national',
      stateInstagramHandles: stateHandles,
      defaultStateInstagramHandle:
          data['defaultStateInstagramHandle'] as String? ?? 'fbla_national',
    );
  }
}

/// A featured Instagram post (URL stored in Firestore; admins can add from National/State/Chapter).
class FeaturedInstagramPost {
  final String id;
  final String url;
  final String source; // 'national' | 'state' | 'chapter'
  final String? caption;
  final int order;
  final DateTime? addedAt;

  FeaturedInstagramPost({
    required this.id,
    required this.url,
    required this.source,
    this.caption,
    this.order = 0,
    this.addedAt,
  });

  factory FeaturedInstagramPost.fromFirestore(
      DocumentSnapshot doc, Map<String, dynamic>? data) {
    final d = data ?? doc.data() as Map<String, dynamic>? ?? {};
    return FeaturedInstagramPost(
      id: doc.id,
      url: d['url'] as String? ?? '',
      source: d['source'] as String? ?? 'national',
      caption: d['caption'] as String?,
      order: (d['order'] as num?)?.toInt() ?? 0,
      addedAt: (d['addedAt'] as Timestamp?)?.toDate(),
    );
  }
}
