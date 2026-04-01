import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ApiFormat { gemini, openai }

class AiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String endpoint;
  final String apiKey;
  final ApiFormat format;
  final bool isBuiltIn;
  final bool isEnabled;
  final int createdAt;

  const AiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.endpoint,
    required this.apiKey,
    required this.format,
    this.isBuiltIn = false,
    this.isEnabled = true,
    required this.createdAt,
  });

  factory AiProvider.create({
    required String name,
    required String baseUrl,
    required String endpoint,
    required String apiKey,
    required ApiFormat format,
    bool isBuiltIn = false,
  }) {
    return AiProvider(
      id: _uuid.v4(),
      name: name,
      baseUrl: baseUrl,
      endpoint: endpoint,
      apiKey: apiKey,
      format: format,
      isBuiltIn: isBuiltIn,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  AiProvider copyWith({
    String? name,
    String? baseUrl,
    String? endpoint,
    String? apiKey,
    ApiFormat? format,
    bool? isEnabled,
  }) {
    return AiProvider(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      format: format ?? this.format,
      isBuiltIn: isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'base_url': baseUrl,
    'endpoint': endpoint,
    'api_key': apiKey,
    'format': format.name,
    'is_built_in': isBuiltIn ? 1 : 0,
    'is_enabled': isEnabled ? 1 : 0,
    'created_at': createdAt,
  };

  factory AiProvider.fromMap(Map<String, dynamic> map) => AiProvider(
    id: map['id'] as String,
    name: map['name'] as String,
    baseUrl: map['base_url'] as String,
    endpoint: map['endpoint'] as String,
    apiKey: map['api_key'] as String,
    format: ApiFormat.values.firstWhere(
          (e) => e.name == map['format'],
      orElse: () => ApiFormat.openai,
    ),
    isBuiltIn: (map['is_built_in'] as int) == 1,
    isEnabled: (map['is_enabled'] as int) == 1,
    createdAt: map['created_at'] as int,
  );
}