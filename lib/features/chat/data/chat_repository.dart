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
          """
Context from previous conversation:
$summaryContext

Recent conversation:
$recentContext

Please respond naturally to the user's latest message. Keep your response clear, concise, and directly to the point. Do NOT include unnecessary greetings, explanations, or apologies. Start your answer directly.

Assistant:""";
    } else {
      finalPrompt =
          "${conversationHistory.map((msg) {
            final role = msg.role == 'user' ? "User" : "Assistant";
            return "$role: ${msg.content}";
          }).join("\n")}\nAssistant:";
    }

    final request =
        http.Request(
            'POST',
            Uri.parse(
              '${ApiConstants.ollamaBaseUrl}${ApiConstants.ollamaGenerateEndpoint}',
            ),
          )
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({
            "model": ApiConstants.defaultLlmModel,
            "prompt": finalPrompt,
            "stream": true,
            "options": {"temperature": 0.2, "top_p": 0.3, "max_tokens": 500},
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
}
