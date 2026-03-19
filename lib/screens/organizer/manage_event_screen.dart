import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'participants_screen.dart'; // We'll build this next

class ManageEventScreen extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const ManageEventScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Event'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            Text(
              eventData['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Event Description
            Text(
              eventData['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Volunteers and Points info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Volunteers: ${eventData['volunteers'] ?? 0}'),
                Text('Points: ${eventData['points'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Participants Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParticipantsScreen(
                          eventId: eventId,
                          eventPoints: eventData['points'] ?? 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('View Participants'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),

                // Optional: Delete event from Manage Screen
                ElevatedButton.icon(
                  onPressed: () async {
                    bool confirm = false;
                    confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content:
                            const Text('Are you sure you want to delete this event?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
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

                    // Delete related participants
                    final participants = await FirebaseFirestore.instance
                        .collection('user_events')
                        .where('eventId', isEqualTo: eventId)
                        .get();

                    for (var doc in participants.docs) {
                      await doc.reference.delete();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted successfully')),
                    );

                    Navigator.pop(context); // back to dashboard
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
