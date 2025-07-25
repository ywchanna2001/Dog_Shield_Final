import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:uuid/uuid.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  // Get all pets for current user
  Future<List<Pet>> getPets() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found when trying to get pets');
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection(AppConstants.petsCollection)
          .where('ownerId', isEqualTo: user.uid)
          .get();

      return snapshot.docs
          .map((doc) => Pet.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pets: $e');
      if (e.toString().contains('User not logged in')) {
        rethrow; // Re-throw authentication errors as-is
      }
      throw Exception('Failed to load pets');
    }
  }

  // Get specific pet by ID
  Future<Pet> getPet(String petId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.petsCollection)
          .doc(petId)
          .get();

      if (!doc.exists) throw Exception('Pet not found');
      return Pet.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting pet: $e');
      throw Exception('Failed to load pet details');
    }
  }

  // Add new pet
  Future<Pet> addPet({
    required String name,
    required String breed,
    required DateTime dateOfBirth,
    required String gender,
    required bool isNeutered,
    required double weight,
    File? image,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadPetImage(image);
      }

      final petId = _uuid.v4();
      final pet = Pet(
        id: petId,
        name: name,
        breed: breed,
        dateOfBirth: dateOfBirth,
        gender: gender,
        isNeutered: isNeutered,
        weight: weight,
        imageUrl: imageUrl,
        ownerId: user.uid,
      );

      await _firestore
          .collection(AppConstants.petsCollection)
          .doc(petId)
          .set(pet.toMap());

      return pet;
    } catch (e) {
      print('Error adding pet: $e');
      throw Exception('Failed to add pet');
    }
  }

  // Update existing pet
  Future<Pet> updatePet({
    required String petId,
    String? name,
    String? breed,
    DateTime? dateOfBirth,
    String? gender,
    bool? isNeutered,
    double? weight,
    File? newImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current pet data
      final petDoc = await _firestore
          .collection(AppConstants.petsCollection)
          .doc(petId)
          .get();

      if (!petDoc.exists) throw Exception('Pet not found');
      
      final currentPet = Pet.fromMap(petDoc.data() as Map<String, dynamic>);
      
      // Check if pet belongs to current user
      if (currentPet.ownerId != user.uid) {
        throw Exception('You do not have permission to update this pet');
      }

      // Upload new image if provided
      String? imageUrl = currentPet.imageUrl;
      if (newImage != null) {
        imageUrl = await _uploadPetImage(newImage);
      }

      // Update pet with new data
      final updatedPet = currentPet.copyWith(
        name: name,
        breed: breed,
        dateOfBirth: dateOfBirth,
        gender: gender,
        isNeutered: isNeutered,
        weight: weight,
        imageUrl: imageUrl,
      );

      await _firestore
          .collection(AppConstants.petsCollection)
          .doc(petId)
          .update(updatedPet.toMap());

      return updatedPet;
    } catch (e) {
      print('Error updating pet: $e');
      throw Exception('Failed to update pet');
    }
  }

  // Delete pet
  Future<void> deletePet(String petId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get pet to check ownership
      final petDoc = await _firestore
          .collection(AppConstants.petsCollection)
          .doc(petId)
          .get();

      if (!petDoc.exists) throw Exception('Pet not found');
      
      final pet = Pet.fromMap(petDoc.data() as Map<String, dynamic>);
      
      // Check if pet belongs to current user
      if (pet.ownerId != user.uid) {
        throw Exception('You do not have permission to delete this pet');
      }

      // Delete pet image if exists
      if (pet.imageUrl != null) {
        try {
          await _storage.refFromURL(pet.imageUrl!).delete();
        } catch (e) {
          print('Error deleting pet image: $e');
          // Continue with pet deletion even if image deletion fails
        }
      }

      // Delete all reminders for this pet
      final remindersSnapshot = await _firestore
          .collection(AppConstants.remindersCollection)
          .where('petId', isEqualTo: petId)
          .get();
      
      final batch = _firestore.batch();
      
      for (var doc in remindersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the pet document
      batch.delete(_firestore.collection(AppConstants.petsCollection).doc(petId));
      
      await batch.commit();
    } catch (e) {
      print('Error deleting pet: $e');
      throw Exception('Failed to delete pet');
    }
  }

  // Upload pet image to Firebase Storage
  Future<String> _uploadPetImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('pet_images/$fileName');
      
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading pet image: $e');
      throw Exception('Failed to upload pet image');
    }
  }
}
