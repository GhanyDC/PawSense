import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for pet breed data
class PetBreed {
  final String id;
  final String name;
  final String species; // 'cat' or 'dog'
  final String description;
  final String imageUrl;
  final List<String> commonHealthIssues;
  final String averageLifespan;
  final String sizeCategory;
  final String coatType;
  final String status; // 'active' or 'inactive'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  PetBreed({
    required this.id,
    required this.name,
    required this.species,
    this.description = '',
    this.imageUrl = '',
    this.commonHealthIssues = const [],
    this.averageLifespan = '',
    this.sizeCategory = '',
    this.coatType = '',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Create from Firestore document
  factory PetBreed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetBreed(
      id: doc.id,
      name: data['name'] ?? '',
      species: data['species'] ?? 'dog',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      commonHealthIssues: List<String>.from(data['commonHealthIssues'] ?? []),
      averageLifespan: data['averageLifespan'] ?? '',
      sizeCategory: data['sizeCategory'] ?? '',
      coatType: data['coatType'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Create from JSON map
  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? 'dog',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      commonHealthIssues: List<String>.from(json['commonHealthIssues'] ?? []),
      averageLifespan: json['averageLifespan'] ?? '',
      sizeCategory: json['sizeCategory'] ?? '',
      coatType: json['coatType'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? '',
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'description': description,
      'imageUrl': imageUrl,
      'commonHealthIssues': commonHealthIssues,
      'averageLifespan': averageLifespan,
      'sizeCategory': sizeCategory,
      'coatType': coatType,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  PetBreed copyWith({
    String? id,
    String? name,
    String? species,
    String? description,
    String? imageUrl,
    List<String>? commonHealthIssues,
    String? averageLifespan,
    String? sizeCategory,
    String? coatType,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PetBreed(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      commonHealthIssues: commonHealthIssues ?? this.commonHealthIssues,
      averageLifespan: averageLifespan ?? this.averageLifespan,
      sizeCategory: sizeCategory ?? this.sizeCategory,
      coatType: coatType ?? this.coatType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Check if breed is active
  bool get isActive => status == 'active';

  /// Get species display name
  String get speciesDisplayName => species == 'cat' ? 'Cat' : 'Dog';

  /// Get formatted description (truncated if needed)
  String getFormattedDescription({int maxLength = 60}) {
    if (description.isEmpty) return 'No description';
    if (description.length <= maxLength) return description;
    return '${description.substring(0, maxLength)}...';
  }

  @override
  String toString() {
    return 'PetBreed(id: $id, name: $name, species: $species, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetBreed && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum for breed species
enum BreedSpecies {
  all,
  cat,
  dog;

  String get value {
    switch (this) {
      case BreedSpecies.all:
        return 'all';
      case BreedSpecies.cat:
        return 'cat';
      case BreedSpecies.dog:
        return 'dog';
    }
  }

  String get displayName {
    switch (this) {
      case BreedSpecies.all:
        return 'All Species';
      case BreedSpecies.cat:
        return 'Cats';
      case BreedSpecies.dog:
        return 'Dogs';
    }
  }
}

/// Enum for breed status
enum BreedStatus {
  all,
  active,
  inactive;

  String get value {
    switch (this) {
      case BreedStatus.all:
        return 'all';
      case BreedStatus.active:
        return 'active';
      case BreedStatus.inactive:
        return 'inactive';
    }
  }

  String get displayName {
    switch (this) {
      case BreedStatus.all:
        return 'All Status';
      case BreedStatus.active:
        return 'Active';
      case BreedStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Enum for sort options
enum BreedSortOption {
  nameAsc,
  nameDesc,
  species,
  dateAdded;

  String get value {
    switch (this) {
      case BreedSortOption.nameAsc:
        return 'name_asc';
      case BreedSortOption.nameDesc:
        return 'name_desc';
      case BreedSortOption.species:
        return 'species';
      case BreedSortOption.dateAdded:
        return 'date_added';
    }
  }

  String get displayName {
    switch (this) {
      case BreedSortOption.nameAsc:
        return 'Name (A-Z)';
      case BreedSortOption.nameDesc:
        return 'Name (Z-A)';
      case BreedSortOption.species:
        return 'Species';
      case BreedSortOption.dateAdded:
        return 'Date Added';
    }
  }
}

/// Size category options
class SizeCategory {
  static const String small = 'small';
  static const String medium = 'medium';
  static const String large = 'large';
  static const String extraLarge = 'extra_large';

  static List<String> get all => [small, medium, large, extraLarge];

  static String getDisplayName(String category) {
    switch (category) {
      case small:
        return 'Small';
      case medium:
        return 'Medium';
      case large:
        return 'Large';
      case extraLarge:
        return 'Extra Large';
      default:
        return category;
    }
  }
}

/// Coat type options
class CoatType {
  static const String short = 'short';
  static const String medium = 'medium';
  static const String long = 'long';
  static const String hairless = 'hairless';

  static List<String> get all => [short, medium, long, hairless];

  static String getDisplayName(String type) {
    switch (type) {
      case short:
        return 'Short';
      case medium:
        return 'Medium';
      case long:
        return 'Long';
      case hairless:
        return 'Hairless';
      default:
        return type;
    }
  }
}
