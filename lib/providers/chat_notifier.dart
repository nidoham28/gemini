import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import 'provider_selection_notifier.dart';

final chatProvider =
StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  // Rebuilds (and resets chat) whenever the active provider/model changes.
  final aiService = ref.watch(aiServiceProvider);
  return ChatNotifier(aiService);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  AiService? _aiService;
  bool _isLoading = false;
  String? _error;

  ChatNotifier(this._aiService) : super([]);

  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateService(AiService? service) => _aiService = service;

  List<Map<String, String>> get _history => state.map((msg) {
    return {
      'role': msg.type == MessageType.user ? 'user' : 'model',
      'content': msg.text,
    };
  }).toList();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    if (_aiService == null) {
      state = [
        ...state,
        ChatMessage(
          text: 'No provider configured. Open Settings to add an API key.',
          type: MessageType.model,
          error: 'no_provider',
        ),
      ];
      return;
    }

    _error = null;
    _isLoading = true;

    state = [...state, ChatMessage(text: text, type: MessageType.user)];

    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    var aiMessage = ChatMessage(
      id: aiMessageId,
      text: '',
      type: MessageType.model,
      isStreaming: true,
    );
    state = [...state, aiMessage];

    try {
      final stream = _aiService!.sendMessageStream(
        message: text,
        history: _history.sublist(0, _history.length - 2),
      );

      String fullText = '';
      await for (final chunk in stream) {
        fullText += chunk;
        aiMessage = aiMessage.copyWith(text: fullText);
        state = [...state.sublist(0, state.length - 1), aiMessage];
      }

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