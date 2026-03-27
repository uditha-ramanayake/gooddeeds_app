
class Event {
  final String id;
  final String title;
  final String description;
  final String date;
  final String location;
  final String? imageUrl;
  final int volunteers;
  final int points;
  final String creatorId; // ADDED: the ID of the user who created the event

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.imageUrl,
    required this.volunteers,
    required this.points,
    required this.creatorId, // ADDED
  });

  // Converts Firestore map to Event
  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      volunteers: data['volunteers'] ?? 0,
      points: data['points'] ?? 0,
      creatorId: data['creatorId']?.toString() ?? '', // ADDED
    );
  }

  // Keeps old screens using fromFirestore working
  factory Event.fromFirestore(dynamic doc) {
    return Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Converts Event back to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'imageUrl': imageUrl,
      'volunteers': volunteers,
      'points': points,
      'creatorId': creatorId, // ADDED
    };
  }
}