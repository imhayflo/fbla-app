import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/member.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: StreamBuilder<Member?>(
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatBadge(
                            label: 'Rank',
                            value: member.rank > 0 ? '#${member.rank}' : '-',
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
                ),

                // Member Information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Actions
                      Text(
                        'Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Edit profile coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Settings coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Help & Support coming soon!')),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
