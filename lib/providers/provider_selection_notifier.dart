import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_model_config.dart';
import '../models/ai_provider.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

// ── Singleton DB provider ────────────────────────────────────────────────────

final databaseServiceProvider =
Provider<DatabaseService>((ref) => DatabaseService());

// ── Selection state ──────────────────────────────────────────────────────────

class ProviderSelectionState {
  final List<AiProvider> providers;
  final List<AiModelConfig> models;
  final AiProvider? activeProvider;
  final AiModelConfig? activeModel;
  final bool isLoading;

  const ProviderSelectionState({
    this.providers = const [],
    this.models = const [],
    this.activeProvider,
    this.activeModel,
    this.isLoading = true,
  });

  ProviderSelectionState copyWith({
    List<AiProvider>? providers,
    List<AiModelConfig>? models,
    AiProvider? activeProvider,
    AiModelConfig? activeModel,
    bool? isLoading,
    bool clearActiveProvider = false,
    bool clearActiveModel = false,
  }) {
    return ProviderSelectionState(
      providers: providers ?? this.providers,
      models: models ?? this.models,
      activeProvider:
      clearActiveProvider ? null : (activeProvider ?? this.activeProvider),
      activeModel:
      clearActiveModel ? null : (activeModel ?? this.activeModel),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isConfigured =>
      activeProvider != null &&
          activeModel != null &&
          activeProvider!.apiKey.isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProviderSelectionNotifier
    extends StateNotifier<ProviderSelectionState> {
  final DatabaseService _db;

  ProviderSelectionNotifier(this._db)
      : super(const ProviderSelectionState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);

    final providers = await _db.getProviders();
    final activeProviderId = await _db.getSetting('active_provider_id');
    final activeModelId = await _db.getSetting('active_model_id');

    AiProvider? activeProvider = _findById(providers, activeProviderId);
    activeProvider ??= providers.isNotEmpty ? providers.first : null;

    List<AiModelConfig> models = [];
    AiModelConfig? activeModel;

    if (activeProvider != null) {
      models = await _db.getModels(activeProvider.id);
      activeModel = _findById(models, activeModelId);
      activeModel ??=
          _findDefault(models) ?? (models.isNotEmpty ? models.first : null);
    }

    state = ProviderSelectionState(
      providers: providers,
      models: models,
      activeProvider: activeProvider,
      activeModel: activeModel,
      isLoading: false,
    );
  }

  /// Switch the active provider and auto-select its default model.
  Future<void> selectProvider(AiProvider provider) async {
    final models = await _db.getModels(provider.id);
    final defaultModel =
        _findDefault(models) ?? (models.isNotEmpty ? models.first : null);

    await _db.setSetting('active_provider_id', provider.id);
    if (defaultModel != null) {
      await _db.setSetting('active_model_id', defaultModel.id);
    }

    state = state.copyWith(
      activeProvider: provider,
      activeModel: defaultModel,
      models: models,
    );
  }

  /// Switch only the model within the current provider.
  Future<void> selectModel(AiModelConfig model) async {
    await _db.setSetting('active_model_id', model.id);
    state = state.copyWith(activeModel: model);
  }

  /// Call after any provider/model CRUD to sync state with DB.
  Future<void> reload() => _load();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  T? _findById<T>(List<T> list, String? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item is AiProvider && item.id == id) return item;
      if (item is AiModelConfig && item.id == id) return item;
    }
    return null;
  }

  AiModelConfig? _findDefault(List<AiModelConfig> models) {
    for (final m in models) {
      if (m.isDefault) return m;
    }
    return null;
  }
}

// ── Riverpod providers ───────────────────────────────────────────────────────

final providerSelectionProvider =
StateNotifierProvider<ProviderSelectionNotifier, ProviderSelectionState>(
        (ref) => ProviderSelectionNotifier(ref.read(databaseServiceProvider)));

/// Derives a ready-to-use [AiService] from the active selection.
/// Returns null when no provider/model is selected.
final aiServiceProvider = Provider<AiService?>((ref) {
  final sel = ref.watch(providerSelectionProvider);
  if (sel.activeProvider == null || sel.activeModel == null) return null;
  return AiService(
    provider: sel.activeProvider!,
    model: sel.activeModel!,
  );
});