import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _model = 'gemini-2.5-flash';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ✅ PUBLIC GETTERS
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
        ]
      };
    }).toList();
  }

  // ✅ নন-স্ট্রিমিং
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
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw Exception('No content in candidate');
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in content');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        throw Exception('No text in part');
      }

      return text;
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response: $e');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ✅ স্ট্রিমিং
  Stream<String> sendMessageStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    if (!hasApiKey) {
      throw Exception('API Key not configured. Check .env file');
    }

    final uri = Uri.https(
      _baseUrl,
      '/v1beta/models/$_model:streamGenerateContent',
      {'key': _apiKey},
    );

    final body = jsonEncode({
      'contents': [
        ..._formatHistory(history),
        {
          'role': 'user',
          'parts': [
            {'text': message}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    });

    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('HTTP ${streamedResponse.statusCode}: $errorBody');
      }

      String buffer = '';

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();

          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6);

            if (jsonStr == '[DONE]') continue;
            if (jsonStr.isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;

              final candidates = data['candidates'] as List<dynamic>?;
              if (candidates == null || candidates.isEmpty) continue;

              final candidate = candidates[0] as Map<String, dynamic>;
              final content = candidate['content'] as Map<String, dynamic>?;
              if (content == null) continue;

              final parts = content['parts'] as List<dynamic>?;
              if (parts == null || parts.isEmpty) continue;

              final part = parts[0] as Map<String, dynamic>;
              final text = part['text'] as String?;

              if (text != null && text.isNotEmpty) {
                yield text;
              }

            } catch (e) {
              if (kDebugMode) print('Parse error: $e');
              continue;
            }
          }
        }
      }

      if (buffer.trim().startsWith('data: ')) {
        final jsonStr = buffer.trim().substring(6);
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            if (content != null) {
              final parts = content['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          }
        } catch (e) {
          // Ignore final buffer parse error
        }
      }

    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      throw Exception('Streaming error: $e');
    }
  }
}