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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userBubbleColor = isDark
        ? const Color(0xFF004A77)
        : const Color(0xFF1A73E8);
    final modelBubbleColor = colorScheme.surfaceContainerHighest;
    final userTextColor = Colors.white;
    final modelTextColor = colorScheme.onSurface;
    final codeBackground = isDark
        ? const Color(0xFF1E1F20)
        : const Color(0xFFF1F3F4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildModelAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : modelBubbleColor,
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
                        color: userTextColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        code: GoogleFonts.robotoMono(
                          backgroundColor: codeBackground,
                          color: isDark
                              ? const Color(0xFF81C995)
                              : const Color(0xFF188038),
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: codeBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        h1: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        h2: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        h3: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        strong: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        em: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: GoogleFonts.roboto(
                          color: modelTextColor,
                          fontSize: 15,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: codeBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Blinking cursor while streaming
                  if (message.isStreaming && isLatest)
                    Container(
                      width: 2,
                      height: 18,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildModelAvatar() {
    return Container(
      width: 28,
      height: 28,
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildUserAvatar(ColorScheme colorScheme) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 16,
      ),
    );
  }
}