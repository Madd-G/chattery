import 'dart:convert';
import 'package:chattery/core/constants/api_constants.dart';
import 'package:chattery/core/models/message.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class ChatRepository {
  Stream<String> generateChatResponseStream({
    required String prompt,
    required List<Message> conversationHistory,
    String? summaryContext,
  });
  Future<String> generateSummary({required List<Message> conversationHistory});
}

class ChatRepositoryImpl implements ChatRepository {
  final http.Client _client;

  ChatRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Stream<String> generateChatResponseStream({
    required String prompt,
    required List<Message> conversationHistory,
    String? summaryContext,
  }) async* {
    String finalPrompt;

    if (summaryContext != null && summaryContext.isNotEmpty) {
      // Use summary + recent messages (last 6 messages) for context
      final recentMessages = conversationHistory.length > 6
          ? conversationHistory.sublist(conversationHistory.length - 6)
          : conversationHistory;

      final recentContext = recentMessages
          .map((msg) {
        final role = msg.role == 'user' ? "User" : "Assistant";
        return "$role: ${msg.content}";
      })
          .join("\n");

      finalPrompt =
      """Context from previous conversation:
$summaryContext

Recent conversation:
$recentContext

Please respond naturally to the user's latest message. Keep your response clear and helpful.
Assistant:""";
    } else {
      // Use full history if no summary yet
      finalPrompt = conversationHistory
          .map((msg) {
        final role = msg.role == 'user' ? "User" : "Assistant";
        return "$role: ${msg.content}";
      })
          .join("\n");
      finalPrompt += "\nAssistant:";
    }

    final request = http.Request(
      'POST',
      Uri.parse('${ApiConstants.ollamaBaseUrl}${ApiConstants.ollamaGenerateEndpoint}'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        "model": ApiConstants.defaultLlmModel,
        "prompt": finalPrompt,
        "stream": true,
        "options": {"temperature": 0.7, "top_p": 0.9, "max_tokens": 500},
      });

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'HTTP ${streamedResponse.statusCode}: ${streamedResponse.reasonPhrase}',
      );
    }

    await for (var chunk
    in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      try {
        final data = jsonDecode(chunk);
        if (data.containsKey('response')) {
          yield data['response'] as String;
        }
      } catch (e) {
        debugPrint("Error parsing chunk: $e, chunk: $chunk");
      }
    }
  }

  @override
  Future<String> generateSummary({required List<Message> conversationHistory}) async {
    final history = conversationHistory
        .map((msg) {
      final role = msg.role == 'user' ? "User" : "Assistant";
      return "$role: ${msg.content}";
    })
        .join("\n");

    final response = await _client.post(
      Uri.parse('${ApiConstants.ollamaBaseUrl}${ApiConstants.ollamaGenerateEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": ApiConstants.defaultLlmModel,
        "prompt":
        """Please create a concise summary of this conversation that captures the key topics, questions asked, and important information discussed. Keep it brief but informative:

$history
Summary:""",
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