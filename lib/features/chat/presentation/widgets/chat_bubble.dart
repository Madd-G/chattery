import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

import 'package:chattery/core/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isUser
                ? Text(
              message.content,
              style: const TextStyle(color: Colors.white),
            )
                : Builder(
              builder: (context) => MarkdownBody(
                data: message.content,
                builders: {
                  'code': CodeElementBuilder(context),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeElementBuilder(this.context);

  @override
  Widget visitElementAfter(element, children) {
    final text = element.textContent;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied!'),
                  duration: Duration(seconds: 1),
                ),
              );
              debugPrint("Copied: $text");
            },
          ),
        ],
      ),
    );
  }
}