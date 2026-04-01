import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ai_model_config.dart';
import '../models/ai_provider.dart';
import '../providers/provider_selection_notifier.dart';
import 'provider_detail_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(providerSelectionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: sel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // ── Active Selection ────────────────────────────────
          _SectionHeader(label: 'Active Configuration'),
          _ActiveSelectionCard(sel: sel, ref: ref),
          const SizedBox(height: 8),
          // ── Providers ───────────────────────────────────────
          _SectionHeader(label: 'Providers'),
          ...sel.providers.map((p) => _ProviderTile(
            provider: p,
            isActive: sel.activeProvider?.id == p.id,
            onTap: () => _openProviderDetail(context, ref, p),
            onSelect: () => ref
                .read(providerSelectionProvider.notifier)
                .selectProvider(p),
          )),
          const SizedBox(height: 12),
          // ── Add Custom Provider ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _openProviderDetail(context, ref, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Custom Provider'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openProviderDetail(
      BuildContext context, WidgetRef ref, AiProvider? provider) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(provider: provider),
      ),
    );
    ref.read(providerSelectionProvider.notifier).reload();
  }
}

// ── Active Selection Card ─────────────────────────────────────────────────────

class _ActiveSelectionCard extends ConsumerWidget {
  final ProviderSelectionState sel;
  final WidgetRef ref;

  const _ActiveSelectionCard({required this.sel, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasKey = sel.activeProvider?.apiKey.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Provider row
          ListTile(
            leading: _ProviderIcon(provider: sel.activeProvider),
            title: Text(
              sel.activeProvider?.name ?? 'None selected',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Provider',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(configured: hasKey),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              ],
            ),
            onTap: () => _showProviderPicker(context, ref),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.4)),
          // Model row
          ListTile(
            leading: Icon(Icons.memory_rounded, color: colorScheme.primary),
            title: Text(
              sel.activeModel?.displayName ?? 'No model',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              sel.activeModel?.modelId ?? '',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant),
            onTap: () => _showModelPicker(context, ref),
          ),
        ],
      ),
    );
  }

  void _showProviderPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProviderPickerSheet(
        providers: sel.providers,
        activeId: sel.activeProvider?.id,
        onSelect: (p) {
          ref.read(providerSelectionProvider.notifier).selectProvider(p);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModelPickerSheet(
        models: sel.models,
        activeId: sel.activeModel?.id,
        onSelect: (m) {
          ref.read(providerSelectionProvider.notifier).selectModel(m);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Provider Tile ─────────────────────────────────────────────────────────────

class _ProviderTile extends StatelessWidget {
  final AiProvider provider;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _ProviderTile({
    required this.provider,
    required this.isActive,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final configured = provider.apiKey.isNotEmpty;

    return ListTile(
      leading: _ProviderIcon(provider: provider),
      title: Text(
        provider.name,
        style: GoogleFonts.roboto(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          _FormatBadge(format: provider.format),
          const SizedBox(width: 6),
          _StatusChip(configured: configured),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(Icons.radio_button_checked_rounded,
                color: colorScheme.primary, size: 20)
          else
            IconButton(
              icon: Icon(Icons.radio_button_unchecked_rounded,
                  color: colorScheme.onSurfaceVariant, size: 20),
              onPressed: onSelect,
              tooltip: 'Use this provider',
            ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: colorScheme.onSurfaceVariant, size: 20),
            onPressed: onTap,
            tooltip: 'Configure',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Pickers (Bottom Sheets) ───────────────────────────────────────────────────

class _ProviderPickerSheet extends StatelessWidget {
  final List<AiProvider> providers;
  final String? activeId;
  final void Function(AiProvider) onSelect;

  const _ProviderPickerSheet({
    required this.providers,
    required this.activeId,
    required this.onSelect,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Provider',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        ...providers.map((p) => ListTile(
          leading: _ProviderIcon(provider: p),
          title: Text(p.name,
              style: GoogleFonts.roboto(color: colorScheme.onSurface)),
          subtitle: _FormatBadge(format: p.format),
          trailing: activeId == p.id
              ? Icon(Icons.check_rounded, color: colorScheme.primary)
              : null,
          onTap: () => onSelect(p),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ModelPickerSheet extends StatelessWidget {
  final List<AiModelConfig> models;
  final String? activeId;
  final void Function(AiModelConfig) onSelect;

  const _ModelPickerSheet({
    required this.models,
    required this.activeId,
    required this.onSelect,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Model',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (models.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No models available. Add a model in provider settings.',
              style: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...models.map((m) => ListTile(
            leading: Icon(Icons.memory_rounded, color: colorScheme.primary),
            title: Text(m.displayName,
                style: GoogleFonts.roboto(color: colorScheme.onSurface)),
            subtitle: Text(
              m.modelId,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: activeId == m.id
                ? Icon(Icons.check_rounded, color: colorScheme.primary)
                : null,
            onTap: () => onSelect(m),
          )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _ProviderIcon extends StatelessWidget {
  final AiProvider? provider;
  const _ProviderIcon({this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (provider == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.cloud_off_rounded,
            size: 18, color: colorScheme.onSurfaceVariant),
      );
    }

    final name = provider!.name.toLowerCase();
    if (name.contains('gemini')) {
      return _GradientAvatar(
        colors: const [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335)
        ],
        icon: Icons.auto_awesome,
      );
    } else if (name.contains('openrouter')) {
      return _GradientAvatar(
        colors: const [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
        icon: Icons.route_rounded,
      );
    } else if (name.contains('z.ai') || name.contains('xai') || name.contains('grok')) {
      return _GradientAvatar(
        colors: const [Color(0xFF1a1a1a), Color(0xFF4a4a4a)],
        icon: Icons.bolt_rounded,
      );
    } else {
      return _GradientAvatar(
        colors: [colorScheme.primary, colorScheme.tertiary],
        icon: Icons.cloud_rounded,
      );
    }
  }
}

class _GradientAvatar extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  const _GradientAvatar({required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final ApiFormat format;
  const _FormatBadge({required this.format});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGemini = format == ApiFormat.gemini;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGemini
            ? const Color(0xFF4285F4).withOpacity(0.12)
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isGemini ? 'Gemini' : 'OpenAI',
        style: GoogleFonts.robotoMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isGemini ? const Color(0xFF4285F4) : colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool configured;
  const _StatusChip({required this.configured});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: configured
            ? Colors.green.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            configured ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 10,
            color: configured ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            configured ? 'Ready' : 'No key',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: configured ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}