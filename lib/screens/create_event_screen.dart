import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'discover_events_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _pointsController = TextEditingController();

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You must be logged in to create an event')),
          );
          return;
        }

        // Add event to Firestore with creatorId
        await FirebaseFirestore.instance.collection('events').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'date': _dateController.text.trim(),
          'location': _locationController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
          'points': int.tryParse(_pointsController.text.trim()) ?? 0,
          'volunteers': 0,
          'createdAt': Timestamp.now(),
          'creatorId': currentUser.uid, // ✅ added creatorId
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event Created Successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DiscoverEventsScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (label != "Image URL (optional)" &&
              (value == null || value.isEmpty)) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Event'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(
                        controller: _titleController, label: "Event Title"),
                    _buildTextField(
                        controller: _descriptionController,
                        label: "Description",
                        maxLines: 3),
                    _buildTextField(
                        controller: _dateController,
                        label: "Date",
                        readOnly: true,
                        onTap: _pickDate),
                    _buildTextField(
                        controller: _locationController, label: "Location"),
                    _buildTextField(
                        controller: _imageUrlController,
                        label: "Image URL (optional)"),
                    _buildTextField(
                        controller: _pointsController,
                        label: "Points",
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Create Event"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
