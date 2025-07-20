import 'dart:convert';

import 'package:chattery/core/constants/api_constants.dart';
import 'package:chattery/core/models/message.dart';
import 'package:http/http.dart' as http;

abstract class HintsRepository {
  Future<List<String>> generateHints(List<Message> conversationHistory);
}

class HintsRepositoryImpl implements HintsRepository {
  final http.Client _client;

  HintsRepositoryImpl({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<String>> generateHints(List<Message> conversationHistory) async {
    final history = conversationHistory
        .map((msg) {
          final role = msg.role == 'user' ? "User" : "Assistant";
          return "$role: ${msg.content}";
        })
        .join("\n");

    final response = await _client.post(
      Uri.parse(
        '${ApiConstants.ollamaBaseUrl}${ApiConstants.ollamaGenerateEndpoint}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": ApiConstants.defaultLlmModel,
        "prompt":
            """
Based on the following conversation, suggest 3–5 short, natural follow-up questions or topics the user could ask next.

Important: Return only the numbered list of suggestions. Do NOT include any introduction, explanation, or closing remarks. Start directly with "1." and continue the list.

Conversation:
$history

Hints:
""",
        "stream": false,
        "options": {"temperature": 0.7, "max_tokens": 150},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawHints = data['response']?.toString().trim() ?? '';

      final hints = rawHints
          .split(RegExp(r'\n'))
          .map((line) => line.replaceAll(RegExp(r'^\d+\. *'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return hints;
    } else {
      throw Exception('Failed to generate hints: ${response.statusCode}');
    }
  }
}
