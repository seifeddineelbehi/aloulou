import 'package:flutter/material.dart';
import '../../../../../../data/models/chat_message.dart';

class TextContent extends StatelessWidget {
  final ChatMessage message;

  const TextContent({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SelectableText(
        message.text,
        style: TextStyle(
          color: message.isUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

