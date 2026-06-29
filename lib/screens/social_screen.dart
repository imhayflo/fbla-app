import 'package:flutter/material.dart';
import 'package:fbla_member_app/models/member.dart';
import 'package:fbla_member_app/models/social_config.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'package:fbla_member_app/services/social_service.dart';
import 'package:fbla_member_app/widgets/fbla_app_bar.dart';
import 'package:fbla_member_app/widgets/fbla_screen_shell.dart';
import 'package:fbla_member_app/widgets/app_chrome.dart';

class SocialScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialChatConversationId;
  final String? initialChatTitle;
  final int chatOpenRequestId;

  const SocialScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialChatConversationId,
    this.initialChatTitle,
    this.chatOpenRequestId = 0,
  });

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final SocialService _socialService = SocialService();
  SocialConfig? _socialConfig;
  late final TabController _tabController;
  int _handledChatOpenRequestId = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      vsync: this,
    );
    _loadSocialConfig();
    _openRequestedChatAfterBuild();
  }

  @override
  void didUpdateWidget(covariant SocialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != _tabController.index) {
      _tabController.animateTo(widget.initialTabIndex);
    }
    _openRequestedChatAfterBuild();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRequestedChatAfterBuild() {
    final conversationId = widget.initialChatConversationId;
    if (conversationId == null ||
        conversationId.isEmpty ||
        widget.chatOpenRequestId == _handledChatOpenRequestId) {
      return;
    }
    _handledChatOpenRequestId = widget.chatOpenRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ChatSheet(
          dbService: _dbService,
          conversationId: conversationId,
          title: widget.initialChatTitle ?? 'Member',
        ),
      );
    });
  }

  Future<void> _loadSocialConfig() async {
    final config = await _dbService.getSocialConfig();
    if (mounted) setState(() => _socialConfig = config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.public), text: 'Socials'),
                  Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Messages'),
                  Tab(icon: Icon(Icons.push_pin_outlined), text: 'Pins'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
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
          String query = '';
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return StreamBuilder<List<Member>>(
                stream: dbService.membersDirectoryStream,
                builder: (context, snapshot) {
                  final members = snapshot.data ?? [];
                  final filteredMembers = members.where((member) {
                    final search = query.trim().toLowerCase();
                    if (search.isEmpty) return true;
                    return member.name.toLowerCase().contains(search) ||
                        member.email.toLowerCase().contains(search) ||
                        member.school.toLowerCase().contains(search) ||
                        member.chapter.toLowerCase().contains(search);
                  }).toList();

                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _SectionTitle(title: 'Choose a member'),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search members',
                          hintText: 'Name, school, chapter, or email',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setSheetState(() => query = value),
                      ),
                      const SizedBox(height: 16),
                      if (members.isEmpty)
                        const _EmptyState(
                          icon: Icons.people_outline,
                          text: 'No other members found.',
                        )
                      else if (filteredMembers.isEmpty)
                        const _EmptyState(
                          icon: Icons.search_off,
                          text: 'No members match that search.',
                        ),
                      ...filteredMembers.map(
                        (member) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: member.photoUrl.isNotEmpty
                                  ? NetworkImage(member.photoUrl)
                                  : null,
                              child: member.photoUrl.isEmpty
                                  ? Text(member.initials)
                                  : null,
                            ),
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
          label: const Text('Create pin request'),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Pin trade requests'),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: dbService.pinListingsStream,
          builder: (context, snapshot) {
            final listings = snapshot.data ?? [];
            if (listings.isEmpty) {
              return const _EmptyState(
                icon: Icons.push_pin_outlined,
                text: 'No pin requests yet.',
              );
            }
            return Column(
              children: listings.map((listing) {
                final ownerId = listing['ownerId'];
                final mine = ownerId == dbService.currentUserId;
                final wantedPin = listing['pinName']?.toString() ?? 'FBLA pin';
                final wantedState = listing['state']?.toString() ?? 'Any chapter';
                final offeredPin = listing['offeredPinName']?.toString() ??
                    listing['tradeFor']?.toString() ??
                    'Open to offers';
                final offerCondition = listing['offerCondition']?.toString() ??
                    listing['condition']?.toString() ??
                    'Good';
                final offerNotes = listing['offerNotes']?.toString() ?? '';
                final subtitle = StringBuffer()
                  ..writeln('${listing['ownerName'] ?? 'Member'} is looking for $wantedState')
                  ..writeln('Offering: $offeredPin - $offerCondition');
                if (offerNotes.trim().isNotEmpty) {
                  subtitle.write(offerNotes.trim());
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(_pinInitials(wantedState)),
                    ),
                    title: Text('Looking for $wantedPin'),
                    subtitle: Text(subtitle.toString().trim()),
                    isThreeLine: true,
                    trailing: mine
                        ? const Chip(label: Text('Yours'))
                        : FilledButton.tonal(
                            onPressed: () async {
                              await dbService.requestPinTrade(listing);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Trade offer sent')),
                                );
                              }
                            },
                            child: const Text('Offer'),
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
  final _wantedPin = TextEditingController();
  final _wantedState = TextEditingController();
  final _offeredPin = TextEditingController();
  final _offerCondition = TextEditingController(text: 'Good');
  final _offerNotes = TextEditingController();

  @override
  void dispose() {
    _wantedPin.dispose();
    _wantedState.dispose();
    _offeredPin.dispose();
    _offerCondition.dispose();
    _offerNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.push_pin_outlined),
                title: Text('Create pin request'),
                subtitle: Text('Ask for the pin you want and offer one of yours.'),
              ),
              TextFormField(
                controller: _wantedPin,
                decoration: const InputDecoration(labelText: 'Pin you are looking for'),
                validator: _required,
              ),
              TextFormField(
                controller: _wantedState,
                decoration: const InputDecoration(labelText: 'State or chapter wanted'),
                validator: _required,
              ),
              TextFormField(
                controller: _offeredPin,
                decoration: const InputDecoration(labelText: 'Pin you can offer'),
                validator: _required,
              ),
              TextFormField(
                controller: _offerCondition,
                decoration: const InputDecoration(labelText: 'Offered pin condition'),
                validator: _required,
              ),
              TextFormField(
                controller: _offerNotes,
                decoration: const InputDecoration(labelText: 'Offer notes'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await widget.dbService.createPinListing(
                      pinName: _wantedPin.text,
                      state: _wantedState.text,
                      offeredPinName: _offeredPin.text,
                      offerCondition: _offerCondition.text,
                      offerNotes: _offerNotes.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Post request'),
                ),
              ),
            ],
          ),
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
