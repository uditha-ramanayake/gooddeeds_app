import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';
import 'my_events_screen.dart';
import 'event_details_screen.dart';

class DiscoverEventsScreen extends StatelessWidget {
  const DiscoverEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
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
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyEventsScreen()),
              );
            },
            icon: const Icon(Icons.event_available, color: Colors.white),
            label: const Text(
              'My Events',
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

          final events = snapshot.data!.docs
              .map((doc) =>
                  Event.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          if (events.isEmpty) {
            return const Center(child: Text('No events available.'));
          }

          return FutureBuilder<QuerySnapshot>(
            future: currentUser == null
                ? Future.value(null)
                : FirebaseFirestore.instance
                    .collection('user_events')
                    .where('userId', isEqualTo: currentUser.uid)
                    .get(),
            builder: (context, joinedSnapshot) {
              final joinedEventIds = <String>{};
              if (joinedSnapshot.hasData && joinedSnapshot.data != null) {
                joinedEventIds.addAll(joinedSnapshot.data!.docs
                    .map((doc) => doc['eventId'].toString()));
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isCreator =
                      currentUser != null && event.creatorId == currentUser.uid;
                  final isJoined = joinedEventIds.contains(event.id);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      onTap: () {
                        // Navigate to EventDetailsScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailsScreen(event: event)),
                        );
                      },
                      // Image on the left
                      leading: event.imageUrl != null &&
                              event.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                event.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  const Icon(Icons.image, color: Colors.white),
                            ),
                      title: Text(event.title),
                      subtitle: Text(
                          'Volunteers: ${event.volunteers}  |  Points: ${event.points}'),
                      trailing: currentUser == null
                          ? null
                          : isCreator
                              ? null // Creator can't join their own event
                              : isJoined
                                  ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                      ),
                                      child: const Text('Joined'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        await _joinEvent(
                                            context, event, currentUser.uid);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4CAF50),
                                      ),
                                      child: const Text('Join'),
                                    ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Join function that adds user to user_events in Firebase
  Future<void> _joinEvent(
      BuildContext context, Event event, String userId) async {
    final eventId = event.id;

    // Check if already joined
    final existing = await FirebaseFirestore.instance
        .collection('user_events')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Already joined!')));
      return;
    }

    // Get user info
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) return;

    // Add participant to user_events collection
    await FirebaseFirestore.instance.collection('user_events').add({
      'userId': userId,
      'eventId': eventId,
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'points': event.points,
      'joinedAt': Timestamp.now(),
    });

    // Update user points
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'points': FieldValue.increment(event.points),
    }, SetOptions(merge: true));

    // Update event volunteers count
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'volunteers': FieldValue.increment(1),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Joined event!')));
  }
}
