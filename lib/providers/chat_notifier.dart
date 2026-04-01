import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import 'provider_selection_notifier.dart';

final chatProvider =
StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
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

  // ── FIXED: 'model' পরিবর্তে 'assistant' ব্যবহার করা হয়েছে ──
  List<Map<String, String>> get _history => state.map((msg) {
    return {
      'role': msg.type == MessageType.user ? 'user' : 'assistant',
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

    // ১. বর্তমান ইউজার মেসেজ স্টেটে যোগ করা
    state = [...state, ChatMessage(text: text, type: MessageType.user)];

    // ২. AI রেসপন্সের জন্য একটি খালি বাবল তৈরি করা
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    var aiMessage = ChatMessage(
      id: aiMessageId,
      text: '',
      type: MessageType.model,
      isStreaming: true,
    );
    state = [...state, aiMessage];

    try {
      // ── FIXED: History Slicing Logic ──
      // আমরা এখন যে মেসেজটি পাঠাচ্ছি (যা শেষে যুক্ত হয়েছে), তার আগের সব মেসেজ হিস্ট্রিতে পাঠাবো।
      // state.length - 1 ব্যবহার করা হয়েছে যাতে বর্তমান মেসেজ বাদ যায়।
      List<Map<String, String>> previousHistory = [];
      if (_history.length > 1) {
        previousHistory = _history.sublist(0, _history.length - 1);
      }

      final stream = _aiService!.sendMessageStream(
        message: text,
        history: previousHistory,
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