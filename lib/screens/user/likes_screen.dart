import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen_community.dart';

class LikesScreen extends StatelessWidget {
  final List<String> likedUserIds;

  const LikesScreen({super.key, required this.likedUserIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Likes"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: likedUserIds.isEmpty
          ? const Center(child: Text("No likes yet"))
          : ListView.builder(
              itemCount: likedUserIds.length,
              itemBuilder: (context, index) {
                final userId = likedUserIds[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(title: Text("Loading..."));
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final userName = userData['name'] ?? 'User';
                    final userImage = userData['profileImage'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userImage.isNotEmpty
                            ? NetworkImage(userImage)
                            : null,
                        child: userImage.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(userName),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreenCommunity(
                              userId: userId,
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