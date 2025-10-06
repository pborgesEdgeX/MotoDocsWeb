class Document {
  final String id;
  final String name;
  final String sourceUri;
  final String mimeType;
  final List<String> bikeModels;
  final List<String> components;
  final List<String> tags;
  final String visibility;
  final String status;
  final int? progressPercentage;
  final String? progressMessage;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.name,
    required this.sourceUri,
    required this.mimeType,
    required this.bikeModels,
    required this.components,
    required this.tags,
    required this.visibility,
    required this.status,
    this.progressPercentage,
    this.progressMessage,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sourceUri: json['source_uri'] ?? '',
      mimeType: json['mime_type'] ?? '',
      bikeModels: List<String>.from(json['bike_models'] ?? []),
      components: List<String>.from(json['components'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      visibility: json['visibility'] ?? 'public',
      status: json['status'] ?? 'UPLOADED',
      progressPercentage: json['progress_percentage'],
      progressMessage: json['progress_message'],
      error: json['error'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source_uri': sourceUri,
      'mime_type': mimeType,
      'bike_models': bikeModels,
      'components': components,
      'tags': tags,
      'visibility': visibility,
      'status': status,
      'progress_percentage': progressPercentage,
      'progress_message': progressMessage,
      'error': error,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
