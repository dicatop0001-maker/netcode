import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
    final MessageModel message;
    final bool isMe;
    final VoidCallback? onPrivateReply;

    const MessageBubble({
          super.key,
          required this.message,
          required this.isMe,
          this.onPrivateReply,
    });

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
                                                                      topLeft: const Radius.circular(16),
                                                                      topRight: const Radius.circular(16),
                                                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                                                    ),
                                                    ),
                                        child: Column(
                                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                                      children: [
                                                                      // ── Nome do remetente (SEMPRE visivel) ──────────────────────
                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                                            Text(
                                                                                                                                  isMe ? 'Voce' : message.senderNick,
                                                                                                                                  style: TextStyle(
                                                                                                                                                          fontSize: 11,
                                                                                                                                                          fontWeight: FontWeight.bold,
                                                                                                                                                          color: isMe ? Colors.black87 : AppTheme.primary,
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                            // Badge privado
                                                                                                            if (message.isPrivate) ...[
                                                                                                                                  const SizedBox(width: 4),
                                                                                                                                  Container(
                                                                                                                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                                                                                                                          decoration: BoxDecoration(
                                                                                                                                                                                    color: Colors.orange.withOpacity(0.25),
                                                                                                                                                                                    borderRadius: BorderRadius.circular(6),
                                                                                                                                                                                  ),
                                                                                                                                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                                                                                                                                                    const Icon(Icons.lock_outline, size: 9, color: Colors.orange),
                                                                                                                                                                                    const SizedBox(width: 2),
                                                                                                                                                                                    const Text('privado',
                                                                                                                                                                                                                           style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                                                                                                                                                  ]),
                                                                                                                                                        ),
                                                                                                                                ],
                                                                                                            // Botao responder privado (so em msgs de outros)
                                                                                                            if (!isMe && onPrivateReply != null) ...[
                                                                                                                                  const SizedBox(width: 6),
                                                                                                                                  GestureDetector(
                                                                                                                                                          onTap: onPrivateReply,
                                                                                                                                                          child: const Icon(Icons.reply, size: 14, color: AppTheme.textSecondary),
                                                                                                                                                        ),
                                                                                                                                ],
                                                                                                          ],
                                                                                      ),
                                                                      const SizedBox(height: 2),
                                                                      // ── Imagem ───────────────────────────────────────────────────
                                                                      if (message.imagePath != null)
                                                                        Padding(
                                                                                            padding: const EdgeInsets.only(bottom: 4),
                                                                                            child: ClipRRect(
                                                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                                                  child: Image.file(
                                                                                                                                          File(message.imagePath!),
                                                                                                                                          width: 200, height: 200, fit: BoxFit.cover,
                                                                                                                                        ),
                                                                                                                ),
                                                                                          ),
                                                                      // ── Texto ────────────────────────────────────────────────────
                                                                      if (message.text.isNotEmpty && message.text != '[Imagem]')
                                                                        Text(
                                                                                            message.text,
                                                                                            style: TextStyle(
                                                                                                                  fontSize: 14,
                                                                                                                  color: isMe ? Colors.black : AppTheme.textPrimary,
                                                                                                                ),
                                                                                          ),
                                                                      const SizedBox(height: 2),
                                                                      // ── Hora ─────────────────────────────────────────────────────
                                                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                                                                        if (message.forwarded)
                                                                                          const Icon(Icons.forward, size: 10, color: AppTheme.textSecondary),
                                                                                        Text(
                                                                                                            DateFormat('HH:mm').format(message.createdAt),
                                                                                                            style: TextStyle(
                                                                                                                                  fontSize: 9,
                                                                                                                                  color: isMe ? Colors.black54 : AppTheme.textSecondary,
                                                                                                                                ),
                                                                                                          ),
                                                                                      ]),
                                                                    ],
                                                    ),
                                      ),
                          ),
                );
    }
}
