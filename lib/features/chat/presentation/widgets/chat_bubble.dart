import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

import 'package:chattery/core/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.smart_toy, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? SelectableText(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
                  : MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  code: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                    backgroundColor: Colors.grey.shade300,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                ),
                builders: {
                  'code': CodeElementBuilder(context),
                },
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final String codeText = element.textContent;

    final isCodeBlock = codeText.contains('\n') || codeText.trim().split('\n').length > 1;

    if (!isCodeBlock) {
      return null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RichText(
              text: TextSpan(text: codeText, style: preferredStyle),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: Colors.white70,
              ),
              tooltip: 'Salin Kode',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codeText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode disalin ke clipboard!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}