import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.isLoading,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF282A2C)
                      : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Gemini',
                          hintStyle: GoogleFonts.roboto(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        cursorColor: colorScheme.primary,
                      ),
                    ),
                    if (!_hasText)
                      IconButton(
                        icon: Icon(
                          Icons.mic_none_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {},
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              hasText: _hasText,
              isLoading: widget.isLoading,
              onTap: _send,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool hasText;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _SendButton({
    required this.hasText,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final active = hasText && !isLoading;
    final bgColor = active
        ? colorScheme.primary
        : (isDark ? const Color(0xFF282A2C) : const Color(0xFFE8EAED));

    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? Padding(
          padding: const EdgeInsets.all(13),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onSurfaceVariant,
          ),
        )
            : Icon(
          Icons.arrow_upward_rounded,
          color: active ? Colors.white : colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}