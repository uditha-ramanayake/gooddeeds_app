import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class ParticipantsScreen extends StatelessWidget {
  final Event event;

  const ParticipantsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user_events').where('eventId', isEqualTo: event.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final participants = snapshot.data!.docs;
          if (participants.isEmpty) return const Center(child: Text('No participants yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index].data() as Map<String, dynamic>;
              final userId = participant['userId'];
              final points = participant['points'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(padding: EdgeInsets.all(16), child: Text('User not found.')),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'Unknown';
                  final email = userData['email'] ?? 'No email';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(backgroundColor: Color(0xFF4CAF50), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Email: $email'),
                          Text('Points Earned: $points'),
                        ],
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
}