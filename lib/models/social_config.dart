import 'package:cloud_firestore/cloud_firestore.dart';

class SocialConfig {
  final String nationalInstagramHandle;
  final String? nationalInstagramUrl;
  final Map<String, String> stateInstagramHandles;
  final String defaultStateInstagramHandle;
  final String? defaultStateInstagramUrl;
  final String? nationalLinkedInUrl;
  final String? nationalFacebookUrl;

  const SocialConfig({
    this.nationalInstagramHandle = 'fbla_national',
    this.nationalInstagramUrl,
    this.stateInstagramHandles = const {},
    this.defaultStateInstagramHandle = 'fbla_national',
    this.defaultStateInstagramUrl,
    this.nationalLinkedInUrl,
    this.nationalFacebookUrl,
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
      nationalInstagramUrl: data['nationalInstagramUrl'] as String?,
      stateInstagramHandles: stateHandles,
      defaultStateInstagramHandle:
          data['defaultStateInstagramHandle'] as String? ?? 'fbla_national',
      defaultStateInstagramUrl: data['defaultStateInstagramUrl'] as String?,
      nationalLinkedInUrl: data['nationalLinkedInUrl'] as String?,
      nationalFacebookUrl: data['nationalFacebookUrl'] as String?,
    );
  }
}

class FeaturedInstagramPost {
  final String id;
  final String url;
  final String source;
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
