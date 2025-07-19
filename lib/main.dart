import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chattery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // Full conversation history
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _summaryScrollController = ScrollController();

  bool _loading = false;
  bool _summaryLoading = false;
  String? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _loading) return;

    setState(() {
      _messages.add({"role": "user", "content": prompt});
      _loading = true;
      _error = null;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final response = await _sendToLLM(prompt);

      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _loading = false;
      });

      _scrollToBottom();

      // Update summary after every message
      _updateSummary();

      // await _flutterTts.speak(response);

    } catch (e) {
      setState(() {
        _error = "Gagal mengirim pesan: ${e.toString()}";
        _loading = false;
      });
    }
  }

  Future<String> _sendToLLM(String prompt) async {
    String finalPrompt;

    if (_summary != null && _summary!.isNotEmpty) {
      // Use summary + recent messages (last 6 messages) for context
      final recentMessages = _messages.length > 6
          ? _messages.sublist(_messages.length - 6)
          : _messages;

      final recentContext = recentMessages.map((msg) {
        final role = msg['role'] == 'user' ? "User" : "Assistant";
        return "$role: ${msg['content']}";
      }).join("\n");

      finalPrompt = """Context from previous conversation:
$_summary

Recent conversation:
$recentContext

Please respond naturally to the user's latest message. Keep your response clear and helpful.
Assistant:""";
    } else {
      // Use full history if no summary yet
      finalPrompt = _messages.map((msg) {
        final role = msg['role'] == 'user' ? "User" : "Assistant";
        return "$role: ${msg['content']}";
      }).join("\n");
      finalPrompt += "\nAssistant:";
    }

    final response = await http.post(
      Uri.parse('http://localhost:11434/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "llama2",
        "prompt": finalPrompt,
        "stream": false,
        "options": {
          "temperature": 0.7,
          "top_p": 0.9,
          "max_tokens": 500,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['response']?.toString().trim() ?? 'Tidak ada respon dari model';
  }

  Future<void> _updateSummary() async {
    if (_summaryLoading || _messages.isEmpty) return;

    setState(() {
      _summaryLoading = true;
    });

    try {
      final history = _messages.map((msg) {
        final role = msg['role'] == 'user' ? "User" : "Assistant";
        return "$role: ${msg['content']}";
      }).join("\n");

      final response = await http.post(
        Uri.parse('http://localhost:11434/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "llama2",
          "prompt": """Please create a concise summary of this conversation that captures the key topics, questions asked, and important information discussed. Keep it brief but informative:

$history

Summary:""",
          "stream": false,
          "options": {
            "temperature": 0.3,
            "max_tokens": 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['response']?.toString().trim() ?? '';

        setState(() {
          _summary = summary.isEmpty ? "Ringkasan sedang diproses..." : summary;
          _summaryLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _summaryLoading = false;
      });
      debugPrint("Summary update error: $e");
    }
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _summary = null;
      _error = null;
    });
  }

  void _regenerateSummary() {
    if (_messages.isNotEmpty) {
      _updateSummary();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _summaryScrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chattery"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.delete),
        //     onPressed: _clearChat,
        //     tooltip: "Bersihkan Chat",
        //   ),
        // ],
      ),
      body: Row(
        children: [
          /// Left Panel: Chat
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Error display
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Chat messages - Both user and AI
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                    child: Text(
                      "Mulai percakapan dengan mengetik pesan...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.smart_toy,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.blue.shade500
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isUser ? null : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),

                            if (isUser) ...[
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Loading indicator
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Ketik pesan Anda...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_loading,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _loading ? Icons.hourglass_empty : Icons.send,
                          color: _loading ? Colors.grey : Colors.blue,
                        ),
                        onPressed: _loading ? null : _sendMessage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Right Panel: Summary
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "📋 Ringkasan Percakapan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_messages.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: _summaryLoading ? null : _regenerateSummary,
                          tooltip: "Perbarui ringkasan",
                        ),
                    ],
                  ),
                ),

                // Summary content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _summaryLoading
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Membuat ringkasan..."),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      controller: _summaryScrollController,
                      child: Text(
                        _summary ?? (_messages.isEmpty
                            ? "Mulai percakapan untuk melihat ringkasan..."
                            : "Belum ada ringkasan."),
                        style: TextStyle(
                          color: _summary != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Summary info
                // if (_messages.isNotEmpty)
                //   Container(
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       border: Border(
                //         top: BorderSide(color: Colors.grey.shade300),
                //       ),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           "📊 Statistik:",
                //           style: TextStyle(
                //             fontWeight: FontWeight.bold,
                //             color: Colors.grey.shade700,
                //           ),
                //         ),
                //         const SizedBox(height: 8),
                //         Text(
                //           "• ${_messages.length} pesan total\n"
                //               "• ${_messages.where((m) => m['role'] == 'user').length} dari pengguna\n"
                //               "• ${_messages.where((m) => m['role'] == 'assistant').length} dari assistant",
                //           style: TextStyle(
                //             fontSize: 12,
                //             color: Colors.grey.shade600,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}