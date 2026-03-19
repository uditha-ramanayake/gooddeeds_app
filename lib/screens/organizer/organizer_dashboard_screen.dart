import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_event_screen.dart'; // We'll build this next

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Organizer Dashboard'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
        body: const Center(
          child: Text('Please login to view your events.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter events created by current user
          final List events = snapshot.data!.docs
              .where((doc) => doc['creatorId'] == currentUser.uid)
              .toList();

          if (events.isEmpty) {
            return const Center(child: Text('You have not created any events.'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventId = event.id;
              final eventData = event.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(eventData['title'] ?? 'No Title'),
                  subtitle: Text(
                    'Volunteers: ${eventData['volunteers'] ?? 0}  |  Points: ${eventData['points'] ?? 0}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Manage button
                      IconButton(
                        icon: const Icon(Icons.manage_accounts, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageEventScreen(
                                eventId: eventId,
                                eventData: eventData,
                              ),
                            ),
                          );
                        },
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Delete the event
                          await FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventId)
                              .delete();

                          // Delete related user_events
                          final userEvents = await FirebaseFirestore.instance
                              .collection('user_events')
                              .where('eventId', isEqualTo: eventId)
                              .get();

                          for (var doc in userEvents.docs) {
                            await doc.reference.delete();
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event deleted successfully')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
