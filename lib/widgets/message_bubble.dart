import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLatest;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1A73E8) : const Color(0xFFE8EAED),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message.text,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.roboto(
                          color: const Color(0xFF3C4043),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        code: GoogleFonts.robotoMono(
                          backgroundColor: const Color(0xFFF1F3F4),
                          color: const Color(0xFF188038),
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        a: GoogleFonts.robotoMono(
                          fontSize: 13,
                          color: const Color(0xFF3C4043),
                        ),
                        h1: GoogleFonts.roboto(
                          color: const Color(0xFF202124),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        h2: GoogleFonts.roboto(
                          color: const Color(0xFF202124),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        h3: GoogleFonts.roboto(
                          color: const Color(0xFF202124),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        strong: GoogleFonts.roboto(
                          color: const Color(0xFF202124),
                          fontWeight: FontWeight.w600,
                        ),
                        listBullet: GoogleFonts.roboto(
                          color: const Color(0xFF3C4043),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (message.isStreaming && isLatest)
                    Container(
                      width: 2,
                      height: 18,
                      color: const Color(0xFF1A73E8),
                      margin: const EdgeInsets.only(top: 4),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 18),
    );
  }
}