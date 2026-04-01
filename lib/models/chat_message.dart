import 'package:uuid/uuid.dart';

var uuid = const Uuid();

enum MessageType { user, model }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isStreaming;
  final String? error;

  ChatMessage({
    String? id,
    required this.text,
    required this.type,
    DateTime? timestamp,
    this.isStreaming = false,
    this.error,
  })  : id = id ?? uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isStreaming,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error ?? this.error,
    );
  }
}