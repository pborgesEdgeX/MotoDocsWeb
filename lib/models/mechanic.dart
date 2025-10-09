class Mechanic {
  final String id;
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final List<String> specializations;
  final int experienceYears;
  final double rating;
  final int totalCalls;
  final String? profilePhotoUrl;
  final bool isAvailable;
  final double hourlyRate;
  final String? bio;
  final String timezone;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Mechanic({
    required this.id,
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.specializations,
    required this.experienceYears,
    required this.rating,
    required this.totalCalls,
    this.profilePhotoUrl,
    required this.isAvailable,
    required this.hourlyRate,
    this.bio,
    required this.timezone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    return Mechanic(
      id: json['id'] as String,
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      experienceYears: json['experience_years'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalCalls: json['total_calls'] as int? ?? 0,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      bio: json['bio'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'specializations': specializations,
      'experience_years': experienceYears,
      'rating': rating,
      'total_calls': totalCalls,
      'profile_photo_url': profilePhotoUrl,
      'is_available': isAvailable,
      'hourly_rate': hourlyRate,
      'bio': bio,
      'timezone': timezone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Mechanic copyWith({
    String? id,
    String? uid,
    String? email,
    String? name,
    String? phone,
    List<String>? specializations,
    int? experienceYears,
    double? rating,
    int? totalCalls,
    String? profilePhotoUrl,
    bool? isAvailable,
    double? hourlyRate,
    String? bio,
    String? timezone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mechanic(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specializations: specializations ?? this.specializations,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      totalCalls: totalCalls ?? this.totalCalls,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MechanicPublicInfo {
  final String id;
  final String name;
  final List<String> specializations;
  final int experienceYears;
  final double rating;
  final int totalCalls;
  final double hourlyRate;
  final bool isAvailable;
  final String? profilePhotoUrl;
  final String? bio;

  MechanicPublicInfo({
    required this.id,
    required this.name,
    required this.specializations,
    required this.experienceYears,
    required this.rating,
    required this.totalCalls,
    required this.hourlyRate,
    required this.isAvailable,
    this.profilePhotoUrl,
    this.bio,
  });

  factory MechanicPublicInfo.fromJson(Map<String, dynamic> json) {
    return MechanicPublicInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      experienceYears: json['experience_years'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalCalls: json['total_calls'] as int? ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] as bool? ?? false,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

