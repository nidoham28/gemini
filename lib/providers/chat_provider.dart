import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

final chatProvider =
StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.read(geminiServiceProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GeminiService _geminiService;
  bool _isLoading = false;
  String? _error;

  ChatNotifier(this._geminiService) : super([]);

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, String>> get _history {
    return state.map((msg) {
      return {
        'role': msg.type == MessageType.user ? 'user' : 'model',
        'content': msg.text,
      };
    }).toList();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _error = null;
    _isLoading = true;

    // Append user message.
    state = [
      ...state,
      ChatMessage(text: text, type: MessageType.user),
    ];

    // Append empty AI placeholder with streaming flag.
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    var aiMessage = ChatMessage(
      id: aiMessageId,
      text: '',
      type: MessageType.model,
      isStreaming: true,
    );
    state = [...state, aiMessage];

    try {
      // ✅ state is now [...priorHistory, userMessage, aiPlaceholder].
      // Subtract 2 to exclude both trailing entries so the history passed
      // to the service contains only prior turns — the current user turn
      // is sent separately via the 'message' parameter.
      final stream = _geminiService.sendMessageStream(
        message: text,
        history: _history.sublist(0, _history.length - 2),
      );

      String fullText = '';

      await for (final chunk in stream) {
        fullText += chunk;
        aiMessage = aiMessage.copyWith(text: fullText);
        state = [
          ...state.sublist(0, state.length - 1),
          aiMessage,
        ];
      }

      // Mark streaming complete.
      state = [
        ...state.sublist(0, state.length - 1),
        aiMessage.copyWith(isStreaming: false),
      ];
    } catch (e) {
      _error = e.toString();
      state = [
        ...state.sublist(0, state.length - 1),
        ChatMessage(
          text: 'Error: ${e.toString()}',
          type: MessageType.model,
          error: e.toString(),
        ),
      ];
    } finally {
      _isLoading = false;
    }
  }

  void clearChat() {
    state = [];
    _error = null;
  }
}