import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_event_screen.dart';
import 'create_event_screen.dart'; // Import the create event screen

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('creatorId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return const Center(
              child: Text('You have not created any events.'),
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;
              final eventId = event.id;

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
                        icon: const Icon(Icons.manage_accounts,
                            color: Colors.blue),
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
                          bool confirm = false;
                          confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete this event?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );

                          if (!confirm) return;

                          // Delete event
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
                            const SnackBar(
                                content: Text('Event deleted successfully')),
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