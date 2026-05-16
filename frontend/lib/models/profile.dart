class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? pushToken;
  final String? skiLevel;
  final String? home;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.pushToken,
    this.skiLevel,
    this.home,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      pushToken: json['push_token'],
      skiLevel: json['ski_level'],
      home: json['home'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'push_token': pushToken,
      'ski_level': skiLevel,
      'home': home,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pushToken: pushToken ?? this.pushToken,
      skiLevel: skiLevel ?? this.skiLevel,
      home: home ?? this.home,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
