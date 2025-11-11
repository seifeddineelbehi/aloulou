// File: presentation/screens/chat/chat_session_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ChatSessionScreen extends StatelessWidget {
  final String sessionId;

  const ChatSessionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyMessages = [
      {'text': 'Hi there!', 'isUser': true},
      {'text': 'Hello! How can I assist you?', 'isUser': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Session: $sessionId'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: dummyMessages.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final msg = dummyMessages[index];
          return Align(
            alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg['isUser']
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(msg['text']),
            ),
          );
        },
      ),
    );
  }
}
