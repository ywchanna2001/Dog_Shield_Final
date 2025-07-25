import 'dart:convert';

class Pet {
  final String id;
  final String name;
  final String breed;
  final DateTime dateOfBirth;
  final String gender;
  final bool isNeutered;
  final double weight;
  final String? imageUrl;
  final String ownerId;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.dateOfBirth,
    required this.gender,
    required this.isNeutered,
    required this.weight,
    this.imageUrl,
    required this.ownerId,
  });

  String get age {
    final now = DateTime.now();
    final years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      return '${years - 1} years';
    }
    return '$years years';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'isNeutered': isNeutered,
      'weight': weight,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      gender: map['gender'] ?? 'Male',
      isNeutered: map['isNeutered'] ?? false,
      weight: map['weight']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Pet.fromJson(String source) => Pet.fromMap(json.decode(source));

  Pet copyWith({
    String? id,
    String? name,
    String? breed,
    DateTime? dateOfBirth,
    String? gender,
    bool? isNeutered,
    double? weight,
    String? imageUrl,
    String? ownerId,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isNeutered: isNeutered ?? this.isNeutered,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
