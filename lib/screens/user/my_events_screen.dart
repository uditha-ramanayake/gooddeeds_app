import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gooddeeds_app/models/event_model.dart'; // ✅ correct

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
        // ✅ Removed the Create Event button
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

              // Events created OR joined
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
                        'Volunteers: ${event.volunteers}  |  Points: ${event.points}',
                      ),

                      // ✅ ONLY LEAVE BUTTON (NO DELETE ANYMORE)
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCreator && isJoined)
                            IconButton(
                              icon: const Icon(
                                Icons.exit_to_app,
                                color: Colors.orange,
                              ),
                              onPressed: () async {
                                // Remove from user_events
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

                                // Decrease volunteers count
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.id)
                                    .update({
                                  'volunteers': FieldValue.increment(-1),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Left event'),
                                  ),
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
