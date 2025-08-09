import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _petService = PetService();

  String _gender = 'Male';
  DateTime? _dateOfBirth;
  File? _petImage;
  bool _isNeutered = false;
  bool _isLoading = false;

  // Sample breed list
  final List<String> _dogBreeds = [
    'Labrador Retriever',
    'German Shepherd',
    'Golden Retriever',
    'Bulldog',
    'Beagle',
    'Poodle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Siberian Husky',
    'Great Dane',
    'Doberman Pinscher',
    'Shih Tzu',
    'Chihuahua',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _petImage = File(image.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _petImage = File(image.path);
      });
    }
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor)),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;

        // Calculate age based on date of birth
        final now = DateTime.now();
        final age = now.year - picked.year;

        if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
          _ageController.text = '${age - 1} years';
        } else {
          _ageController.text = '$age years';
        }
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the PetService to save the pet to Firebase
      await _petService.addPet(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        dateOfBirth: _dateOfBirth ?? DateTime.now(),
        gender: _gender,
        isNeutered: _isNeutered,
        weight: double.parse(_weightController.text),
        image: _petImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pet added successfully'), backgroundColor: Colors.green));
        // Navigate back to home screen
        Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pet: ${e.toString()}'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Pet'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Saving pet...')],
                ),
              )
              : SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pet Image
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => _buildImageSourceSelection(),
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                image:
                                    _petImage != null
                                        ? DecorationImage(image: FileImage(_petImage!), fit: BoxFit.cover)
                                        : null,
                              ),
                              child:
                                  _petImage == null
                                      ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.pets, size: 40, color: AppTheme.primaryColor),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      )
                                      : Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          Container(), // Empty container for the stack to work with the image
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppTheme.primaryColor,
                                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pet Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Pet Name',
                            hintText: 'Enter your pet\'s name',
                            prefixIcon: Icon(Icons.pets),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your pet\'s name';
                            }
                            if (value.length < AppConstants.petNameMinLength) {
                              return 'Name must be at least ${AppConstants.petNameMinLength} characters';
                            }
                            if (value.length > AppConstants.petNameMaxLength) {
                              return 'Name must be at most ${AppConstants.petNameMaxLength} characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Breed
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Breed',
                            hintText: 'Select your pet\'s breed',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items:
                              _dogBreeds.map((String breed) {
                                return DropdownMenuItem<String>(value: breed, child: Text(breed));
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _breedController.text = value;
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your pet\'s breed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender
                        Row(
                          children: [
                            const Text('Gender:'),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                            const Text('Male'),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                            const Text('Female'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                hintText: 'Select date of birth',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text:
                                    _dateOfBirth == null
                                        ? ''
                                        : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                              ),
                              validator: (value) {
                                if (_dateOfBirth == null) {
                                  return 'Please select your pet\'s date of birth';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Age
                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            hintText: 'Pet\'s age (will be calculated from birth date)',
                            prefixIcon: Icon(Icons.timelapse),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Weight
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'Enter your pet\'s weight',
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your pet\'s weight';
                            }
                            // Check if it's a valid number
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid weight';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Neutered/Spayed
                        Row(
                          children: [
                            Checkbox(
                              value: _isNeutered,
                              onChanged: (value) {
                                setState(() {
                                  _isNeutered = value ?? false;
                                });
                              },
                            ),
                            const Text('Is your pet neutered/spayed?'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePet,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                    : const Text('Save Pet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildImageSourceSelection() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Select Image Source', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 30),
                    ),
                    const SizedBox(height: 12),
                    const Text('Camera'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.photo_library, color: AppTheme.primaryColor, size: 30),
                    ),
                    const SizedBox(height: 12),
                    const Text('Gallery'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
