import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:dogshield_ai/presentation/widgets/bottom_navigation.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReminderService _reminderService = ReminderService();
  final PetService _petService = PetService();
  
  List<Reminder> _reminders = [];
  List<Reminder> _upcomingReminders = [];
  List<Reminder> _completedReminders = [];
  Map<String, Pet> _petsMap = {};
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load pets first
      final pets = await _petService.getPets();
      
      // Create map of pet id to pet object for quick lookup
      final petsMap = {for (var pet in pets) pet.id: pet};
      
      // Load all reminders
      final reminders = await _reminderService.getAllReminders();
      
      // Split reminders into upcoming and completed
      final now = DateTime.now();
      final upcoming = reminders.where((r) => 
        !r.isCompleted && r.date.isAfter(now.subtract(const Duration(days: 1)))
      ).toList();
      
      final completed = reminders.where((r) => r.isCompleted).toList();
      
      // Sort upcoming by date ascending
      upcoming.sort((a, b) => a.date.compareTo(b.date));
      
      // Sort completed by date descending
      completed.sort((a, b) => b.date.compareTo(a.date));
      
      setState(() {
        _petsMap = petsMap;
        _reminders = reminders;
        _upcomingReminders = upcoming;
        _completedReminders = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reminders: $e';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2), // Set reminders tab as active
    );
  }
  
  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersList(_upcomingReminders, isUpcoming: true),
          _buildRemindersList(_completedReminders, isUpcoming: false),
        ],
      ),
    );
  }
  
  Widget _buildRemindersList(List<Reminder> reminders, {required bool isUpcoming}) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming reminders' : 'No completed reminders',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming 
                ? 'Add reminders to track your pet\'s care schedule'
                : 'Completed reminders will appear here',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddReminderDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Reminder'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder, _petsMap[reminder.petId]);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, Pet? pet) {
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
    
    final bool isPast = reminder.date.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppConstants.editReminderRoute,
            arguments: reminder,
          ).then((_) => _loadData());
        },
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(iconData, color: iconColor),
              ),
              title: Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: reminder.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
                ),
              ),
              subtitle: Text(
                pet != null ? pet.name : 'Unknown Pet',
              ),
              trailing: Checkbox(
                value: reminder.isCompleted,
                onChanged: (value) {
                  if (value != null) {
                    _reminderService
                      .updateReminderStatus(reminder.id, value)
                      .then((_) => _loadData());
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, y - h:mm a').format(reminder.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: isPast && !reminder.isCompleted
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                      if (isPast && !reminder.isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Overdue',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (reminder.repeat && reminder.frequency != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Repeats ${reminder.frequency}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (reminder.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reminder.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (_getReminderSpecificInfo(reminder).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getReminderSpecificInfo(reminder),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getReminderSpecificInfo(Reminder reminder) {
    switch (reminder.type) {
      case AppConstants.typeMedication:
        return reminder.dosage != null ? 'Dosage: ${reminder.dosage}' : '';
      case AppConstants.typeFeeding:
        return reminder.portion != null 
            ? 'Portion: ${reminder.portion}' + 
              (reminder.mealType != null ? ' | Type: ${reminder.mealType}' : '')
            : '';
      case AppConstants.typeVaccination:
        return reminder.vetClinic != null ? 'Clinic: ${reminder.vetClinic}' : '';
      default:
        return '';
    }
  }
  
  void _showAddReminderDialog() {
    if (_petsMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a pet first before creating reminders'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Pet'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _petsMap.length,
            itemBuilder: (context, index) {
              final pet = _petsMap.values.elementAt(index);
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: pet.imageUrl != null
                      ? NetworkImage(pet.imageUrl!)
                      : null,
                  child: pet.imageUrl == null
                      ? const Icon(Icons.pets)
                      : null,
                ),
                title: Text(pet.name),
                subtitle: Text(pet.breed),
                onTap: () {
                  Navigator.pop(context);
                  _showReminderTypeDialog(pet);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  void _showReminderTypeDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Reminder Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReminderTypeButton(
              context: context,
              pet: pet,
              icon: Icons.medication,
              label: 'Medication',
              type: AppConstants.typeMedication,
            ),
            _buildReminderTypeButton(
              context: context,
              pet: pet,
              icon: Icons.restaurant,
              label: 'Feeding',
              type: AppConstants.typeFeeding,
            ),
            _buildReminderTypeButton(
              context: context,
              pet: pet,
              icon: Icons.healing,
              label: 'Vaccination',
              type: AppConstants.typeVaccination,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReminderTypeButton({
    required BuildContext context,
    required Pet pet,
    required IconData icon,
    required String label,
    required String type,
  }) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(icon),
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          AppConstants.addReminderRoute,
          arguments: {
            'petId': pet.id,
            'petName': pet.name,
            'reminderType': type,
          },
        ).then((_) => _loadData());
      },
    );
  }
}
