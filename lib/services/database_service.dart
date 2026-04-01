import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/ai_model_config.dart';
import '../models/ai_provider.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_providers.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE providers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        base_url TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        api_key TEXT NOT NULL,
        format TEXT NOT NULL,
        is_built_in INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE models (
        id TEXT PRIMARY KEY,
        provider_id TEXT NOT NULL,
        model_id TEXT NOT NULL,
        display_name TEXT NOT NULL,
        is_default INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedBuiltInProviders(db);
  }

  Future<void> _seedBuiltInProviders(Database db) async {
    final gemini = AiProvider.create(
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com',
      endpoint: '/v1beta/models/{model}:streamGenerateContent',
      apiKey: '',
      format: ApiFormat.gemini,
      isBuiltIn: true,
    );

    final openRouter = AiProvider.create(
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai',
      endpoint: '/api/v1/chat/completions',
      apiKey: '',
      format: ApiFormat.openai,
      isBuiltIn: true,
    );

    final zai = AiProvider.create(
      name: 'Z.ai',
      baseUrl: 'https://api.z.ai',
      endpoint: '/v1/chat/completions',
      apiKey: '',
      format: ApiFormat.openai,
      isBuiltIn: true,
    );

    await db.insert('providers', gemini.toMap());
    await db.insert('providers', openRouter.toMap());
    await db.insert('providers', zai.toMap());

    // ── Gemini models ──────────────────────────────────────────────
    final geminiFlash = AiModelConfig.create(
      providerId: gemini.id,
      modelId: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      isDefault: true,
    );
    final geminiPro = AiModelConfig.create(
      providerId: gemini.id,
      modelId: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
    );
    final gemini15 = AiModelConfig.create(
      providerId: gemini.id,
      modelId: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash',
    );

    // ── OpenRouter models ──────────────────────────────────────────
    final orGpt4o = AiModelConfig.create(
      providerId: openRouter.id,
      modelId: 'openai/gpt-4o',
      displayName: 'GPT-4o',
      isDefault: true,
    );
    final orClaude = AiModelConfig.create(
      providerId: openRouter.id,
      modelId: 'anthropic/claude-sonnet-4-5',
      displayName: 'Claude Sonnet 4.5',
    );
    final orMistral = AiModelConfig.create(
      providerId: openRouter.id,
      modelId: 'mistralai/mistral-large',
      displayName: 'Mistral Large',
    );

    // ── Z.ai models ────────────────────────────────────────────────
    final zaiModel = AiModelConfig.create(
      providerId: zai.id,
      modelId: 'z1-32b',
      displayName: 'Z1-32B',
      isDefault: true,
    );

    for (final m in [
      geminiFlash,
      geminiPro,
      gemini15,
      orGpt4o,
      orClaude,
      orMistral,
      zaiModel,
    ]) {
      await db.insert('models', m.toMap());
    }

    // Default active selection: Gemini Flash
    await db.insert('settings', {'key': 'active_provider_id', 'value': gemini.id});
    await db.insert('settings', {'key': 'active_model_id', 'value': geminiFlash.id});
  }

  // ── Providers ────────────────────────────────────────────────────

  Future<List<AiProvider>> getProviders() async {
    final db = await database;
    final maps = await db.query('providers', orderBy: 'created_at ASC');
    return maps.map(AiProvider.fromMap).toList();
  }

  Future<AiProvider?> getProvider(String id) async {
    final db = await database;
    final maps = await db.query('providers', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : AiProvider.fromMap(maps.first);
  }

  Future<void> insertProvider(AiProvider provider) async {
    final db = await database;
    await db.insert('providers', provider.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProvider(AiProvider provider) async {
    final db = await database;
    await db.update('providers', provider.toMap(),
        where: 'id = ?', whereArgs: [provider.id]);
  }

  Future<void> deleteProvider(String id) async {
    final db = await database;
    await db.delete('providers', where: 'id = ?', whereArgs: [id]);
    await db.delete('models', where: 'provider_id = ?', whereArgs: [id]);
  }

  // ── Models ───────────────────────────────────────────────────────

  Future<List<AiModelConfig>> getModels(String providerId) async {
    final db = await database;
    final maps = await db.query('models',
        where: 'provider_id = ?', whereArgs: [providerId]);
    return maps.map(AiModelConfig.fromMap).toList();
  }

  Future<AiModelConfig?> getModel(String id) async {
    final db = await database;
    final maps = await db.query('models', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : AiModelConfig.fromMap(maps.first);
  }

  Future<void> insertModel(AiModelConfig model) async {
    final db = await database;
    await db.insert('models', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateModel(AiModelConfig model) async {
    final db = await database;
    await db.update('models', model.toMap(),
        where: 'id = ?', whereArgs: [model.id]);
  }

  Future<void> deleteModel(String id) async {
    final db = await database;
    await db.delete('models', where: 'id = ?', whereArgs: [id]);
  }

  // ── Settings ─────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return maps.isEmpty ? null : maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}