import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantsScreen extends StatelessWidget {
  final String eventId;
  final int eventPoints; // points to deduct if absent

  const ParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_events')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final participants = snapshot.data!.docs;

          if (participants.isEmpty) {
            return const Center(child: Text('No participants yet.'));
          }

          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participantDoc = participants[index];
              final participantData =
                  participantDoc.data() as Map<String, dynamic>;
              final attendance = participantData['attendance'] ?? 'pending';
              final userName = participantData['userName'] ?? 'No Name'; // optional
              final userId = participantData['userId'];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(userName),
                  subtitle: Text('Status: ${attendance.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Present button
                      if (attendance == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('user_events')
                                .doc(participantDoc.id)
                                .update({'attendance': 'attended'});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$userName marked as Present'),
                              ),
                            );
                          },
                        ),

                      // Absent button
                      if (attendance == 'pending')
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            // Update attendance to absent
                            await FirebaseFirestore.instance
                                .collection('user_events')
                                .doc(participantDoc.id)
                                .update({'attendance': 'absent'});

                            // Deduct points from the user
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .update({
                              'points': FieldValue.increment(-eventPoints)
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$userName marked as Absent'),
                              ),
                            );
                          },
                        ),

                      // Show status if already marked
                      if (attendance != 'pending')
                        Text(
                          attendance == 'attended' ? '✅ Attended' : '❌ Absent',
                          style: TextStyle(
                            color: attendance == 'attended'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
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
