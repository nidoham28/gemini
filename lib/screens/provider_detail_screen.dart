import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_model_config.dart';
import '../models/ai_provider.dart';
import '../providers/provider_selection_notifier.dart';
import '../services/database_service.dart';

class ProviderDetailScreen extends ConsumerStatefulWidget {
  final AiProvider? provider; // null = create new

  const ProviderDetailScreen({super.key, this.provider});

  @override
  ConsumerState<ProviderDetailScreen> createState() =>
      _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _apiKeyCtrl;

  late ApiFormat _format;
  bool _obscureKey = true;
  bool _isSaving = false;

  List<AiModelConfig> _models = [];
  bool _modelsLoading = true;

  DatabaseService get _db => ref.read(databaseServiceProvider);

  bool get _isEditing => widget.provider != null;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _baseUrlCtrl = TextEditingController(text: p?.baseUrl ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _apiKeyCtrl = TextEditingController(text: p?.apiKey ?? '');
    _format = p?.format ?? ApiFormat.openai;

    if (_isEditing) _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _modelsLoading = true);
    final models = await _db.getModels(widget.provider!.id);
    if (mounted)
      setState(() {
        _models = models;
        _modelsLoading = false;
      });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _baseUrlCtrl.dispose();
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updated = widget.provider!.copyWith(
          name: _nameCtrl.text.trim(),
          baseUrl: _baseUrlCtrl.text.trim(),
          endpoint: _endpointCtrl.text.trim(),
          apiKey: _apiKeyCtrl.text.trim(),
          format: _format,
        );
        await _db.updateProvider(updated);
      } else {
        final newProvider = AiProvider.create(
          name: _nameCtrl.text.trim(),
          baseUrl: _baseUrlCtrl.text.trim(),
          endpoint: _endpointCtrl.text.trim(),
          apiKey: _apiKeyCtrl.text.trim(),
          format: _format,
        );
        await _db.insertProvider(newProvider);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete Provider ───────────────────────────────────────────────────────

  Future<void> _deleteProvider() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text(
            'Remove "${widget.provider!.name}" and all its models? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteProvider(widget.provider!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Add Model ─────────────────────────────────────────────────────────────

  Future<void> _showAddModelDialog() async {
    final modelIdCtrl = TextEditingController();
    final displayNameCtrl = TextEditingController();
    bool isDefault = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Model'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model ID',
                  hintText: 'e.g. gemini-2.5-flash',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. Gemini 2.5 Flash',
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setS(() => isDefault = v ?? false),
                title: const Text('Set as default'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (modelIdCtrl.text.isEmpty || displayNameCtrl.text.isEmpty) {
                  return;
                }
                final model = AiModelConfig.create(
                  providerId: widget.provider!.id,
                  modelId: modelIdCtrl.text.trim(),
                  displayName: displayNameCtrl.text.trim(),
                  isDefault: isDefault,
                );
                await _db.insertModel(model);
                Navigator.pop(ctx);
                await _loadModels();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    modelIdCtrl.dispose();
    displayNameCtrl.dispose();
  }

  Future<void> _deleteModel(AiModelConfig model) async {
    await _db.deleteModel(model.id);
    await _loadModels();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? widget.provider!.name : 'New Provider',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing && !widget.provider!.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _deleteProvider,
              tooltip: 'Delete provider',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Provider Details ───────────────────────────────────
            _SectionLabel(label: 'Provider Details'),
            const SizedBox(height: 12),
            _buildField(
              controller: _nameCtrl,
              label: 'Name',
              hint: 'e.g. My Custom Provider',
              icon: Icons.label_outline_rounded,
              validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _baseUrlCtrl,
              label: 'Base URL',
              hint: 'https://api.example.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: (v) {
                final s = v!.trim();
                if (s.isEmpty) return 'Base URL is required';
                if (!s.startsWith('http')) return 'Must start with http(s)://';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _endpointCtrl,
              label: 'Endpoint Path',
              hint: '/v1/chat/completions',
              icon: Icons.route_rounded,
              validator: (v) {
                final s = v!.trim();
                if (s.isEmpty) return 'Endpoint is required';
                if (!s.startsWith('/')) return 'Must start with /';
                return null;
              },
            ),
            const SizedBox(height: 12),
            // API Key field
            TextFormField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              style: GoogleFonts.robotoMono(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            // Format selector
            _SectionLabel(label: 'API Format'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FormatButton(
                    label: 'Gemini',
                    subtitle: 'Google native',
                    icon: Icons.auto_awesome,
                    selected: _format == ApiFormat.gemini,
                    onTap: () => setState(() => _format = ApiFormat.gemini),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatButton(
                    label: 'OpenAI',
                    subtitle: 'Compatible API',
                    icon: Icons.api_rounded,
                    selected: _format == ApiFormat.openai,
                    onTap: () => setState(() => _format = ApiFormat.openai),
                  ),
                ),
              ],
            ),
            // ── Models Section (only when editing) ─────────────────
            if (_isEditing) ...[
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(label: 'Models'),
                  TextButton.icon(
                    onPressed: _showAddModelDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Model'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_modelsLoading)
                const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ))
              else if (_models.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No models yet. Add at least one model to use this provider.',
                      style: GoogleFonts.roboto(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _models.map((model) {
                      return ListTile(
                        leading: Icon(Icons.memory_rounded,
                            color: colorScheme.primary, size: 20),
                        title: Text(
                          model.displayName,
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          model.modelId,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (model.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                              onPressed: () => _deleteModel(model),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 32),
            // ── Save Button ────────────────────────────────────────
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(
                _isEditing ? 'Save Changes' : 'Create Provider',
                style: GoogleFonts.roboto(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                )),
            Text(subtitle,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}