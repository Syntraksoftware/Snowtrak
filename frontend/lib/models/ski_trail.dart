class SkiTrail {
  final String id;
  final String name;
  final String resort;
  final String country;
  final TrailDifficulty difficulty;
  final double lengthKm;
  final int elevationDropM;
  final bool isGroomed;
  final bool hasSnowmaking;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final List<String>? features;

  SkiTrail({
    required this.id,
    required this.name,
    required this.resort,
    required this.country,
    required this.difficulty,
    required this.lengthKm,
    required this.elevationDropM,
    this.isGroomed = true,
    this.hasSnowmaking = false,
    this.description,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.features,
  });

  factory SkiTrail.fromJson(Map<String, dynamic> json) {
    return SkiTrail(
      id: json['id'] as String,
      name: json['name'] as String,
      resort: json['resort'] as String,
      country: json['country'] as String,
      difficulty: trailDifficultyFromString(json['difficulty'] as String),
      lengthKm: (json['length_km'] as num).toDouble(),
      elevationDropM: json['elevation_drop_m'] as int,
      isGroomed: json['is_groomed'] as bool? ?? true,
      hasSnowmaking: json['has_snowmaking'] as bool? ?? false,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      imageUrl: json['image_url'] as String?,
      features: (json['features'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'resort': resort,
      'country': country,
      'difficulty': difficulty.name,
      'length_km': lengthKm,
      'elevation_drop_m': elevationDropM,
      'is_groomed': isGroomed,
      'has_snowmaking': hasSnowmaking,
      'description': description,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'features': features,
    };
  }
}

enum TrailDifficulty {
  green, // Beginner
  blue, // Intermediate
  red, // Advanced (European)
  black, // Expert
  doubleBlack, // Expert Only
}

extension TrailDifficultyExtension on TrailDifficulty {
  String get displayName {
    switch (this) {
      case TrailDifficulty.green:
        return 'Green (Beginner)';
      case TrailDifficulty.blue:
        return 'Blue (Intermediate)';
      case TrailDifficulty.red:
        return 'Red (Advanced)';
      case TrailDifficulty.black:
        return 'Black (Expert)';
      case TrailDifficulty.doubleBlack:
        return 'Double Black (Expert Only)';
    }
  }

  String get shortName {
    switch (this) {
      case TrailDifficulty.green:
        return 'Green';
      case TrailDifficulty.blue:
        return 'Blue';
      case TrailDifficulty.red:
        return 'Red';
      case TrailDifficulty.black:
        return 'Black';
      case TrailDifficulty.doubleBlack:
        return '◆◆';
    }
  }

  String get icon {
    switch (this) {
      case TrailDifficulty.green:
        return '●';
      case TrailDifficulty.blue:
        return '■';
      case TrailDifficulty.red:
        return '■';
      case TrailDifficulty.black:
        return '◆';
      case TrailDifficulty.doubleBlack:
        return '◆◆';
    }
  }

  int get color {
    switch (this) {
      case TrailDifficulty.green:
        return 0xFF4CAF50;
      case TrailDifficulty.blue:
        return 0xFF2196F3;
      case TrailDifficulty.red:
        return 0xFFE53935;
      case TrailDifficulty.black:
        return 0xFF212121;
      case TrailDifficulty.doubleBlack:
        return 0xFF212121;
    }
  }
}

TrailDifficulty trailDifficultyFromString(String value) {
  switch (value.toLowerCase()) {
    case 'green':
      return TrailDifficulty.green;
    case 'blue':
      return TrailDifficulty.blue;
    case 'red':
      return TrailDifficulty.red;
    case 'black':
      return TrailDifficulty.black;
    case 'doubleblack':
    case 'double_black':
      return TrailDifficulty.doubleBlack;
    default:
      return TrailDifficulty.blue;
  }
}
