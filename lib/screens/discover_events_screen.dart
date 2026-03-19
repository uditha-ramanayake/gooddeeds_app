import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import 'my_events_screen.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'user/profile_screen.dart';
import 'user/community_screen.dart'; // Import CommunityScreen

class DiscoverEventsScreen extends StatefulWidget {
  const DiscoverEventsScreen({super.key});

  @override
  State<DiscoverEventsScreen> createState() => _DiscoverEventsScreenState();
}

class _DiscoverEventsScreenState extends State<DiscoverEventsScreen> {
  final Map<String, bool> _joinedEvents = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.forum), // 💬 Community icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CommunityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateEventScreen()),
              );
            },
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

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isCreator =
                  currentUser != null && event.creatorId == currentUser.uid;
              final joined = _joinedEvents[event.id] ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EventDetailsScreen(event: event)),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        image:
                            event.imageUrl != null && event.imageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(event.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        color: Colors.grey[300],
                      ),
                      child: event.imageUrl == null || event.imageUrl!.isEmpty
                          ? const Icon(Icons.image,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Join Button & Volunteers/Points
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCreator && currentUser != null)
                          ElevatedButton(
                            onPressed: joined
                                ? null
                                : () async {
                                    await _joinEvent(
                                        context, event, currentUser.uid);
                                    setState(() {
                                      _joinedEvents[event.id] = true;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: joined
                                  ? Colors.grey
                                  : const Color(0xFF4CAF50),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            child: Text(joined ? 'Joined' : 'Join Event'),
                          ),
                        const SizedBox(height: 8),
                        // Volunteers & Points
                        Text(
                          'Volunteers: ${event.volunteers}  |  Points: ${event.points}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Event Details Card (Title & Description)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailsScreen(event: event)),
                        );
                      },
                      title: Text(event.title),
                      subtitle: Text(event.description),
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Join function
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

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) return;

    // Add user to event
    await FirebaseFirestore.instance.collection('user_events').add({
      'userId': userId,
      'eventId': eventId,
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'points': event.points,
      'joinedAt': Timestamp.now(),
    });

    // Increment user points
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'points': FieldValue.increment(event.points),
    }, SetOptions(merge: true));

    // Increment event volunteers
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'volunteers': FieldValue.increment(1),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Joined event!')));
  }
}
