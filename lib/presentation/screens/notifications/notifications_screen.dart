import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:dogshield_ai/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ReminderService _reminderService = ReminderService();
  final PetService _petService = PetService();
  final NotificationService _notificationService = NotificationService();
  List<Reminder> _overdueReminders = [];
  List<Reminder> _todayReminders = [];
  List<Reminder> _upcomingReminders = [];
  Map<String, Pet> _petsMap = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load pets
      final pets = await _petService.getPets();
      _petsMap = {for (var pet in pets) pet.id: pet};

      // Load reminders
      final allReminders = await _reminderService.getAllReminders();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Overdue reminders (past due and not completed)
      _overdueReminders =
          allReminders.where((reminder) {
            return reminder.date.isBefore(now) && !reminder.isCompleted;
          }).toList();

      // Today's reminders (due today and not completed)
      _todayReminders =
          allReminders.where((reminder) {
            final reminderDate = DateTime(reminder.date.year, reminder.date.month, reminder.date.day);
            return reminderDate.isAtSameMomentAs(today) &&
                !reminder.isCompleted &&
                !reminder.date.isBefore(now); // Exclude overdue from today's list
          }).toList();

      // Upcoming reminders (next 7 days, not completed)
      _upcomingReminders =
          allReminders.where((reminder) {
            final reminderDate = DateTime(reminder.date.year, reminder.date.month, reminder.date.day);
            return reminderDate.isAfter(today) &&
                reminderDate.isBefore(today.add(const Duration(days: 7))) &&
                !reminder.isCompleted;
          }).toList();

      // Sort by date/time
      _overdueReminders.sort((a, b) => b.date.compareTo(a.date)); // Most recent overdue first
      _todayReminders.sort((a, b) => a.date.compareTo(b.date));
      _upcomingReminders.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              try {
                await _notificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification sent! Check your device notifications.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Notification error: $e'), backgroundColor: Colors.red));
                }
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotifications),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage, style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_overdueReminders.isEmpty && _todayReminders.isEmpty && _upcomingReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('You\'re all caught up!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _notificationService.showTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent to your device! Check your notification panel.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending notification: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Mobile Notification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final status = await _notificationService.getNotificationStatus();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Notification Status'),
                            content: Text(
                              'Enabled: ${status['enabled']}\n'
                              'Platform: ${status['platform'] ?? 'unknown'}\n'
                              'Time: ${status['timestamp']}\n'
                              '${status['error'] != null ? 'Error: ${status['error']}' : ''}',
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error checking status: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Check Notification Status'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overdue Reminders Section (Priority)
          if (_overdueReminders.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Overdue (${_overdueReminders.length})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
            ..._overdueReminders.map((reminder) => _buildNotificationCard(reminder, isOverdue: true)),
            const SizedBox(height: 24),
          ],

          if (_todayReminders.isNotEmpty) ...[
            _buildSectionHeader('Today', _todayReminders.length),
            const SizedBox(height: 12),
            ..._todayReminders.map((reminder) => _buildNotificationCard(reminder, isToday: true)),
            const SizedBox(height: 24),
          ],
          if (_upcomingReminders.isNotEmpty) ...[
            _buildSectionHeader('Upcoming', _upcomingReminders.length),
            const SizedBox(height: 12),
            ..._upcomingReminders.map((reminder) => _buildNotificationCard(reminder, isToday: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Reminder reminder, {bool isToday = false, bool isOverdue = false}) {
    final pet = _petsMap[reminder.petId];
    final petName = pet?.name ?? 'Unknown Pet';

    IconData typeIcon;
    Color typeColor;

    switch (reminder.type) {
      case AppConstants.typeMedication:
        typeIcon = Icons.medication;
        typeColor = isOverdue ? Colors.red : Colors.orange;
        break;
      case AppConstants.typeFeeding:
        typeIcon = Icons.restaurant;
        typeColor = isOverdue ? Colors.red : Colors.green;
        break;
      case AppConstants.typeVaccination:
        typeIcon = Icons.healing;
        typeColor = isOverdue ? Colors.red : Colors.red;
        break;
      default:
        typeIcon = Icons.event;
        typeColor = isOverdue ? Colors.red : AppTheme.primaryColor;
    }

    // Calculate overdue duration if applicable
    String overdueText = '';
    if (isOverdue) {
      final overdueDuration = DateTime.now().difference(reminder.date);
      if (overdueDuration.inDays > 0) {
        overdueText = '${overdueDuration.inDays} day${overdueDuration.inDays > 1 ? 's' : ''} overdue';
      } else if (overdueDuration.inHours > 0) {
        overdueText = '${overdueDuration.inHours} hour${overdueDuration.inHours > 1 ? 's' : ''} overdue';
      } else {
        overdueText = 'Recently overdue';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markAsCompleted(reminder),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(petName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    if (reminder.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isToday ? DateFormat.Hm().format(reminder.date) : DateFormat.MMMd().format(reminder.date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isOverdue ? Colors.red : (isToday ? AppTheme.primaryColor : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          isOverdue
                              ? Colors.red.withOpacity(0.1)
                              : (isToday ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverdue ? overdueText : (isToday ? 'Today' : 'Upcoming'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.red : (isToday ? AppTheme.primaryColor : Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsCompleted(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark as Completed'),
            content: Text('Mark "${reminder.title}" as completed?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete')),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _reminderService.updateReminderStatus(reminder.id, true);
        _loadNotifications(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder marked as completed'), backgroundColor: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to mark reminder as completed: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }
}
