import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event, size: 100, color: Color(0xFF4CAF50)),
              ),
            const SizedBox(height: 16),

            // Event Title
            Text(
              event.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Event Description
            Text(
              event.description,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Event Date
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text('Date: ${event.date}'),
              ],
            ),
            const SizedBox(height: 8),

            // Event Location
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text('Location: ${event.location}'),
              ],
            ),
            const SizedBox(height: 8),

            // Event Volunteers
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text('Volunteers: ${event.volunteers}'),
              ],
            ),
            const SizedBox(height: 8),

            // Event Points
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text('Points: ${event.points}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
