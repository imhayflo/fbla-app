import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fbla_member_app/models/state_competition_result.dart';

const _prefsOpenAIKey = 'openai_api_key';
const _openAIModel = 'gpt-4o-mini';

class OpenAIConfig {
  static Future<String?> getApiKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_prefsOpenAIKey)?.trim();
  }

  static Future<void> saveApiKey(String? key) async {
    final p = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await p.remove(_prefsOpenAIKey);
    } else {
      await p.setString(_prefsOpenAIKey, key.trim());
    }
  }
}


/// Parses pasted official state conference result text with ChatGPT.
class StateResultsParserService {
  static Future<List<StateCompetitionResult>> parseResultsText(
    String rawText, {
    String? apiKey,
  }) async {
    final key = apiKey ?? await OpenAIConfig.getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
        'Add an OpenAI API key under Settings -> State results to parse pasted listings.',
      );
    }

    final prompt = StringBuffer()
      ..writeln(
        'You extract structured FBLA state-level competitive event results from text.',
      )
      ..writeln(
        'Return ONLY a JSON array. Each object must have: '
        'memberName (string), placement (integer 1-10), eventName (string), '
        'stateCode (two-letter US state), conferenceYear (integer), '
        'conferenceMonth (integer 1-12, optional), '
        'conferenceLabel (string, e.g. "California State Leadership Conference").',
      )
      ..writeln('Text to parse:')
      ..writeln(rawText.length > 8000 ? rawText.substring(0, 8000) : rawText);

    final body = jsonEncode({
      'model': _openAIModel,
      'messages': [
        {
          'role': 'system',
          'content': 'You extract FBLA results and return only valid JSON.',
        },
        {'role': 'user', 'content': prompt.toString()},
      ],
      'temperature': 0.2,
    });

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI returned ${resp.statusCode}. Check your API key.');
    }

    final outer = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = outer['choices']?[0]?['message']?['content'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Empty response from ChatGPT.');
    }

    var jsonText = text.trim();
    if (jsonText.startsWith('```')) {
      final lines = jsonText.split('\n');
      if (lines.length > 2) {
        jsonText = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(jsonText);
    } catch (_) {
      final start = jsonText.indexOf('[');
      final end = jsonText.lastIndexOf(']');
      if (start < 0 || end <= start) {
        throw Exception('Could not parse JSON from ChatGPT output.');
      }
      parsed = jsonDecode(jsonText.substring(start, end + 1));
    }

    if (parsed is! List) {
      throw Exception('Expected a JSON array of results.');
    }

    return parsed
        .whereType<Map<String, dynamic>>()
        .map((m) => StateCompetitionResult.fromMap(m))
        .where((r) => r.memberName.isNotEmpty && r.placement > 0)
        .toList();
  }
}
