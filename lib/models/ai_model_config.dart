import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class AiModelConfig {
  final String id;
  final String providerId;
  final String modelId;
  final String displayName;
  final bool isDefault;

  const AiModelConfig({
    required this.id,
    required this.providerId,
    required this.modelId,
    required this.displayName,
    this.isDefault = false,
  });

  factory AiModelConfig.create({
    required String providerId,
    required String modelId,
    required String displayName,
    bool isDefault = false,
  }) {
    return AiModelConfig(
      id: _uuid.v4(),
      providerId: providerId,
      modelId: modelId,
      displayName: displayName,
      isDefault: isDefault,
    );
  }

  AiModelConfig copyWith({
    String? modelId,
    String? displayName,
    bool? isDefault,
  }) {
    return AiModelConfig(
      id: id,
      providerId: providerId,
      modelId: modelId ?? this.modelId,
      displayName: displayName ?? this.displayName,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'provider_id': providerId,
    'model_id': modelId,
    'display_name': displayName,
    'is_default': isDefault ? 1 : 0,
  };

  factory AiModelConfig.fromMap(Map<String, dynamic> map) => AiModelConfig(
    id: map['id'] as String,
    providerId: map['provider_id'] as String,
    modelId: map['model_id'] as String,
    displayName: map['display_name'] as String,
    isDefault: (map['is_default'] as int) == 1,
  );
}