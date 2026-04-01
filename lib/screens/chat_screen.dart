import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_model_config.dart';
import '../models/chat_message.dart';
import '../providers/provider_selection_notifier.dart';
import '../providers/chat_notifier.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'settings_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messages = ref.watch(chatProvider);
    final isLoading = ref.read(chatProvider.notifier).isLoading;
    final sel = ref.watch(providerSelectionProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _showModelPicker(context, ref, sel),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProviderLogo(providerName: sel.activeProvider?.name ?? ''),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  sel.isLoading
                      ? 'Loading...'
                      : (sel.activeModel?.displayName ?? 'Select model'),
                  style: GoogleFonts.roboto(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
        actions: [
          // API key warning indicator
          if (!sel.isLoading && !sel.isConfigured)
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              tooltip: 'API key not configured',
              onPressed: () => _openSettings(context),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _openSettings(context);
                  break;
                case 'clear':
                  ref.read(chatProvider.notifier).clearChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: _menuItem(context, Icons.settings_outlined, 'Settings'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: _menuItem(context, Icons.delete_outline, 'Clear chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Configuration banner
          if (!sel.isLoading && !sel.isConfigured)
            _ConfigBanner(onTap: () => _openSettings(context)),
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeScreen(context)
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isLatest = index == messages.length - 1;
                return MessageBubble(
                  message: message,
                  isLatest: isLatest,
                );
              },
            ),
          ),
          if (isLoading &&
              messages.isNotEmpty &&
              messages.last.type != MessageType.model)
            const TypingIndicator(),
          ChatInput(
            onSend: (text) => ref.read(chatProvider.notifier).sendMessage(text),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.roboto(color: colorScheme.onSurface)),
      ],
    );
  }

  void _openSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    ref.read(providerSelectionProvider.notifier).reload();
  }

  void _showModelPicker(
      BuildContext context, WidgetRef ref, ProviderSelectionState sel) {
    if (sel.models.isEmpty) {
      _openSettings(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickModelSheet(
        sel: sel,
        onSelectModel: (m) {
          ref.read(providerSelectionProvider.notifier).selectModel(m);
          Navigator.pop(context);
        },
        onOpenSettings: () {
          Navigator.pop(context);
          _openSettings(context);
        },
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sel = ref.watch(providerSelectionProvider);

    final suggestions = [
      ('Help me write a Flutter app', Icons.code_rounded),
      ('Explain quantum computing', Icons.science_rounded),
      ('Write a poem about coding', Icons.edit_rounded),
      ('Debug this error message', Icons.bug_report_rounded),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderLogo(
              providerName: sel.activeProvider?.name ?? '',
              size: 56,
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFF9B72CB),
                  Color(0xFFD96570),
                ],
              ).createShader(bounds),
              child: Text(
                'Hello, there',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sel.activeModel != null
                  ? 'Powered by ${sel.activeModel!.displayName}'
                  : 'How can I help you today?',
              style: GoogleFonts.roboto(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: suggestions.map((item) {
                return _SuggestionCard(
                  label: item.$1,
                  icon: item.$2,
                  onTap: () => ref.read(chatProvider.notifier).sendMessage(item.$1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Model Picker (inline bottom sheet) ──────────────────────────────────

class _QuickModelSheet extends StatelessWidget {
  final ProviderSelectionState sel;
  final void Function(AiModelConfig) onSelectModel;
  final VoidCallback onOpenSettings;

  const _QuickModelSheet({
    required this.sel,
    required this.onSelectModel,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sel.activeProvider?.name ?? 'Provider',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Manage'),
              ),
            ],
          ),
        ),
        ...sel.models.map((m) => ListTile(
          leading: Icon(Icons.memory_rounded, color: colorScheme.primary),
          title: Text(m.displayName,
              style: GoogleFonts.roboto(color: colorScheme.onSurface)),
          subtitle: Text(
            m.modelId,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: sel.activeModel?.id == m.id
              ? Icon(Icons.check_rounded, color: colorScheme.primary)
              : null,
          onTap: () => onSelectModel(m),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Config banner ─────────────────────────────────────────────────────────────

class _ConfigBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfigBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Colors.orange.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'API key not configured. Tap here to set up your provider.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.orange, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Provider Logo ─────────────────────────────────────────────────────────────

class _ProviderLogo extends StatelessWidget {
  final String providerName;
  final double size;

  const _ProviderLogo({required this.providerName, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final name = providerName.toLowerCase();
    List<Color> colors;
    IconData icon;

    if (name.contains('gemini')) {
      colors = const [
        Color(0xFF4285F4),
        Color(0xFF34A853),
        Color(0xFFFBBC05),
        Color(0xFFEA4335)
      ];
      icon = Icons.auto_awesome;
    } else if (name.contains('openrouter')) {
      colors = const [Color(0xFF6B46C1), Color(0xFF9F7AEA)];
      icon = Icons.route_rounded;
    } else if (name.contains('z.ai') || name.contains('xai')) {
      colors = const [Color(0xFF1a1a1a), Color(0xFF555555)];
      icon = Icons.bolt_rounded;
    } else {
      colors = [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.tertiary,
      ];
      icon = Icons.cloud_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

// ── Suggestion Card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            Text(
              label,
              style: GoogleFonts.roboto(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}