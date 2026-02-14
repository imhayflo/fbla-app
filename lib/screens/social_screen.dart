import 'package:flutter/material.dart';
import 'package:fbla_member_app/models/member.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'package:fbla_member_app/services/social_service.dart';
import 'package:fbla_member_app/models/social_config.dart';


class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SocialService _socialService = SocialService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share achievements card
            _ShareAchievementsCard(
              socialService: _socialService,
              dbService: _dbService,
            ),
            const SizedBox(height: 24),

            // Instagram feeds section
            Text(
              'FBLA on Instagram',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow and view posts from National, your state, and your chapter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<Member?>(
              stream: _dbService.memberStream,
              builder: (context, memberSnapshot) {
                final member = memberSnapshot.data;

                // Chapter IG: prefer URL if you add it later; fall back to handle -> build URL.
                final chapterUrl = _resolveChapterInstagramUrl(member);

                return Column(
                  children: [
                    _InstagramProfileTile(
                      title: 'National FBLA',
                      subtitle: 'Official national FBLA',
                      subtitleLine: '@fbla_national',
                      icon: Icons.flag,
                      onPressed: () => _socialService.openNationalInstagram(),
                    ),
                    const SizedBox(height: 12),
                    _InstagramProfileTile(
                      title: 'Your State FBLA',
                      subtitle: member?.state != null && member!.state.isNotEmpty
                          ? '${member.state} FBLA'
                          : 'State FBLA',
                      subtitleLine: _stateSubtitleLine(member?.state),
                      icon: Icons.map,
                      onPressed: () => _socialService.openStateInstagram(
                        member?.state,
                      ),
                    ),
                    if (chapterUrl != null && chapterUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InstagramProfileTile(
                        title: 'Your Chapter',
                        subtitle: member?.chapter ?? 'Chapter',
                        subtitleLine: _chapterSubtitleLine(member),
                        icon: Icons.groups,
                        onPressed: () =>
                            _socialService.openChapterInstagramUrl(chapterUrl),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Featured posts (still curated from Firestore)
            Text(
              'Featured Posts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recent posts from National, State, and Chapter FBLA accounts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<FeaturedInstagramPost>>(
              stream: _dbService.featuredInstagramPostsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 48,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No featured posts yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Admins can add Instagram post URLs to show here.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: posts
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FeaturedPostCard(
                            post: post,
                            socialService: _socialService,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveChapterInstagramUrl(Member? member) {
    // If you later add member.chapterInstagramUrl, check it here first.
    // For now, keep compatibility with chapterInstagramHandle:
    final handle = (member?.chapterInstagramHandle ?? '').trim();
    if (handle.isEmpty) return null;
    final clean = handle.replaceFirst(RegExp(r'^@'), '');
    if (clean.isEmpty) return null;
    return 'https://www.instagram.com/$clean/';
  }

  String _stateSubtitleLine(String? state) {
    // We don’t know the exact state handle when using hardcoded URLs,
    // so show a generic label. If you want, you can add a map of state->handle
    // and display it here.
    final s = (state ?? '').trim();
    if (s.isEmpty) return 'State FBLA Instagram';
    return '$s FBLA Instagram';
  }

  String _chapterSubtitleLine(Member? member) {
    final handle = (member?.chapterInstagramHandle ?? '').trim();
    if (handle.isEmpty) return 'Chapter Instagram';
    return handle.startsWith('@') ? handle : '@$handle';
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
                Icon(
                  Icons.share,
                  color: colorScheme.primary,
                  size: 28,
                ),
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
              'Post your FBLA achievements directly to Instagram, Twitter, or any app using Share.',
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
                          const SnackBar(
                            content: Text('Load your profile to share.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share that you\'re in FBLA'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Latest achievement:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AchievementShareTile(
                      achievement: achievements.first,
                      memberName: member?.name,
                      socialService: socialService,
                    ),
                    if (achievements.length > 1) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showAchievementPicker(
                          context,
                          achievements,
                          member?.name,
                          socialService,
                        ),
                        icon: const Icon(Icons.more_horiz),
                        label: const Text('Share another achievement'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showAchievementPicker(
    BuildContext context,
    List<Achievement> achievements,
    String? memberName,
    SocialService socialService,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose an achievement to share',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ...achievements.map(
              (a) => ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(a.title),
                subtitle: Text(a.subtitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  socialService.shareAchievement(a, memberName: memberName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementShareTile extends StatelessWidget {
  const _AchievementShareTile({
    required this.achievement,
    required this.memberName,
    required this.socialService,
  });

  final Achievement achievement;
  final String? memberName;
  final SocialService socialService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.emoji_events,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(achievement.title),
        subtitle: Text(
          achievement.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton(
          onPressed: () => socialService.shareAchievement(
            achievement,
            memberName: memberName,
          ),
          child: const Text('Share'),
        ),
      ),
    );
  }
}

class _InstagramProfileTile extends StatelessWidget {
  const _InstagramProfileTile({
    required this.title,
    required this.subtitle,
    required this.subtitleLine,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String subtitleLine;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitleLine),
        trailing: FilledButton.tonal(
          onPressed: onPressed,
          child: const Text('View on Instagram'),
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
    final theme = Theme.of(context);
    final sourceLabel = post.source == 'national'
        ? 'National'
        : post.source == 'state'
            ? 'State'
            : 'Chapter';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.photo_camera,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          sourceLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          post.caption ??
              (post.url.length > 50
                  ? '${post.url.substring(0, 50)}...'
                  : post.url),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => socialService.openInstagramPostUrl(post.url),
      ),
    );
  }
}
