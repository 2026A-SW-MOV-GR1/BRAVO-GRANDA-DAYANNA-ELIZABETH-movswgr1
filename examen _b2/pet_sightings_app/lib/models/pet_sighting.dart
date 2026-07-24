enum PetType { perro, gato, otro }

enum SightingStatus { visto, encontrado }

extension PetTypeLabel on PetType {
  String get label {
    switch (this) {
      case PetType.perro:
        return 'Perro';
      case PetType.gato:
        return 'Gato';
      case PetType.otro:
        return 'Otro';
    }
  }
}

extension SightingStatusLabel on SightingStatus {
  String get label {
    switch (this) {
      case SightingStatus.visto:
        return 'Visto';
      case SightingStatus.encontrado:
        return 'Encontrado / Reunido';
    }
  }
}

class PetSighting {
  final String id;
  final String petName;
  final PetType petType;
  final String description;
  final String contactPhone;
  final double latitude;
  final double longitude;
  final DateTime sightedAt;
  final String? photoPath;
  final SightingStatus status;

  PetSighting({
    required this.id,
    required this.petName,
    required this.petType,
    required this.description,
    required this.contactPhone,
    required this.latitude,
    required this.longitude,
    required this.sightedAt,
    this.photoPath,
    this.status = SightingStatus.visto,
  });

  PetSighting copyWith({SightingStatus? status}) {
    return PetSighting(
      id: id,
      petName: petName,
      petType: petType,
      description: description,
      contactPhone: contactPhone,
      latitude: latitude,
      longitude: longitude,
      sightedAt: sightedAt,
      photoPath: photoPath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'petName': petName,
        'petType': petType.name,
        'description': description,
        'contactPhone': contactPhone,
        'latitude': latitude,
        'longitude': longitude,
        'sightedAt': sightedAt.toIso8601String(),
        'photoPath': photoPath,
        'status': status.name,
      };

  factory PetSighting.fromJson(Map<String, dynamic> json) => PetSighting(
        id: json['id'] as String,
        petName: json['petName'] as String,
        petType: PetType.values.firstWhere(
          (e) => e.name == json['petType'],
          orElse: () => PetType.otro,
        ),
        description: json['description'] as String,
        contactPhone: json['contactPhone'] as String,
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        sightedAt: DateTime.parse(json['sightedAt'] as String),
        photoPath: json['photoPath'] as String?,
        status: SightingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SightingStatus.visto,
        ),
      );
}
