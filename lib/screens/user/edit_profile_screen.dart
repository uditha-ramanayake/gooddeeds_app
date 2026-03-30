import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String? currentImageUrl;
  final String? currentBio; // NEW

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    this.currentImageUrl,
    this.currentBio, // NEW
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _imageUrlController;
  late TextEditingController _bioController; // NEW

  bool _loading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _imageUrlController =
        TextEditingController(text: widget.currentImageUrl ?? '');
    _bioController =
        TextEditingController(text: widget.currentBio ?? ''); // NEW
    _currentImageUrl = widget.currentImageUrl;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newName = _nameController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final bio = _bioController.text.trim(); // NEW

    try {
      // ✅ Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'name': newName,
        'profileImage': imageUrl,
        'bio': bio, // NEW
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _bioController.dispose(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (_imageUrlController.text.isNotEmpty) {
      imageProvider = NetworkImage(_imageUrlController.text);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 🖼️ Image URL input
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Profile Image URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 👤 Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 📝 Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Add a bio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📧 Email (READ ONLY)
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email (cannot be changed)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
