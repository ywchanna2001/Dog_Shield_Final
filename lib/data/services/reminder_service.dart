import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'package:dogshield_ai/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class ReminderService {
  // Singleton pattern to ensure a single shared instance across the app
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  NotificationService? _notificationService;

  // Method to set notification service to avoid circular dependency
  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  // Get all reminders for a specific pet
  Future<List<Reminder>> getPetReminders(String petId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found when trying to get reminders');
        throw Exception('User not logged in');
      }

      final snapshot =
          await _firestore.collection(AppConstants.remindersCollection).where('petId', isEqualTo: petId).get();

      final reminders = snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();

      // Sort manually instead of using orderBy to avoid Firebase index issues
      reminders.sort((a, b) => a.date.compareTo(b.date));

      return reminders;
    } catch (e) {
      print('Error getting reminders: $e');
      if (e.toString().contains('User not logged in')) {
        rethrow; // Re-throw authentication errors as-is
      }
      throw Exception('Failed to load reminders');
    }
  }

  // Get all reminders for current user (across all pets)
  Future<List<Reminder>> getAllReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found when trying to get all reminders');
        throw Exception('User not logged in');
      }

      // Get all pets for the current user
      final petsSnapshot =
          await _firestore.collection(AppConstants.petsCollection).where('ownerId', isEqualTo: user.uid).get();

      final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();

      if (petIds.isEmpty) return [];

      // Get reminders for all pets
      final remindersSnapshot =
          await _firestore.collection(AppConstants.remindersCollection).where('petId', whereIn: petIds).get();

      final reminders = remindersSnapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();

      // Sort manually instead of using orderBy to avoid Firebase index issues
      reminders.sort((a, b) => a.date.compareTo(b.date));

      return reminders;
    } catch (e) {
      print('Error getting all reminders: $e');
      if (e.toString().contains('User not logged in')) {
        rethrow; // Re-throw authentication errors as-is
      }
      throw Exception('Failed to load reminders');
    }
  }

  // Get upcoming reminders
  Future<List<Reminder>> getUpcomingReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get all pets for the current user
      final petsSnapshot =
          await _firestore.collection(AppConstants.petsCollection).where('ownerId', isEqualTo: user.uid).get();

      final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();

      if (petIds.isEmpty) return [];

      // Get all reminders for the user's pets
      final remindersSnapshot =
          await _firestore.collection(AppConstants.remindersCollection).where('petId', whereIn: petIds).get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter and sort in memory to avoid compound query index issues
      final reminders =
          remindersSnapshot.docs
              .map((doc) => Reminder.fromMap(doc.data()))
              .where(
                (reminder) => !reminder.isCompleted && reminder.date.isAfter(today.subtract(const Duration(days: 1))),
              )
              .toList();

      // Sort by date
      reminders.sort((a, b) => a.date.compareTo(b.date));

      return reminders;
    } catch (e) {
      print('Error getting upcoming reminders: $e');
      throw Exception('Failed to load upcoming reminders');
    }
  }

  // Add new reminder (generic base)
  Future<Reminder> _addReminderBase({
    required String petId,
    required String title,
    required String description,
    required DateTime date,
    required String type,
    bool repeat = false,
    String? frequency,
    DateTime? endDate,
    String? additionalInfo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Verify that the pet exists and belongs to the user
      final petDoc = await _firestore.collection(AppConstants.petsCollection).doc(petId).get();

      if (!petDoc.exists) throw Exception('Pet not found');

      final petData = petDoc.data();
      if (petData == null || petData['ownerId'] != user.uid) {
        throw Exception('You do not have permission to add reminders for this pet');
      }

      final reminderId = _uuid.v4();
      final reminder = Reminder(
        id: reminderId,
        petId: petId,
        title: title,
        description: description,
        date: date,
        type: type,
        repeat: repeat,
        frequency: frequency,
        endDate: endDate,
        additionalInfo: additionalInfo,
      );

      await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).set(reminder.toMap());

      // Schedule notification for the reminder if notification service is available
      await _notificationService?.scheduleReminderNotification(reminder);

      return reminder;
    } catch (e) {
      print('Error adding reminder: $e');
      throw Exception('Failed to add reminder');
    }
  }

  // Add medication reminder
  Future<Reminder> addMedicationReminder({
    required String petId,
    required String medicationName,
    required DateTime date,
    required String description,
    required String dosage,
    bool repeat = false,
    String? frequency,
    DateTime? endDate,
  }) async {
    try {
      return await _addReminderBase(
        petId: petId,
        title: medicationName,
        description: description,
        date: date,
        type: AppConstants.typeMedication,
        repeat: repeat,
        frequency: frequency,
        endDate: endDate,
        additionalInfo: 'Dosage: $dosage',
      ).then((reminder) {
        // Update with medication-specific fields
        return _firestore.collection(AppConstants.remindersCollection).doc(reminder.id).update({'dosage': dosage}).then(
          (_) {
            return reminder.copyWith(dosage: dosage);
          },
        );
      });
    } catch (e) {
      print('Error adding medication reminder: $e');
      throw Exception('Failed to add medication reminder');
    }
  }

  // Add feeding reminder
  Future<Reminder> addFeedingReminder({
    required String petId,
    required String mealName,
    required DateTime date,
    required String description,
    required String portion,
    required String mealType,
    bool repeat = false,
    String? frequency,
    String? additionalInfo,
  }) async {
    try {
      return await _addReminderBase(
        petId: petId,
        title: mealName,
        description: description,
        date: date,
        type: AppConstants.typeFeeding,
        repeat: repeat,
        frequency: frequency,
        additionalInfo: additionalInfo,
      ).then((reminder) {
        // Update with feeding-specific fields
        return _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id)
            .update({'portion': portion, 'mealType': mealType})
            .then((_) {
              return reminder.copyWith(portion: portion, mealType: mealType);
            });
      });
    } catch (e) {
      print('Error adding feeding reminder: $e');
      throw Exception('Failed to add feeding reminder');
    }
  }

  // Add generic reminder
  Future<Reminder> addGenericReminder({
    required String petId,
    required String title,
    required String description,
    required DateTime date,
    bool repeat = false,
    String? frequency,
    String? additionalInfo,
  }) async {
    try {
      return await _addReminderBase(
        petId: petId,
        title: title,
        description: description,
        date: date,
        type: AppConstants.typeOther,
        repeat: repeat,
        frequency: frequency,
        additionalInfo: additionalInfo,
      );
    } catch (e) {
      print('Error adding generic reminder: $e');
      throw Exception('Failed to add reminder');
    }
  }

  // Add vaccination reminder
  Future<Reminder> addVaccinationReminder({
    required String petId,
    required String vaccineName,
    required DateTime date,
    required String description,
    String? vetClinic,
    DateTime? nextDueDate,
    File? vaccineRecord,
  }) async {
    try {
      final reminder = await _addReminderBase(
        petId: petId,
        title: vaccineName,
        description: description,
        date: date,
        type: AppConstants.typeVaccination,
        additionalInfo: vetClinic != null ? 'Vet: $vetClinic' : null,
      );

      // Upload vaccine record if provided
      String? vaccineRecordUrl;
      if (vaccineRecord != null) {
        vaccineRecordUrl = await _uploadVaccineRecord(vaccineRecord);
      }

      // Update with vaccination-specific fields
      await _firestore.collection(AppConstants.remindersCollection).doc(reminder.id).update({
        'vetClinic': vetClinic,
        'nextDueDate': nextDueDate?.toIso8601String(),
        'vaccineRecordUrl': vaccineRecordUrl,
      });

      return reminder.copyWith(vetClinic: vetClinic, nextDueDate: nextDueDate, vaccineRecordUrl: vaccineRecordUrl);
    } catch (e) {
      print('Error adding vaccination reminder: $e');
      throw Exception('Failed to add vaccination reminder');
    }
  }

  // Update reminder status (mark as completed)
  Future<Reminder> updateReminderStatus(String reminderId, bool isCompleted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get the reminder
      final reminderDoc = await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).get();

      if (!reminderDoc.exists) throw Exception('Reminder not found');

      final reminder = Reminder.fromMap(reminderDoc.data() as Map<String, dynamic>);

      // Verify pet ownership
      final petDoc = await _firestore.collection(AppConstants.petsCollection).doc(reminder.petId).get();

      if (!petDoc.exists) throw Exception('Pet not found');

      final petData = petDoc.data();
      if (petData == null || petData['ownerId'] != user.uid) {
        throw Exception('You do not have permission to update this reminder');
      }

      // Update reminder status
      await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).update({
        'isCompleted': isCompleted,
      });

      return reminder.copyWith(isCompleted: isCompleted);
    } catch (e) {
      print('Error updating reminder status: $e');
      throw Exception('Failed to update reminder status');
    }
  }

  // Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get the reminder
      final reminderDoc = await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).get();

      if (!reminderDoc.exists) throw Exception('Reminder not found');

      final reminder = Reminder.fromMap(reminderDoc.data() as Map<String, dynamic>);

      // Verify pet ownership
      final petDoc = await _firestore.collection(AppConstants.petsCollection).doc(reminder.petId).get();

      if (!petDoc.exists) throw Exception('Pet not found');

      final petData = petDoc.data();
      if (petData == null || petData['ownerId'] != user.uid) {
        throw Exception('You do not have permission to delete this reminder');
      }

      // Delete vaccine record if exists
      if (reminder.vaccineRecordUrl != null) {
        try {
          await _storage.refFromURL(reminder.vaccineRecordUrl!).delete();
        } catch (e) {
          print('Error deleting vaccine record: $e');
          // Continue with reminder deletion even if record deletion fails
        }
      }

      // Delete the reminder
      await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).delete();
    } catch (e) {
      print('Error deleting reminder: $e');
      throw Exception('Failed to delete reminder');
    }
  }

  // Upload vaccine record to Firebase Storage
  Future<String> _uploadVaccineRecord(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileName = 'vaccine_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('vaccine_records/$fileName');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading vaccine record: $e');
      throw Exception('Failed to upload vaccine record');
    }
  }
}
