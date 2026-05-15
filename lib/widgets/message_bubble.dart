import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16))),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Text(message.senderNick,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: isMe ? Colors.black87 : AppTheme.primary)),
              if (message.imagePath != null)
                Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(message.imagePath!),
                        width: 200, height: 200, fit: BoxFit.cover))),
              if (message.text.isNotEmpty && message.text != '[Imagem]')
                Text(message.text, style: TextStyle(fontSize: 14,
                    color: isMe ? Colors.black : AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (message.forwarded)
                  const Icon(Icons.forward, size: 10, color: AppTheme.textSecondary),
                Text(DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(fontSize: 9,
                        color: isMe ? Colors.black54 : AppTheme.textSecondary)),
              ]),
            ]))));
  }
}
