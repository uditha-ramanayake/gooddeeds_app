import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user/discover_events_screen.dart';
import 'organizer/organizer_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Save role in Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'role': role,
    }, SetOptions(merge: true));

    // Navigate based on role
    if (role == 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const DiscoverEventsScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const OrganizerDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Are you a User or Organizer?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // USER BUTTON
            ElevatedButton(
              onPressed: () => _selectRole(context, 'user'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text("Continue as User"),
            ),

            const SizedBox(height: 20),

            // ORGANIZER BUTTON
            ElevatedButton(
              onPressed: () => _selectRole(context, 'organizer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text("Continue as Organizer"),
            ),
          ],
        ),
      ),
    );
  }
}