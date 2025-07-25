import 'dart:convert';

class Reminder {
  final String id;
  final String petId;
  final String title;
  final String description;
  final DateTime date;
  final String type;
  final bool isCompleted;
  final bool repeat;
  final String? frequency;
  final DateTime? endDate;
  final String? additionalInfo;

  // For medication
  final String? dosage;

  // For feeding
  final String? portion;
  final String? mealType;

  // For vaccination
  final String? vetClinic;
  final String? vaccineRecordUrl;
  final DateTime? nextDueDate;
  
  Reminder({
    required this.id,
    required this.petId,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.isCompleted = false,
    this.repeat = false,
    this.frequency,
    this.endDate,
    this.additionalInfo,
    this.dosage,
    this.portion,
    this.mealType,
    this.vetClinic,
    this.vaccineRecordUrl,
    this.nextDueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'isCompleted': isCompleted,
      'repeat': repeat,
      'frequency': frequency,
      'endDate': endDate?.toIso8601String(),
      'additionalInfo': additionalInfo,
      'dosage': dosage,
      'portion': portion,
      'mealType': mealType,
      'vetClinic': vetClinic,
      'vaccineRecordUrl': vaccineRecordUrl,
      'nextDueDate': nextDueDate?.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      type: map['type'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      repeat: map['repeat'] ?? false,
      frequency: map['frequency'],
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      additionalInfo: map['additionalInfo'],
      dosage: map['dosage'],
      portion: map['portion'],
      mealType: map['mealType'],
      vetClinic: map['vetClinic'],
      vaccineRecordUrl: map['vaccineRecordUrl'],
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Reminder.fromJson(String source) => Reminder.fromMap(json.decode(source));

  Reminder copyWith({
    String? id,
    String? petId,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    bool? isCompleted,
    bool? repeat,
    String? frequency,
    DateTime? endDate,
    String? additionalInfo,
    String? dosage,
    String? portion,
    String? mealType,
    String? vetClinic,
    String? vaccineRecordUrl,
    DateTime? nextDueDate,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      repeat: repeat ?? this.repeat,
      frequency: frequency ?? this.frequency,
      endDate: endDate ?? this.endDate,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      dosage: dosage ?? this.dosage,
      portion: portion ?? this.portion,
      mealType: mealType ?? this.mealType,
      vetClinic: vetClinic ?? this.vetClinic,
      vaccineRecordUrl: vaccineRecordUrl ?? this.vaccineRecordUrl,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}
