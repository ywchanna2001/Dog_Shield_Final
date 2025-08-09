import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/auth_service.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'package:dogshield_ai/presentation/widgets/bottom_navigation.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  final PetService _petService = PetService();
  final ReminderService _reminderService = ReminderService();

  List<Pet> _pets = [];
  List<Reminder> _upcomingReminders = [];
  List<Reminder> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load pets
      final pets = await _petService.getPets();

      // Load upcoming reminders
      final reminders = await _reminderService.getUpcomingReminders();

      // Get completed reminders for recent activities (past 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final allReminders = await _reminderService.getAllReminders();
      final recentActivities = allReminders.where((r) => r.isCompleted && r.date.isAfter(thirtyDaysAgo)).toList();

      // Sort by date (most recent first)
      recentActivities.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _pets = pets;
        _upcomingReminders = reminders;
        _recentActivities = recentActivities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // In case future callbacks try to setState after dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DogShield AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.notificationsRoute);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder(
        future: AuthService().getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppTheme.primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: user?.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
                      backgroundColor: Colors.white,
                      child:
                          user?.imageUrl == null
                              ? Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 40, color: AppTheme.primaryColor),
                              )
                              : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? 'Loading...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _selectedIndex == 0,
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('My Pets'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppConstants.petsRoute);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Reminders'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppConstants.reminderRoute);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('AI Detection'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppConstants.aiDetectionRoute);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppConstants.profileRoute);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context);
                  // Sign out implementation
                  final authService = AuthService();
                  authService.signOut().then((_) {
                    Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading data: $_errorMessage',
              style: TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet carousel
            _buildPetCarousel(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Upcoming Reminders
            _buildSectionHeader('Upcoming Reminders', AppConstants.reminderRoute),
            const SizedBox(height: 12),
            _buildUpcomingReminders(),
            const SizedBox(height: 24),

            // Recent Activities
            _buildSectionHeader('Recent Activities', null),
            const SizedBox(height: 12),
            _buildRecentActivities(),
            const SizedBox(height: 24),

            // Health Tips
            _buildHealthTips(),

            // Extra space for floating action button
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCarousel() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length + 1, // +1 for the add new pet card
        itemBuilder: (context, index) {
          if (index == _pets.length) {
            // Add new pet card
            return _buildAddPetCard();
          }

          final pet = _pets[index];
          return _buildPetCard(pet);
        },
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        // Navigate to pet profile screen
        Navigator.pushNamed(context, AppConstants.petProfileRoute, arguments: pet);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image:
                    pet.imageUrl != null
                        ? DecorationImage(image: NetworkImage(pet.imageUrl!), fit: BoxFit.cover)
                        : null,
              ),
              child:
                  pet.imageUrl == null ? Center(child: Icon(Icons.pets, size: 40, color: AppTheme.primaryColor)) : null,
            ),
            // Pet info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed} • ${pet.age}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppConstants.addPetRoute);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text('Add New Pet', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              icon: Icons.camera_alt,
              label: 'AI Detection',
              onTap: () => Navigator.pushNamed(context, AppConstants.aiDetectionRoute),
            ),
            _buildQuickActionItem(
              icon: Icons.pets,
              label: 'My Pets',
              onTap: () => Navigator.pushNamed(context, AppConstants.petsRoute),
            ),
            _buildQuickActionItem(
              icon: Icons.calendar_today,
              label: 'Reminders',
              onTap: () => Navigator.pushNamed(context, AppConstants.reminderRoute),
            ),
            _buildQuickActionItem(
              icon: Icons.person,
              label: 'Profile',
              onTap: () => Navigator.pushNamed(context, AppConstants.profileRoute),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? routeName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (routeName != null)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, routeName);
            },
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildUpcomingReminders() {
    if (_upcomingReminders.isEmpty) {
      return _buildEmptyState(icon: Icons.event_available, message: 'No upcoming reminders');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _upcomingReminders.length > 3 ? 3 : _upcomingReminders.length,
      itemBuilder: (context, index) {
        final reminder = _upcomingReminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    IconData iconData;
    Color iconColor;

    // Find pet name for this reminder
    String petName = 'Unknown';
    final pet = _pets.firstWhere(
      (p) => p.id == reminder.petId,
      orElse:
          () => Pet(
            id: '',
            name: 'Unknown',
            breed: '',
            dateOfBirth: DateTime.now(),
            gender: '',
            isNeutered: false,
            weight: 0,
            ownerId: '',
          ),
    );
    petName = pet.name;

    // Format date
    String formattedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(reminder.date.year, reminder.date.month, reminder.date.day);

    if (reminderDate.isAtSameMomentAs(today)) {
      formattedDate = 'Today, ${DateFormat('h:mm a').format(reminder.date)}';
    } else if (reminderDate.isAtSameMomentAs(tomorrow)) {
      formattedDate = 'Tomorrow, ${DateFormat('h:mm a').format(reminder.date)}';
    } else {
      formattedDate = DateFormat('EEE, MMM d, h:mm a').format(reminder.date);
    }

    switch (reminder.type) {
      case AppConstants.typeVaccination:
        iconData = Icons.medical_services;
        iconColor = AppTheme.primaryColor;
        break;
      case AppConstants.typeMedication:
        iconData = Icons.medication;
        iconColor = AppTheme.warningColor;
        break;
      case AppConstants.typeFeeding:
        iconData = Icons.restaurant;
        iconColor = AppTheme.successColor;
        break;
      case AppConstants.typeDeworming:
        iconData = Icons.healing;
        iconColor = AppTheme.errorColor;
        break;
      default:
        iconData = Icons.event;
        iconColor = AppTheme.infoColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(iconData, color: iconColor)),
        title: Text(reminder.title),
        subtitle: Text('$petName • $formattedDate'),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // TODO: Navigate to reminder details
          },
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    if (_recentActivities.isEmpty) {
      return _buildEmptyState(icon: Icons.history, message: 'No recent activities');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentActivities.length > 3 ? 3 : _recentActivities.length,
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];

        // Find pet name
        String petName = 'Unknown';
        final pet = _pets.firstWhere(
          (p) => p.id == activity.petId,
          orElse:
              () => Pet(
                id: '',
                name: 'Unknown',
                breed: '',
                dateOfBirth: DateTime.now(),
                gender: '',
                isNeutered: false,
                weight: 0,
                ownerId: '',
              ),
        );
        petName = pet.name;

        // Format date (relative)
        final now = DateTime.now();
        final difference = now.difference(activity.date);
        String formattedDate;

        if (difference.inDays == 0) {
          formattedDate = 'Today';
        } else if (difference.inDays == 1) {
          formattedDate = 'Yesterday';
        } else if (difference.inDays < 7) {
          formattedDate = '${difference.inDays} days ago';
        } else if (difference.inDays < 30) {
          final weeks = (difference.inDays / 7).floor();
          formattedDate = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
        } else {
          formattedDate = DateFormat('MMM d').format(activity.date);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(activity.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$petName • $formattedDate'),
                Text(activity.description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildHealthTips() {
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Health Tip',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Regular exercise is essential for your dog\'s physical and mental health. Aim for at least 30 minutes of activity each day.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to health tips screen
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Read More'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigation(currentIndex: _selectedIndex);
  }
}
