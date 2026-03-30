import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostFeedScreen extends StatelessWidget {
  final String userId;

  const PostFeedScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;

              final imageUrl = data['imageUrl']?.toString() ?? '';
              final caption = data['text']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show image if it exists
                    if (imageUrl.isNotEmpty)
                      Image.network(imageUrl, fit: BoxFit.cover)
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      ),

                    // Show caption if it exists
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          caption,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
