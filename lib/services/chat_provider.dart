import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.read(geminiServiceProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GeminiService _geminiService;
  bool _isLoading = false;

  ChatNotifier(this._geminiService) : super([]);

  bool get isLoading => _isLoading;

  List<Map<String, String>> get _history {
    return state.map((msg) {
      return {
        'role': msg.type == MessageType.user ? 'user' : 'model',
        'content': msg.text,
      };
    }).toList();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      type: MessageType.user,
    );

    state = [...state, userMessage];
    _isLoading = true;

    final streamingMessage = ChatMessage(
      text: '',
      type: MessageType.model,
      isStreaming: true,
    );

    state = [...state, streamingMessage];

    try {
      final stream = _geminiService.sendMessageStream(
        message: text,
        history: _history.sublist(0, _history.length - 1),
      );

      String fullResponse = '';

      await for (final chunk in stream) {
        fullResponse += chunk;
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == state.length - 1)
              state[i].copyWith(text: fullResponse)
            else
              state[i]
        ];
      }

      state = [
        for (int i = 0; i < state.length; i++)
          if (i == state.length - 1)
            state[i].copyWith(isStreaming: false)
          else
            state[i]
      ];
    } catch (e) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == state.length - 1)
            state[i].copyWith(
              text: 'Error: ${e.toString()}',
              isStreaming: false,
              error: e.toString(),
            )
          else
            state[i]
      ];
    } finally {
      _isLoading = false;
    }
  }

  void clearChat() {
    state = [];
  }
}