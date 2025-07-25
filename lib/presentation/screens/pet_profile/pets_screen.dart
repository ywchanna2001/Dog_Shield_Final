import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/pet_service.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';
import 'package:dogshield_ai/presentation/widgets/bottom_navigation.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final PetService _petService = PetService();
  bool _isLoading = true;
  List<Pet> _pets = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }
  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final pets = await _petService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pets in UI: $e');
      
      // Check if it's an authentication error
      if (e.toString().contains('User not logged in')) {
        // Redirect to login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        }
        return;
      }
      
      setState(() {
        _errorMessage = 'Failed to load pets: $e';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.addPetRoute)
                .then((_) => _loadPets());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPets,
        child: _buildBody(),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1), // Set pets tab as active
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPets,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 72,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pets added yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a pet to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.addPetRoute)
                  .then((_) => _loadPets());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppConstants.petProfileRoute,
            arguments: pet,
          ).then((_) => _loadPets());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: pet.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(pet.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.pets,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            // Pet info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            pet.gender == 'Male' ? Icons.male : Icons.female,
                            color: pet.gender == 'Male'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          if (pet.isNeutered) const SizedBox(width: 4),
                          if (pet.isNeutered)
                            const Tooltip(
                              message: 'Neutered/Spayed',
                              child: Icon(Icons.cut, size: 18),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.breed,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    children: [
                      Text(
                        'Age: ${pet.age}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Weight: ${pet.weight} kg',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
