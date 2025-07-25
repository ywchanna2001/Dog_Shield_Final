import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';

class AddReminderScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const AddReminderScreen({super.key, required this.args});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reminderService = ReminderService();

  late String _petId;
  late String _petName;
  late String _reminderType;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 15));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _repeat = false;
  String _frequency = 'Daily';
  
  // Specific fields for different reminder types
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();
  String _mealType = 'Breakfast';
  final TextEditingController _vetClinicController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _petId = widget.args['petId'];
    _petName = widget.args['petName'];
    _reminderType = widget.args['reminderType'];
    
    // Set default title based on reminder type
    switch (_reminderType) {
      case AppConstants.typeMedication:
        _titleController.text = 'Medication';
        break;
      case AppConstants.typeFeeding:
        _titleController.text = 'Feeding';
        _mealType = 'Breakfast';
        break;
      case AppConstants.typeVaccination:
        _titleController.text = 'Vaccination';
        break;
      default:
        _titleController.text = 'Reminder';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _portionController.dispose();
    _vetClinicController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        switch (_reminderType) {
          case AppConstants.typeMedication:
            await _reminderService.addMedicationReminder(
              petId: _petId,
              medicationName: _titleController.text,
              description: _descriptionController.text,
              date: _selectedDate,
              dosage: _dosageController.text,
              repeat: _repeat,
              frequency: _repeat ? _frequency : null,
            );
            break;
            
          case AppConstants.typeFeeding:
            await _reminderService.addFeedingReminder(
              petId: _petId,
              mealName: _titleController.text,
              description: _descriptionController.text,
              date: _selectedDate,
              portion: _portionController.text,
              mealType: _mealType,
              repeat: _repeat,
              frequency: _repeat ? _frequency : null,
            );
            break;
            
          case AppConstants.typeVaccination:
            await _reminderService.addVaccinationReminder(
              petId: _petId,
              vaccineName: _titleController.text,
              description: _descriptionController.text,
              date: _selectedDate,
              vetClinic: _vetClinicController.text.isNotEmpty ? _vetClinicController.text : null,
            );
            break;
            
          default:
            // Generic reminder
            await _reminderService.addGenericReminder(
              petId: _petId,
              title: _titleController.text,
              description: _descriptionController.text,
              date: _selectedDate,
              repeat: _repeat,
              frequency: _repeat ? _frequency : null,
            );
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error adding reminder: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${_getReminderTypeLabel()} Reminder'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
              
            Text(
              'For $_petName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('MMM d, y').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('h:mm a').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type-specific fields
            ..._buildTypeSpecificFields(),
            
            // Repeat options
            SwitchListTile(
              title: const Text('Repeat'),
              value: _repeat,
              onChanged: (value) {
                setState(() {
                  _repeat = value;
                });
              },
            ),
            
            if (_repeat)
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                    });
                  }
                },
              ),
              
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveReminder,
                child: const Text('Save Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_reminderType) {
      case AppConstants.typeMedication:
        return [
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Dosage',
              border: OutlineInputBorder(),
              hintText: 'e.g., 1 tablet, 5ml, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter dosage information';
              }
              return null;
            },
          ),
        ];
        
      case AppConstants.typeFeeding:
        return [
          TextFormField(
            controller: _portionController,
            decoration: const InputDecoration(
              labelText: 'Portion Size',
              border: OutlineInputBorder(),
              hintText: 'e.g., 1 cup, 100g, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter portion size';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mealType,
            decoration: const InputDecoration(
              labelText: 'Meal Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
              DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
              DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
              DropdownMenuItem(value: 'Snack', child: Text('Snack')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _mealType = value;
                });
              }
            },
          ),
        ];
        
      case AppConstants.typeVaccination:
        return [
          TextFormField(
            controller: _vetClinicController,
            decoration: const InputDecoration(
              labelText: 'Vet Clinic (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
        
      default:
        return [];
    }
  }

  String _getReminderTypeLabel() {
    switch (_reminderType) {
      case AppConstants.typeMedication:
        return 'Medication';
      case AppConstants.typeFeeding:
        return 'Feeding';
      case AppConstants.typeVaccination:
        return 'Vaccination';
      default:
        return '';
    }
  }
} 