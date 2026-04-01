import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _model = 'gemini-3-flash-preview';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

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

  Stream<String> sendMessageStream({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
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
        'maxOutputTokens': 8192,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    });

    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API Error ${streamedResponse.statusCode}: $errorBody');
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

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
              if (kDebugMode) print('Parse error: $e');
            }
          }
        }
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}