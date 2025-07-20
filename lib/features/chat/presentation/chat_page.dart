import 'package:chattery/features/chat/application/notifiers/chat_notifier.dart';
import 'package:chattery/features/chat/application/providers/chat_providers.dart';
import 'package:chattery/features/chat/application/providers/hints_providers.dart';
import 'package:chattery/features/chat/application/providers/summary_providers.dart';
import 'package:chattery/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:chattery/features/chat/presentation/widgets/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _summaryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider.notifier).initializeTts();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _summaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final summaryState = ref.watch(summaryNotifierProvider);
    final hintsState = ref.watch(hintsNotifierProvider);

    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    final summaryNotifier = ref.read(summaryNotifierProvider.notifier);
    final hintsNotifier = ref.read(hintsNotifierProvider.notifier);

    ref.listen<ChatState>(chatNotifierProvider, (prev, next) {
      if (prev!.messages.length != next.messages.length ||
          (next.messages.isNotEmpty &&
              prev.messages.isNotEmpty &&
              prev.messages.last.content != next.messages.last.content)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Chat"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: chatNotifier.clearChat,
            // Calls the clearChat method on the notifier
            tooltip: "Clear Chat",
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Left Panel: Chat Section
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (chatState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Text(
                      chatState.error!,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Expanded(
                  child: chatState.messages.isEmpty
                      ? const Center(
                          child: Text(
                            "Start a conversation by typing a message...",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chatState.messages[index];
                            final isUser = msg.role == 'user';
                            return ChatBubble(message: msg, isUser: isUser);
                          },
                        ),
                ),

                if (chatState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),

                MessageInput(
                  controller: _controller,
                  onSend: () {
                    chatNotifier.sendMessage(_controller.text);
                    _controller.clear();
                  },
                  isLoading: chatState.isLoading,
                ),
              ],
            ),
          ),

          /// Right Panel: Summary Section
          Expanded(
            child: SingleChildScrollView(
              controller: _summaryScrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Summary Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "📋 Conversation Summary",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, size: 20),
                        onPressed: hintsState.isLoading
                            ? null
                            : () => summaryNotifier.updateSummary(
                                chatState.messages,
                              ),
                        tooltip: "Update summary",
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      if (summaryState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (summaryState.summary == null) {
                        return Text(
                          "No summary yet.",
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Text(summaryState.summary!);
                    },
                  ),
                  const SizedBox(height: 24),

                  /// Hints Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "💡 Hints & Topics",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, size: 20),
                        onPressed: hintsState.isLoading
                            ? null
                            : () =>
                                  hintsNotifier.updateHints(chatState.messages),
                        tooltip: "Update hints",
                      ),
                    ],
                  ),
                  Builder(
                    builder: (_) {
                      if (hintsState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (hintsState.hints == null ||
                          hintsState.hints!.isEmpty) {
                        return Text(
                          "No hints available.",
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: hintsState.hints!
                            .map(
                              (hint) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Text("• $hint"),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
