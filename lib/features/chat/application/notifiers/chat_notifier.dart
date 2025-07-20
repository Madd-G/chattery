import 'package:chattery/features/chat/application/providers/summary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chattery/core/models/message.dart';
import 'package:chattery/core/services/tts_service.dart';
import 'package:chattery/features/chat/data/chat_repository.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({required this.messages, this.isLoading = false, this.error});

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// StateNotifier to manage the chat state and logic
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _chatRepository;
  final TtsService _ttsService;
  final Ref _ref;

  ChatNotifier(this._ref, this._chatRepository, this._ttsService)
    : super(ChatState(messages: []));

  Future<void> initializeTts() async {
    await _ttsService.initialize();
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.isEmpty || state.isLoading) return;

    final newMessage = Message(role: "user", content: prompt);
    state = state.copyWith(
      messages: [...state.messages, newMessage],
      isLoading: true,
      error: null,
    );

    final assistantPlaceholder = Message(role: "assistant", content: "");
    state = state.copyWith(messages: [...state.messages, assistantPlaceholder]);

    try {
      final currentSummary = _ref.read(summaryNotifierProvider).summary;
      String fullResponse = "";
      await for (final chunk in _chatRepository.generateChatResponseStream(
        prompt: prompt,
        conversationHistory: state.messages,
        summaryContext: currentSummary,
      )) {
        fullResponse += chunk;
        final updatedMessages = List<Message>.from(state.messages);
        if (updatedMessages.isNotEmpty &&
            updatedMessages.last.role == "assistant") {
          updatedMessages[updatedMessages.length - 1] = updatedMessages.last
              .copyWith(content: fullResponse);
          state = state.copyWith(messages: updatedMessages);
        }
      }

      state = state.copyWith(isLoading: false);
      // await _ttsService.speak(fullResponse);

      _ref.read(summaryNotifierProvider.notifier).updateSummary(state.messages);
    } catch (e) {
      state = state.copyWith(
        error: "Failed to send message: ${e.toString()}",
        isLoading: false,
      );
      if (state.messages.isNotEmpty &&
          state.messages.last.role == "assistant" &&
          state.messages.last.content == "") {
        final updatedMessages = List<Message>.from(state.messages)
          ..removeLast();
        state = state.copyWith(messages: updatedMessages);
      }
    }
  }

  void clearChat() {
    state = ChatState(messages: []);
    _ref
        .read(summaryNotifierProvider.notifier)
        .clearSummary();
  }
}
