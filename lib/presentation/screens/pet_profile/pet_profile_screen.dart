import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PetProfileScreen extends StatefulWidget {
  final Pet pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PetService _petService = PetService();
  final ReminderService _reminderService = ReminderService();

  late Pet _pet;
  bool _isLoading = false;
  bool _isEditing = false;
  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Male';
  DateTime? _dateOfBirth;
  File? _newPetImage;
  bool _isNeutered = false;

  List<Reminder> _petReminders = [];
  bool _loadingReminders = true;

  // State Management Fix: Initialize the list here
  List<String> _dogBreeds = [
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
  void initState() {
    super.initState();
    _pet = widget.pet;
    _tabController = TabController(length: 2, vsync: this);

    // State Management Fix: Add the pet's current breed to the list
    // if it's not already there. This is done safely before any builds.
    if (!_dogBreeds.contains(_pet.breed)) {
      // Inserts the custom breed before 'Other'
      _dogBreeds.insert(_dogBreeds.length - 1, _pet.breed);
    }

    _nameController.text = _pet.name;
    _breedController.text = _pet.breed;
    _weightController.text = _pet.weight.toString();
    _gender = _pet.gender;
    _dateOfBirth = _pet.dateOfBirth;
    _isNeutered = _pet.isNeutered;

    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    setState(() {
      _loadingReminders = true;
    });

    try {
      final reminders = await _reminderService.getPetReminders(_pet.id);
      if (!mounted) return;
      setState(() {
        _petReminders = reminders;
        _loadingReminders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load reminders: $e';
        _loadingReminders = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _newPetImage = File(image.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _newPetImage = File(image.path);
      });
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset form if canceling edit
        if (!_dogBreeds.contains(widget.pet.breed)) {
          _dogBreeds.insert(_dogBreeds.length - 1, widget.pet.breed);
        }
        _nameController.text = _pet.name;
        _breedController.text = _pet.breed;
        _weightController.text = _pet.weight.toString();
        _gender = _pet.gender;
        _dateOfBirth = _pet.dateOfBirth;
        _isNeutered = _pet.isNeutered;
        _newPetImage = null;
      }
    });
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final updatedPet = await _petService.updatePet(
        petId: _pet.id,
        name: _nameController.text,
        breed: _breedController.text,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        isNeutered: _isNeutered,
        weight: double.parse(_weightController.text),
        newImage: _newPetImage,
      );
      if (!mounted) return;
      setState(() {
        _pet = updatedPet;
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet updated successfully'), backgroundColor: AppTheme.successColor));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to update pet: $e';
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage), backgroundColor: AppTheme.errorColor));
    }
  }

  Future<void> _deletePet() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Pet'),
                content: Text('Are you sure you want to delete ${_pet.name}? This action cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DELETE', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _petService.deletePet(_pet.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to delete pet: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : _pet.name),
        actions: [if (!_isEditing) IconButton(icon: const Icon(Icons.edit), onPressed: _toggleEditing)],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  // *** LAYOUT FIX PART 1 ***
  // This structure is now correct. The Column contains an Expanded widget.
  // This gives the child (either the profile or the form) a fixed, finite height
  // to draw itself in, which prevents the "infinite height/width" error.
  Widget _buildBody() {
    return Column(
      children: [
        if (_errorMessage.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppTheme.errorColor.withOpacity(0.1),
            padding: const EdgeInsets.all(8),
            child: Text(_errorMessage, style: const TextStyle(color: AppTheme.errorColor), textAlign: TextAlign.center),
          ),
        Expanded(child: _isEditing ? _buildEditForm() : _buildPetProfile()),
      ],
    );
  }

  // *** LAYOUT FIX PART 2 ***
  // This widget is a child of the Expanded in _buildBody, so it MUST NOT
  // have its own top-level Expanded widget.
  Widget _buildPetProfile() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Center(
            child: Column(
              children: [
                Hero(
                  tag: 'pet-${_pet.id}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _pet.imageUrl != null ? NetworkImage(_pet.imageUrl!) : null,
                    child:
                        _pet.imageUrl == null ? const Icon(Icons.pets, size: 60, color: AppTheme.primaryColor) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(_pet.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_pet.breed, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ],
            ),
          ),
        ),
        TabBar(controller: _tabController, tabs: const [Tab(text: 'Details'), Tab(text: 'Reminders')]),
        // This inner Expanded is correct because its parent is a Column.
        Expanded(child: TabBarView(controller: _tabController, children: [_buildDetailsTab(), _buildRemindersTab()])),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pet Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoItem('Gender', _pet.gender, Icons.wc),
          _buildInfoItem('Birth Date', DateFormat('MMM d, y').format(_pet.dateOfBirth), Icons.cake),
          _buildInfoItem('Age', _pet.age, Icons.access_time),
          _buildInfoItem('Weight', '${_pet.weight} kg', Icons.fitness_center),
          _buildInfoItem('Neutered/Spayed', _pet.isNeutered ? 'Yes' : 'No', Icons.cut),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _deletePet,
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              label: const Text('Delete Pet', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    if (_loadingReminders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_petReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No reminders set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_pet.name} has no reminders yet', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _petReminders.length,
      itemBuilder: (context, index) {
        final reminder = _petReminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    IconData iconData;
    Color iconColor;

    switch (reminder.type) {
      case AppConstants.typeVaccination:
        iconData = Icons.healing;
        iconColor = Colors.teal;
        break;
      case AppConstants.typeMedication:
        iconData = Icons.medication;
        iconColor = Colors.orange;
        break;
      case AppConstants.typeFeeding:
        iconData = Icons.restaurant;
        iconColor = Colors.purple;
        break;
      case AppConstants.typeDeworming:
        iconData = Icons.bug_report;
        iconColor = Colors.brown;
        break;
      case AppConstants.typeCheckup:
        iconData = Icons.medical_services;
        iconColor = AppTheme.primaryColor;
        break;
      case AppConstants.typeGrooming:
        iconData = Icons.bathroom;
        iconColor = Colors.pink;
        break;
      default:
        iconData = Icons.event;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(iconData, color: iconColor)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y - h:mm a').format(reminder.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: reminder.isCompleted,
              onChanged: (value) {
                if (value != null) {
                  _reminderService.updateReminderStatus(reminder.id, value).then((_) => _loadReminders());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // *** LAYOUT FIX PART 3 ***
  // This widget now correctly returns a scrollable Form without
  // a conflicting Expanded widget. It will correctly fill the space
  // provided by the Expanded widget in _buildBody.
  Widget _buildEditForm() {
    // This method now contains a Container that provides explicit width constraints,
    // solving the layout error for good.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // Provide only a maxWidth to avoid forcing infinite/overly tight constraints
            constraints: BoxConstraints(
              maxWidth: 600, // keeps layout sane on tablets/landscape
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pet Image
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(context: context, builder: (context) => _buildImageSourceSelection());
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage:
                              _newPetImage != null
                                  ? FileImage(_newPetImage!)
                                  : _pet.imageUrl != null
                                  ? NetworkImage(_pet.imageUrl!)
                                  : null,
                          child:
                              _newPetImage == null && _pet.imageUrl == null
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
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor,
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
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
                  value: _breedController.text,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    hintText: 'Select or enter breed',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      _dogBreeds.map((String breed) {
                        return DropdownMenuItem<String>(value: breed, child: Text(breed));
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _breedController.text = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a breed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                FormField<String>(
                  initialValue: _gender,
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Male'),
                                value: 'Male',
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value!;
                                    state.didChange(value);
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Female'),
                                value: 'Female',
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value!;
                                    state.didChange(value);
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        if (state.hasError)
                          Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                      ],
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                FormField<DateTime>(
                  initialValue: _dateOfBirth,
                  builder: (FormFieldState<DateTime> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Birth'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _dateOfBirth != null ? DateFormat.yMMMd().format(_dateOfBirth!) : 'Select date',
                            ),
                          ),
                        ),
                        if (state.hasError)
                          Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                      ],
                    );
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Weight
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your pet\'s weight',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Weight must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Neutered/Spayed
                SwitchListTile(
                  title: const Text('Neutered/Spayed'),
                  value: _isNeutered,
                  onChanged: (value) {
                    setState(() {
                      _isNeutered = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 120, child: OutlinedButton(onPressed: _toggleEditing, child: const Text('Cancel'))),
                    const SizedBox(width: 16),
                    SizedBox(width: 120, child: ElevatedButton(onPressed: _savePet, child: const Text('Save Changes'))),
                  ],
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
          const Text('Choose a photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
                      child: const Icon(Icons.camera_alt, size: 32, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
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
                      child: const Icon(Icons.photo_library, size: 32, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
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
