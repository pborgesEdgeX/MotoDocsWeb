class AvailabilitySlot {
  final String id;
  final String mechanicId;
  final String? dayOfWeek;
  final DateTime? specificDate;
  final String startTime;
  final String endTime;
  final String timezone;
  final bool isRecurring;
  final int maxConcurrentCalls;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilitySlot({
    required this.id,
    required this.mechanicId,
    this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    required this.isRecurring,
    required this.maxConcurrentCalls,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      mechanicId: json['mechanic_id'] as String,
      dayOfWeek: json['day_of_week'] as String?,
      specificDate: json['specific_date'] != null
          ? DateTime.parse(json['specific_date'] as String)
          : null,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      timezone: json['timezone'] as String? ?? 'UTC',
      isRecurring: json['is_recurring'] as bool? ?? true,
      maxConcurrentCalls: json['max_concurrent_calls'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mechanic_id': mechanicId,
      'day_of_week': dayOfWeek,
      'specific_date': specificDate?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'timezone': timezone,
      'is_recurring': isRecurring,
      'max_concurrent_calls': maxConcurrentCalls,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AvailabilitySlot copyWith({
    String? id,
    String? mechanicId,
    String? dayOfWeek,
    DateTime? specificDate,
    String? startTime,
    String? endTime,
    String? timezone,
    bool? isRecurring,
    int? maxConcurrentCalls,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySlot(
      id: id ?? this.id,
      mechanicId: mechanicId ?? this.mechanicId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      specificDate: specificDate ?? this.specificDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      isRecurring: isRecurring ?? this.isRecurring,
      maxConcurrentCalls: maxConcurrentCalls ?? this.maxConcurrentCalls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

