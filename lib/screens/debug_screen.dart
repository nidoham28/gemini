import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';  // ✅ ঠিক করা ইমপোর্ট
import '../services/gemini_service.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(geminiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(geminiServiceProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  service.hasApiKey ? Icons.check_circle : Icons.error,
                  color: service.hasApiKey ? Colors.green : Colors.red,
                ),
                title: const Text('API Key Status'),
                subtitle: Text(service.apiKeyStatus),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  onPressed: service.hasApiKey
                      ? () => _testNonStreaming(context, ref)
                      : null,
                  child: const Text('Test Non-Streaming'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: service.hasApiKey
                      ? () => _testStreaming(context, ref)
                      : null,
                  child: const Text('Test Streaming'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SingleChildScrollView(
                  child: Text('Results will appear here...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testNonStreaming(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(geminiServiceProvider);
      final result = await service.sendMessage(
        message: 'Say "Hello from Gemini" and nothing else',
        history: [],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success: $result')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  void _testStreaming(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(geminiServiceProvider);
      final stream = service.sendMessageStream(
        message: 'Count from 1 to 5 slowly',
        history: [],
      );

      String result = '';
      await for (final chunk in stream) {
        result += chunk;
        debugPrint('Chunk: $chunk');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stream complete: $result')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
}