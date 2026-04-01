import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _model = 'gemini-2.5-flash';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  String get apiKeyStatus {
    final key = _apiKey;
    if (key.isEmpty) return 'Not configured';
    if (key == 'your_api_key_here') return 'Placeholder detected';
    return 'Configured: ${key.substring(0, key.length > 10 ? 10 : key.length)}...';
  }

  bool get hasApiKey => _apiKey.isNotEmpty && _apiKey != 'your_api_key_here';

  List<Map<String, dynamic>> _formatHistory(List<Map<String, String>> history) {
    return history.map((msg) {
      return {
        'role': msg['role'],
        'parts': [
          {'text': msg['content']}
        ],
      };
    }).toList();
  }

  Future<String> sendMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    if (!hasApiKey) {
      throw Exception('API Key not configured. Check .env file');
    }

    final uri = Uri.https(
      _baseUrl,
      '/v1beta/models/$_model:generateContent',
      {'key': _apiKey},
    );

    final body = jsonEncode({
      'contents': [
        ..._formatHistory(history),
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

    final response = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>;
    if (candidates.isEmpty) throw Exception('No candidates in response');

    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return parts[0]['text'] as String;
  }

  Stream<String> sendMessageStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    if (!hasApiKey) {
      throw Exception('API Key not configured. Check .env file');
    }

    // ✅ 'alt=sse' is required. Without it, Gemini returns a raw JSON array
    // instead of SSE-formatted chunks, and the data: parser yields nothing.
    final uri = Uri.https(
      _baseUrl,
      '/v1beta/models/$_model:streamGenerateContent',
      {'key': _apiKey, 'alt': 'sse'},
    );

    final body = jsonEncode({
      'contents': [
        ..._formatHistory(history),
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

    String buffer = '';

    await for (final chunk
    in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;

      // SSE delivers lines ending in \n. Split, keep incomplete tail in buffer.
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;

        final jsonStr = trimmed.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) continue;

          final content =
          candidates[0]['content'] as Map<String, dynamic>?;
          if (content == null) continue;

          final parts = content['parts'] as List<dynamic>?;
          if (parts == null) continue;

          for (final part in parts) {
            final text = (part as Map<String, dynamic>)['text'] as String?;
            if (text != null && text.isNotEmpty) yield text;
          }
        } catch (e) {
          debugPrint('Stream parse error: $e | line: $trimmed');
        }
      }
    }

    // Flush any remaining data left in the buffer after the stream closes.
    final trimmed = buffer.trim();
    if (trimmed.startsWith('data: ')) {
      final jsonStr = trimmed.substring(6).trim();
      if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content =
            candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null) {
              for (final part in parts) {
                final text =
                (part as Map<String, dynamic>)['text'] as String?;
                if (text != null && text.isNotEmpty) yield text;
              }
            }
          }
        } catch (e) {
          debugPrint('Buffer flush parse error: $e');
        }
      }
    }
  }
}