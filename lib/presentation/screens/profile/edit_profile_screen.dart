import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/data/services/auth_service.dart';
import 'package:dogshield_ai/data/models/user_model.dart' as user_model;

class EditProfileScreen extends StatefulWidget {
  final user_model.User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _newImage;
  bool _deleteImage = false;
  bool _isLoading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _currentImageUrl = widget.user.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newImage = File(image.path);
          _deleteImage = false; // Reset delete flag if new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _newImage = null;
      _deleteImage = true;
      _currentImageUrl = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserProfile(
        userId: widget.user.id,
        name: _nameController.text.trim(),
        newImage: _newImage,
        deleteImage: _deleteImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
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
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildImageSection(),
              const SizedBox(height: 32),
              _buildNameField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _newImage != null
                  ? FileImage(_newImage!)
                  : (_currentImageUrl != null
                  ? NetworkImage(_currentImageUrl!)
                  : null) as ImageProvider?,
              child: (_newImage == null && _currentImageUrl == null)
                  ? Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 40),
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20),
                  color: Colors.white,
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
        if (_newImage != null || _currentImageUrl != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            label: const Text(
              'Remove Image',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Name',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}