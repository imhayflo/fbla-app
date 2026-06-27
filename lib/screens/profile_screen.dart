import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/social_service.dart';
import '../models/member.dart';
import 'login_screen.dart';
import 'update_profile_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import '../widgets/fbla_app_bar.dart';
import '../widgets/fbla_screen_shell.dart';
import '../widgets/app_chrome.dart';
import '../widgets/state_placement_badge.dart';
import '../models/state_competition_result.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final SocialService _socialService = SocialService();
  
  int _userRank = 0;
  bool _rankLoading = true;
  bool _placementsSynced = false;

  Future<void> _loadUserRank(String uid) async {
    final rank = await _dbService.getUserRank(uid);
    if (mounted) {
      setState(() {
        _userRank = rank;
        _rankLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. You must enter your password to confirm. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (password == null || password.isEmpty) return;
    try {
      await _authService.deleteAccount(password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FblaAppBar.standard(
        context,
        title: 'Profile',
        actions: const [
          AppHelpButton(
            title: 'Manage your member profile',
            tips: [
              'Your profile keeps membership, chapter, points, placements, and account actions in one place.',
              'Use Update Profile to keep your school, chapter, state, and contact details current.',
            ],
          ),
        ],
      ),
      body: FblaScreenShell(
        child: StreamBuilder<Member?>(
        stream: _dbService.memberStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final member = snapshot.data;
          if (member == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Unable to load profile'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _signOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          }

          // Load user rank when member data is available
          if (_rankLoading) {
            _loadUserRank(member.uid);
          }

          if (!_placementsSynced) {
            _placementsSynced = true;
            _dbService.syncStatePlacementsForMember(member.uid, member.name);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<List<StateCompetitionResult>>(
                  stream: _dbService.statePlacementsStream(member.uid),
                  builder: (context, placementSnap) {
                    final placements = placementSnap.data ?? const [];
                    return _ProfileHeader(
                      member: member,
                      theme: theme,
                      userRank: _userRank,
                      rankLoading: _rankLoading,
                      placements: placements,
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppInstructionCard(
                        id: 'profile',
                        title: 'Manage your member profile',
                        tips: [
                          'Your profile keeps membership, chapter, points, placements, and account actions in one place.',
                          'Use Update Profile to keep your school, chapter, state, and contact details current.',
                        ],
                      ),
                      Text(
                        'Member Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoCard(
                        icon: Icons.school,
                        title: 'School',
                        value: member.school,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.group,
                        title: 'Chapter',
                        value: member.chapter,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.email,
                        title: 'Email',
                        value: member.email,
                      ),
                      if (member.phone.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.phone,
                          title: 'Phone',
                          value: member.phone,
                        ),
                      ],
                      const SizedBox(height: 24),

                      StreamBuilder<List<StateCompetitionResult>>(
                        stream: _dbService.statePlacementsStream(member.uid),
                        builder: (context, placementSnap) {
                          final placements = placementSnap.data ?? const [];
                          if (placements.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'State competition placements',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Badges from official state-level FBLA results',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...placements.map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StatePlacementDetailCard(result: p),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),

                      // Achievements
                      if (member.achievements.isNotEmpty) ...[
                        Text(
                          'Achievements',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: member.achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = member.achievements[index];
                            return _AchievementCard(
                              icon: _getIconData(achievement.icon),
                              title: achievement.title,
                              subtitle: achievement.subtitle,
                              color: _getColor(achievement.color),
                              onShare: () => _socialService.shareAchievement(
                                achievement,
                                memberName: member.name,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        icon: Icons.edit,
                        title: 'Update Profile',
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpdateProfileScreen(member: member),
                            ),
                          );
                          if (updated == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        onTap: _signOut,
                        isDestructive: true,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.delete_forever,
                        title: 'Delete Account',
                        onTap: _deleteAccount,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'leaderboard':
        return Icons.leaderboard;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final Member member;
  final ThemeData theme;
  final int userRank;
  final bool rankLoading;
  final List<StateCompetitionResult> placements;

  const _ProfileHeader({
    required this.member,
    required this.theme,
    required this.userRank,
    required this.rankLoading,
    required this.placements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (placements.isNotEmpty)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: StatePlacementBadge(
                    result: placements.first,
                    compact: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            member.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.memberSince != null
                ? 'Member Since ${member.memberSince!.year}'
                : 'FBLA Member',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (placements.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: placements
                  .map((p) => StatePlacementBadge(result: p, compact: true))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                label: 'Rank',
                value: rankLoading
                    ? '-'
                    : (userRank > 0 ? '#$userRank' : '-'),
              ),
              const SizedBox(width: 24),
              _StatBadge(
                label: 'Points',
                value: '${member.points}',
              ),
              const SizedBox(width: 24),
              _StatBadge(
                label: 'Events',
                value: '${member.eventsAttended}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onShare;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onShare != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
