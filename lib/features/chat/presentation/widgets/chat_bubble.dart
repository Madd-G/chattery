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
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
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
                ? SelectableText(
                    message.content,
                    style: const TextStyle(color: Colors.white),
                  )
                : SelectableText(
                    message.content,
                    style: const TextStyle(color: Colors.black),
                  ),
          ),
        ),
      ],
    );
  }
}
