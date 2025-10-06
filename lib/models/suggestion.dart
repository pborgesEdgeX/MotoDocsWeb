class Suggestion {
  final String query;
  final String? bikeModel;
  final Map<String, dynamic> answer;
  final int latencyMs;
  final DateTime createdAt;
  final String userUid;

  Suggestion({
    required this.query,
    this.bikeModel,
    required this.answer,
    required this.latencyMs,
    required this.createdAt,
    required this.userUid,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      query: json['query'] ?? '',
      bikeModel: json['bike_model'],
      answer: json['answer'] ?? {},
      latencyMs: json['latency_ms'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      userUid: json['user_uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'bike_model': bikeModel,
      'answer': answer,
      'latency_ms': latencyMs,
      'created_at': createdAt.toIso8601String(),
      'user_uid': userUid,
    };
  }
}
