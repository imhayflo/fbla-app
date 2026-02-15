import 'package:flutter/material.dart';
import 'package:fbla_member_app/models/member.dart';
import 'package:fbla_member_app/models/social_config.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'package:fbla_member_app/services/social_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SocialService _socialService = SocialService();
  SocialConfig? _socialConfig;

  @override
  void initState() {
    super.initState();
    _loadSocialConfig();
  }

  Future<void> _loadSocialConfig() async {
    final config = await _dbService.getSocialConfig();
    if (mounted) setState(() => _socialConfig = config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShareAchievementsCard(
              socialService: _socialService,
              dbService: _dbService,
            ),
            const SizedBox(height: 24),
            Text(
              'FBLA on Instagram',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Member?>(
              stream: _dbService.memberStream,
              builder: (context, snapshot) {
                final member = snapshot.data;
                final nationalHandle =
                    _socialConfig?.nationalInstagramHandle ?? 'fbla_national';
                final nationalUrl = _socialConfig?.nationalInstagramUrl;
                final stateKey =
                    (member?.state ?? '').trim().toUpperCase();
                final stateHandle = (stateKey.isNotEmpty &&
                        (_socialConfig?.stateInstagramHandles.containsKey(stateKey) ?? false))
                    ? _socialConfig?.stateInstagramHandles[stateKey]
                    : _socialConfig?.defaultStateInstagramHandle;
                final chapterHandle = member?.chapterInstagramHandle ?? '';

                return Column(
                  children: [
                    _SocialTile(
                      title: 'National FBLA',
                      handle: nationalHandle,
                      icon: Icons.flag,
                      onPressed: () =>
                          _socialService.openInstagramProfile(
                        url: nationalUrl,
                        handle: nationalHandle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SocialTile(
                      title: 'Your State FBLA',
                      handle: stateHandle ?? _socialConfig?.defaultStateInstagramHandle,
                      icon: Icons.map,
                      onPressed: () =>
                          _socialService.openInstagramProfile(
                        handle: stateHandle ?? _socialConfig?.defaultStateInstagramHandle,
                      ),
                    ),
                    if (chapterHandle.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SocialTile(
                        title: 'Your Chapter',
                        handle: chapterHandle,
                        icon: Icons.groups,
                        onPressed: () =>
                            _socialService.openInstagramProfile(
                          handle: chapterHandle,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'FBLA on LinkedIn',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with FBLA on LinkedIn for career and networking.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            _SocialTile(
              title: 'National FBLA',
              handle: 'Future Business Leaders of America',
              icon: Icons.business_center,
              onPressed: () => _socialService.openLinkedInProfile(
                url: _socialConfig?.nationalLinkedInUrl ?? 'https://www.linkedin.com/company/future-business-leaders-america',
                handle: 'future-business-leaders-america',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FBLA on Facebook',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Like and follow FBLA on Facebook for updates and events.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            _SocialTile(
              title: 'National FBLA',
              handle: 'FutureBusinessLeaders',
              icon: Icons.thumb_up,
              onPressed: () => _socialService.openUrl(
                _socialConfig?.nationalFacebookUrl ??
                    'https://www.facebook.com/FutureBusinessLeaders',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Featured Posts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<FeaturedInstagramPost>>(
              stream: _dbService.featuredInstagramPostsStream,
              builder: (context, snapshot) {
                final posts = snapshot.data ?? [];
                return Column(
                  children: posts
                      .map((post) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12),
                            child: _FeaturedPostCard(
                              post: post,
                              socialService: _socialService,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareAchievementsCard extends StatelessWidget {
  const _ShareAchievementsCard({
    required this.socialService,
    required this.dbService,
  });

  final SocialService socialService;
  final DatabaseService dbService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share your achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Post your FBLA achievements to Instagram, Twitter, or any app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Member?>(
              stream: dbService.memberStream,
              builder: (context, snapshot) {
                final member = snapshot.data;
                final achievements = member?.achievements ?? [];
                if (achievements.isEmpty) {
                  return FilledButton.icon(
                    onPressed: () {
                      if (member != null) {
                        socialService.shareProfile(member);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Load your profile to share.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share that you\'re in FBLA'),
                  );
                }
                return FilledButton.icon(
                  onPressed: () => socialService.shareAchievement(
                    achievements.first,
                    memberName: member?.name,
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share latest achievement'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.title,
    required this.handle,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String? handle;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final h = (handle ?? '').trim();
    final display =
        h.isEmpty ? 'Instagram' : (h.startsWith('@') ? h : '@$h');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(display),
        trailing: FilledButton.tonal(
          onPressed: onPressed,
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _FeaturedPostCard extends StatelessWidget {
  const _FeaturedPostCard({
    required this.post,
    required this.socialService,
  });

  final FeaturedInstagramPost post;
  final SocialService socialService;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(post.caption ?? post.url),
        trailing: const Icon(Icons.open_in_new),
        onTap: () =>
            socialService.openInstagramPostUrl(post.url),
      ),
    );
  }
}
