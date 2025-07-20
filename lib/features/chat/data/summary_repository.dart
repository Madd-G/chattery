import 'dart:convert';

import 'package:chattery/core/constants/api_constants.dart';
import 'package:chattery/core/models/message.dart';
import 'package:http/http.dart' as http;

abstract class SummaryRepository {
  Future<String> generateSummary(List<Message> conversationHistory);
}

class SummaryRepositoryImpl implements SummaryRepository {
  final http.Client _client;

  SummaryRepositoryImpl({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String> generateSummary(List<Message> conversationHistory) async {
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
Please create a concise summary of this conversation that captures the key topics, questions asked, and important information discussed. Keep it brief but informative:

$history
Summary:
""",
        "stream": false,
        "options": {"temperature": 0.3, "max_tokens": 200},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']?.toString().trim() ?? '';
    } else {
      throw Exception('Failed to generate summary: ${response.statusCode}');
    }
  }
}
