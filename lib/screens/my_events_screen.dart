import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Events'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
        body: const Center(child: Text('Please login to see your events.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateEventScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Event',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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

          // Convert Firestore docs to List<Event>
          final List<Event> allEvents = snapshot.data!.docs
              .map((doc) =>
                  Event.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('user_events')
                .where('userId', isEqualTo: currentUser.uid)
                .get(),
            builder: (context, joinedSnapshot) {
              if (!joinedSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final joinedEventIds = joinedSnapshot.data!.docs
                  .map((doc) => doc['eventId'].toString())
                  .toSet();

              // Filter: events created by user OR joined by user
              final List<Event> myEvents = allEvents
                  .where((e) =>
                      e.creatorId == currentUser.uid ||
                      joinedEventIds.contains(e.id))
                  .toList();

              if (myEvents.isEmpty) {
                return const Center(child: Text('You have no events yet.'));
              }

              return ListView(
                children: myEvents.map((event) {
                  final isCreator = event.creatorId == currentUser.uid;
                  final isJoined = joinedEventIds.contains(event.id);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                          'Volunteers: ${event.volunteers}  |  Points: ${event.points}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Leave button (only for joined events not created by user)
                          if (isJoined && !isCreator)
                            IconButton(
                              icon: const Icon(Icons.exit_to_app,
                                  color: Colors.orange),
                              onPressed: () async {
                                final userEventsQuery = await FirebaseFirestore
                                    .instance
                                    .collection('user_events')
                                    .where('userId', isEqualTo: currentUser.uid)
                                    .where('eventId', isEqualTo: event.id)
                                    .get();

                                for (var doc in userEventsQuery.docs) {
                                  await doc.reference.delete();
                                }

                                // Deduct points
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .set({
                                  'points': FieldValue.increment(-event.points),
                                }, SetOptions(merge: true));

                                // Decrease volunteers
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.id)
                                    .update({
                                  'volunteers': FieldValue.increment(-1),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Left event')),
                                );
                              },
                            ),

                          // Delete button (only for events created by user)
                          if (isCreator)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Delete event from events collection
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.id)
                                    .delete();

                                // Delete all related user_events entries
                                final userEvents = await FirebaseFirestore
                                    .instance
                                    .collection('user_events')
                                    .where('eventId', isEqualTo: event.id)
                                    .get();

                                for (var doc in userEvents.docs) {
                                  await doc.reference.delete();
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Event deleted successfully')),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
