import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int notificationId;
  final DateTime createdAt; // ADDED THIS FIELD

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
    required this.notificationId,
    DateTime? createdAt, // ADDED THIS PARAMETER
  }) : createdAt = createdAt ?? DateTime.now();

  // For Firestore (uses Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type,
      'isCompleted': isCompleted,
      'repeat': repeat,
      'frequency': frequency,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'additionalInfo': additionalInfo,
      'dosage': dosage,
      'portion': portion,
      'mealType': mealType,
      'vetClinic': vetClinic,
      'vaccineRecordUrl': vaccineRecordUrl,
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'notificationId': notificationId,
      'createdAt': Timestamp.fromDate(createdAt), // ADDED THIS
    };
  }

  // From Firestore (converts Timestamp to DateTime)
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: _parseDate(map['date']),
      type: map['type'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      repeat: map['repeat'] ?? false,
      frequency: map['frequency'],
      endDate: map['endDate'] != null ? _parseDate(map['endDate']) : null,
      additionalInfo: map['additionalInfo'],
      dosage: map['dosage'],
      portion: map['portion'],
      mealType: map['mealType'],
      vetClinic: map['vetClinic'],
      vaccineRecordUrl: map['vaccineRecordUrl'],
      nextDueDate: map['nextDueDate'] != null ? _parseDate(map['nextDueDate']) : null,
      notificationId: map['notificationId'] ?? 0,
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : DateTime.now(), // ADDED THIS
    );
  }

  // Helper method to parse both Timestamp and String dates
  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    } else if (date is DateTime) {
      return date;
    }
    return DateTime.now();
  }

  // For JSON serialization (uses ISO8601 strings)
  Map<String, dynamic> toJsonMap() {
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
      'notificationId': notificationId,
      'createdAt': createdAt.toIso8601String(), // ADDED THIS
    };
  }

  String toJson() => json.encode(toJsonMap());

  factory Reminder.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
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
      notificationId: map['notificationId'] ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(), // ADDED THIS
    );
  }

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
    int? notificationId,
    DateTime? createdAt, // ADDED THIS
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
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt, // ADDED THIS
    );
  }
}