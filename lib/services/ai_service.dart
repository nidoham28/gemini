import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ai_model_config.dart';
import '../models/ai_provider.dart';

class AiService {
  final AiProvider provider;
  final AiModelConfig model;

  AiService({required this.provider, required this.model});

  bool get isConfigured => provider.apiKey.isNotEmpty;

  String get displayName => '${provider.name} · ${model.displayName}';

  /// Dispatches to the correct streaming handler based on [provider.format].
  Stream<String> sendMessageStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    if (!isConfigured) {
      throw Exception(
          'API key not configured for ${provider.name}. Open Settings to add your key.');
    }

    if (provider.format == ApiFormat.gemini) {
      yield* _geminiStream(message: message, history: history);
    } else {
      yield* _openAiStream(message: message, history: history);
    }
  }

  // ── Gemini SSE ───────────────────────────────────────────────────

  Stream<String> _geminiStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    final endpoint = provider.endpoint.replaceAll('{model}', model.modelId);
    final uri = Uri.parse('${provider.baseUrl}$endpoint').replace(
      queryParameters: {'key': provider.apiKey, 'alt': 'sse'},
    );

    final body = jsonEncode({
      'contents': [
        ...history.map((msg) => {
          'role': msg['role'],
          'parts': [
            {'text': msg['content']}
          ],
        }),
        {
          'role': 'user',
          'parts': [
            {'text': message}
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final streamedResponse =
    await request.send().timeout(const Duration(seconds: 30));

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception('HTTP ${streamedResponse.statusCode}: $errorBody');
    }

    yield* _parseSseStream(
      stream: streamedResponse.stream.transform(utf8.decoder),
      extractText: (data) {
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) return null;
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null) return null;
        final buffer = StringBuffer();
        for (final part in parts) {
          final text = (part as Map<String, dynamic>)['text'] as String?;
          if (text != null) buffer.write(text);
        }
        final result = buffer.toString();
        return result.isEmpty ? null : result;
      },
    );
  }

  // ── OpenAI-compatible SSE ────────────────────────────────────────

  Stream<String> _openAiStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    final uri = Uri.parse('${provider.baseUrl}${provider.endpoint}');

    final body = jsonEncode({
      'model': model.modelId,
      'messages': [
        ...history
            .map((msg) => {'role': msg['role'], 'content': msg['content']}),
        {'role': 'user', 'content': message},
      ],
      'stream': true,
      'temperature': 0.7,
      'max_tokens': 2048,
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${provider.apiKey}';

    // OpenRouter requires these extra headers.
    if (provider.baseUrl.contains('openrouter')) {
      request.headers['HTTP-Referer'] = 'https://github.com/flutter-chat-app';
      request.headers['X-Title'] = 'Flutter AI Chat';
    }

    request.body = body;

    final streamedResponse =
    await request.send().timeout(const Duration(seconds: 30));

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception('HTTP ${streamedResponse.statusCode}: $errorBody');
    }

    yield* _parseSseStream(
      stream: streamedResponse.stream.transform(utf8.decoder),
      extractText: (data) {
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) return null;
        final delta = choices[0]['delta'] as Map<String, dynamic>?;
        return delta?['content'] as String?;
      },
    );
  }

  // ── Shared SSE parser ─────────────────────────────────────────────

  Stream<String> _parseSseStream({
    required Stream<String> stream,
    required String? Function(Map<String, dynamic> data) extractText,
  }) async* {
    String buffer = '';

    await for (final chunk in stream) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep incomplete last line

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final jsonStr = trimmed.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = extractText(data);
          if (text != null && text.isNotEmpty) yield text;
        } catch (e) {
          debugPrint('SSE parse error: $e');
        }
      }
    }

    // Flush any remaining buffered data.
    final trimmed = buffer.trim();
    if (trimmed.startsWith('data: ')) {
      final jsonStr = trimmed.substring(6).trim();
      if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = extractText(data);
          if (text != null && text.isNotEmpty) yield text;
        } catch (e) {
          debugPrint('Buffer flush error: $e');
        }
      }
    }
  }
}