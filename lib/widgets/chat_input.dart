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
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5F6368)),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Message Gemini',
                    hintStyle: GoogleFonts.roboto(
                      color: const Color(0xFF5F6368),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: _hasText
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.mic, color: Color(0xFF5F6368)),
                      onPressed: () {},
                    ),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: const Color(0xFF202124),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasText && !widget.isLoading
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFFDADCE0),
                  shape: BoxShape.circle,
                ),
                child: widget.isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF5F6368),
                  ),
                )
                    : Icon(
                  Icons.arrow_upward,
                  color: _hasText ? Colors.white : const Color(0xFF5F6368),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}