class Appointment {
  final String id;
  final String mechanicId;
  final String mechanicName;
  final String userUid;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String motorcycleModel;
  final String issueDescription;
  final DateTime scheduledTime;
  final int durationMinutes;
  final String status;
  final String? agoraChannelName;
  final String? agoraAppId;
  final DateTime? callStartTime;
  final DateTime? callEndTime;
  final int? rating;
  final String? review;
  final String? notes;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.mechanicId,
    required this.mechanicName,
    required this.userUid,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.motorcycleModel,
    required this.issueDescription,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.status,
    this.agoraChannelName,
    this.agoraAppId,
    this.callStartTime,
    this.callEndTime,
    this.rating,
    this.review,
    this.notes,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      mechanicId: json['mechanic_id'] as String,
      mechanicName: json['mechanic_name'] as String,
      userUid: json['user_uid'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      userPhone: json['user_phone'] as String?,
      motorcycleModel: json['motorcycle_model'] as String,
      issueDescription: json['issue_description'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      durationMinutes: json['duration_minutes'] as int,
      status: json['status'] as String,
      agoraChannelName: json['agora_channel_name'] as String?,
      agoraAppId: json['agora_app_id'] as String?,
      callStartTime: json['call_start_time'] != null
          ? DateTime.parse(json['call_start_time'] as String)
          : null,
      callEndTime: json['call_end_time'] != null
          ? DateTime.parse(json['call_end_time'] as String)
          : null,
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      notes: json['notes'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mechanic_id': mechanicId,
      'mechanic_name': mechanicName,
      'user_uid': userUid,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'motorcycle_model': motorcycleModel,
      'issue_description': issueDescription,
      'scheduled_time': scheduledTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status,
      'agora_channel_name': agoraChannelName,
      'agora_app_id': agoraAppId,
      'call_start_time': callStartTime?.toIso8601String(),
      'call_end_time': callEndTime?.toIso8601String(),
      'rating': rating,
      'review': review,
      'notes': notes,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  bool get isUpcoming {
    return status == 'scheduled' && scheduledTime.isAfter(DateTime.now());
  }

  bool get canJoin {
    return status == 'scheduled' &&
        scheduledTime.isBefore(DateTime.now().add(const Duration(minutes: 15)));
  }
}

