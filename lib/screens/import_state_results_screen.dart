import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/database_service.dart';
import '../services/state_results_parser_service.dart';
import '../widgets/fbla_app_bar.dart';
import '../widgets/fbla_screen_shell.dart';

class ImportStateResultsScreen extends StatefulWidget {
  const ImportStateResultsScreen({super.key});

  @override
  State<ImportStateResultsScreen> createState() =>
      _ImportStateResultsScreenState();
}

class _ImportStateResultsScreenState extends State<ImportStateResultsScreen> {
  final _apiKeyController = TextEditingController();
  final _resultsController = TextEditingController();
  final _dbService = DatabaseService();
  bool _loadingKey = true;
  bool _parsing = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await OpenAIConfig.getApiKey();
    if (mounted) {
      setState(() {
        if (key != null) _apiKeyController.text = key;
        _loadingKey = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    await OpenAIConfig.saveApiKey(_apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved on this device')),
      );
    }
  }

  Future<void> _parseAndImport() async {
    final text = _resultsController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste official state results text first')),
      );
      return;
    }

    setState(() => _parsing = true);
    try {
      await OpenAIConfig.saveApiKey(_apiKeyController.text);
      final parsed = await StateResultsParserService.parseResultsText(text);
      if (parsed.isEmpty) {
        throw Exception('No placements were found in that text.');
      }

      await _dbService.saveStateCompetitionResults(parsed);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
      var linked = 0;
      if (uid != null && name.isNotEmpty) {
        linked = await _dbService.syncStatePlacementsForMember(uid, name);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${parsed.length} result(s)'
              '${linked > 0 ? '; $linked linked to your profile' : ''}.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FblaAppBar.standard(context, title: 'State results'),
      body: FblaScreenShell(
        child: _loadingKey
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'ChatGPT-assisted import',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste text from an official FBLA state conference results '
                    'listing (PDF excerpt, webpage copy, or spreadsheet export). '
                    'ChatGPT extracts placements and links them to member profiles '
                    'by name. The app does not scrape websites on its own.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'OpenAI API key',
                      hintText: 'sk-...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _saveApiKey,
                        child: const Text('Save key'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(
                              text: 'https://platform.openai.com/api-keys',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OpenAI API keys link copied'),
                            ),
                          );
                        },
                        child: const Text('Get a key'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _resultsController,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      labelText: 'Official results text',
                      hintText:
                          'Example: Mobile Application Development — 4th Hayden Floyd …',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _parsing ? null : _parseAndImport,
                    icon: _parsing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_parsing ? 'Parsing...' : 'Parse & import'),
                  ),
                ],
              ),
      ),
    );
  }
}
