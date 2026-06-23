import 'package:flutter/material.dart';
import 'package:fbla_member_app/models/member.dart';
import 'package:fbla_member_app/models/social_config.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'package:fbla_member_app/services/social_service.dart';
import 'package:fbla_member_app/widgets/fbla_app_bar.dart';
import 'package:fbla_member_app/widgets/fbla_screen_shell.dart';
import 'package:fbla_member_app/widgets/app_chrome.dart';

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: FblaAppBar.standard(
          context,
          title: 'Social',
          actions: const [
            AppHelpButton(
              title: 'Connect with FBLA members',
              tips: [
                'Use Socials for official links, Messages for requests and chats, and Pins for trading listings.',
                'Pin trading and messaging are built around requests so members stay in control.',
              ],
            ),
          ],
        ),
        body: FblaScreenShell(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AppInstructionCard(
                  id: 'social',
                  title: 'Connect with FBLA members',
                  tips: [
                    'Use Socials for official links, Messages for member requests and chats, and Pins for trading listings.',
                    'Pin trading and messaging are built around requests so members stay in control.',
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.public), text: 'Socials'),
                  Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Messages'),
                  Tab(icon: Icon(Icons.push_pin_outlined), text: 'Pins'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _SocialLinksTab(
                      dbService: _dbService,
                      socialService: _socialService,
                      socialConfig: _socialConfig,
                    ),
                    _MessagesTab(dbService: _dbService),
                    _PinsTab(dbService: _dbService),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLinksTab extends StatelessWidget {
  const _SocialLinksTab({
    required this.dbService,
    required this.socialService,
    required this.socialConfig,
  });

  final DatabaseService dbService;
  final SocialService socialService;
  final SocialConfig? socialConfig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nationalHandle = socialConfig?.nationalInstagramHandle ?? 'fbla_national';
    final nationalUrl = socialConfig?.nationalInstagramUrl ??
        'https://www.instagram.com/fbla_national/';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ShareAchievementsCard(
          socialService: socialService,
          dbService: dbService,
        ),
        const SizedBox(height: 24),
        Text(
          'FBLA on Instagram',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _SocialTile(
          title: 'National FBLA',
          handle: nationalHandle,
          icon: Icons.flag,
          onPressed: () => socialService.openInstagramProfile(url: nationalUrl),
        ),
        const SizedBox(height: 24),
        Text(
          'FBLA on LinkedIn',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with FBLA on LinkedIn for career and networking.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _SocialTile(
          title: 'National FBLA',
          handle: 'Future Business Leaders of America',
          icon: Icons.business_center,
          onPressed: () => socialService.openLinkedInProfile(
            url: socialConfig?.nationalLinkedInUrl ??
                'https://www.linkedin.com/company/future-business-leaders-america',
            handle: 'future-business-leaders-america',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FBLA on Facebook',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _SocialTile(
          title: 'National FBLA',
          handle: 'FutureBusinessLeaders',
          icon: Icons.thumb_up,
          onPressed: () => socialService.openUrl(
            socialConfig?.nationalFacebookUrl ??
                'https://www.facebook.com/FutureBusinessLeaders',
          ),
        ),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab({required this.dbService});

  final DatabaseService dbService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _showMemberDirectory(context),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('New message request'),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Message requests'),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: dbService.messageRequestsStream,
          builder: (context, snapshot) {
            final currentUid = dbService.currentUserId;
            final requests = (snapshot.data ?? [])
                .where((request) => request['status'] == 'pending')
                .toList();
            if (requests.isEmpty) {
              return const _EmptyState(
                icon: Icons.mark_chat_unread_outlined,
                text: 'No pending message requests.',
              );
            }
            return Column(
              children: requests.map((request) {
                final incoming = request['recipientId'] == currentUid;
                final name = incoming
                    ? request['requesterName'] ?? 'Member'
                    : request['recipientName'] ?? 'Member';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(_initials(name.toString()))),
                    title: Text(name.toString()),
                    subtitle: Text(incoming ? 'Wants to message you' : 'Request sent'),
                    trailing: incoming
                        ? Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                tooltip: 'Accept',
                                onPressed: () => dbService.acceptMessageRequest(request),
                                icon: const Icon(Icons.check),
                              ),
                              IconButton(
                                tooltip: 'Decline',
                                onPressed: () => dbService
                                    .declineMessageRequest(request['id'] as String),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          )
                        : const Icon(Icons.hourglass_empty),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Chats'),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: dbService.conversationsStream,
          builder: (context, snapshot) {
            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return const _EmptyState(
                icon: Icons.chat_bubble_outline,
                text: 'No chats yet. Send a request to start one.',
              );
            }
            return Column(
              children: conversations.map((conversation) {
                final names = Map<String, dynamic>.from(
                  conversation['participantNames'] as Map? ?? {},
                );
                final otherName = names.entries
                    .firstWhere(
                      (entry) => entry.key != dbService.currentUserId,
                      orElse: () => MapEntry<String, dynamic>('', 'Member'),
                    )
                    .value
                    .toString();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(_initials(otherName))),
                    title: Text(otherName),
                    subtitle: Text(conversation['lastMessage']?.toString() ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChat(context, conversation['id'] as String, otherName),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showMemberDirectory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return StreamBuilder<List<Member>>(
            stream: dbService.membersDirectoryStream,
            builder: (context, snapshot) {
              final members = snapshot.data ?? [];
              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle(title: 'Choose a member'),
                  if (members.isEmpty)
                    const _EmptyState(
                      icon: Icons.people_outline,
                      text: 'No other members found.',
                    ),
                  ...members.map(
                    (member) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(member.initials)),
                        title: Text(member.name),
                        subtitle: Text(member.school.isEmpty ? member.email : member.school),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            await dbService.sendMessageRequest(member);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message request sent')),
                              );
                            }
                          },
                          child: const Text('Request'),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showChat(BuildContext context, String conversationId, String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ChatSheet(
        dbService: dbService,
        conversationId: conversationId,
        title: title,
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({
    required this.dbService,
    required this.conversationId,
    required this.title,
  });

  final DatabaseService dbService;
  final String conversationId;
  final String title;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title),
              leading: const Icon(Icons.chat_bubble_outline),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.dbService.messagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine =
                          message['senderId'] == widget.dbService.currentUserId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: mine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(message['text']?.toString() ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final text = _controller.text;
                      _controller.clear();
                      widget.dbService.sendChatMessage(widget.conversationId, text);
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinsTab extends StatelessWidget {
  const _PinsTab({required this.dbService});

  final DatabaseService dbService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _showNewPinListing(context),
          icon: const Icon(Icons.add),
          label: const Text('List a pin for trade'),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Pin stock market'),
        SizedBox(
          height: 132,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: dbService.pinMarketStream,
            builder: (context, snapshot) {
              final market = snapshot.data ?? [];
              if (market.isEmpty) {
                return const _EmptyState(
                  icon: Icons.show_chart,
                  text: 'Pin values appear after listings are created.',
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: market.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = market[index];
                  final value = (item['lastValue'] as num?)?.toDouble() ?? 0;
                  return SizedBox(
                    width: 180,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['pinName']?.toString() ?? 'Pin',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '\$${value.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text('${item['listingCount'] ?? 0} listings'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle(title: 'Trade listings'),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: dbService.pinListingsStream,
          builder: (context, snapshot) {
            final listings = snapshot.data ?? [];
            if (listings.isEmpty) {
              return const _EmptyState(
                icon: Icons.push_pin_outlined,
                text: 'No pins listed yet.',
              );
            }
            return Column(
              children: listings.map((listing) {
                final ownerId = listing['ownerId'];
                final mine = ownerId == dbService.currentUserId;
                final value = (listing['askingValue'] as num?)?.toDouble() ?? 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(_pinInitials(listing['state']?.toString())),
                    ),
                    title: Text(listing['pinName']?.toString() ?? 'FBLA pin'),
                    subtitle: Text(
                      '${listing['condition'] ?? 'Good'} • ${listing['ownerName'] ?? 'Member'}\nWants: ${listing['tradeFor'] ?? 'Open to offers'}',
                    ),
                    isThreeLine: true,
                    trailing: mine
                        ? const Chip(label: Text('Yours'))
                        : FilledButton.tonal(
                            onPressed: () async {
                              await dbService.requestPinTrade(listing);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Trade request sent')),
                                );
                              }
                            },
                            child: Text('\$${value.toStringAsFixed(0)}'),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showNewPinListing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PinListingSheet(dbService: dbService),
    );
  }
}

class _PinListingSheet extends StatefulWidget {
  const _PinListingSheet({required this.dbService});

  final DatabaseService dbService;

  @override
  State<_PinListingSheet> createState() => _PinListingSheetState();
}

class _PinListingSheetState extends State<_PinListingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinName = TextEditingController();
  final _state = TextEditingController();
  final _condition = TextEditingController(text: 'Good');
  final _value = TextEditingController(text: '10');
  final _tradeFor = TextEditingController(text: 'Open to offers');

  @override
  void dispose() {
    _pinName.dispose();
    _state.dispose();
    _condition.dispose();
    _value.dispose();
    _tradeFor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.push_pin_outlined),
              title: Text('List a pin'),
            ),
            TextFormField(
              controller: _pinName,
              decoration: const InputDecoration(labelText: 'Pin name'),
              validator: _required,
            ),
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State or chapter'),
              validator: _required,
            ),
            TextFormField(
              controller: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              validator: _required,
            ),
            TextFormField(
              controller: _value,
              decoration: const InputDecoration(labelText: 'Estimated value'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) return 'Enter a value';
                return null;
              },
            ),
            TextFormField(
              controller: _tradeFor,
              decoration: const InputDecoration(labelText: 'Looking for'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  await widget.dbService.createPinListing(
                    pinName: _pinName.text,
                    state: _state.text,
                    condition: _condition.text,
                    askingValue: double.parse(_value.text),
                    tradeFor: _tradeFor.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Post listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
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
    final display = h.isEmpty ? 'Instagram' : (h.startsWith('@') ? h : '@$h');

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  if (parts.isNotEmpty) return parts.first[0].toUpperCase();
  return '?';
}

String _pinInitials(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '?';
  return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
}
