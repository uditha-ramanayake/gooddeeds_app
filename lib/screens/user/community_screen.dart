import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _loading = false;

  // ➕ Create Post
  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty &&
        _imageUrlController.text.trim().isEmpty) return;

    setState(() => _loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      final userName = userData != null && userData.containsKey('name')
          ? userData['name']
          : 'User';

      final userImage = userData != null && userData.containsKey('profileImage')
          ? userData['profileImage']
          : '';

      final imageUrl = _imageUrlController.text.trim();

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'userName': userName,
        'userImage': userImage,
        'text': _postController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likedBy': [],
      });

      _postController.clear();
      _imageUrlController.clear();

      Navigator.pop(context);
    } catch (e) {
      print('Post creation error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 💬 Modal
  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📝 Post text
                  TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'What good deed did you do today?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 10),

                  // 🔗 Image URL input
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      hintText: 'Paste image URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔍 Preview image
                  if (_imageUrlController.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrlController.text,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text("Invalid Image URL");
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _loading ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;

              final likedBy = List<String>.from(data['likedBy'] ?? []);

              final isLiked =
                  currentUser != null && likedBy.contains(currentUser.uid);

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 User
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: data['userImage'] != null &&
                                    data['userImage'] != ''
                                ? NetworkImage(data['userImage'])
                                : null,
                            child: data['userImage'] == null ||
                                    data['userImage'] == ''
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            data['userName'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 📝 Text
                      Text(data['text'] ?? ''),

                      const SizedBox(height: 10),

                      // 📸 Image
                      if (data['imageUrl'] != null && data['imageUrl'] != '')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['imageUrl'],
                            errorBuilder: (context, error, stackTrace) {
                              return const Text("Image failed to load");
                            },
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ❤️ Like
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              if (currentUser == null) return;

                              final postRef = FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(posts[index].id);

                              final postSnapshot = await postRef.get();
                              final likedBy = List<String>.from(
                                  postSnapshot['likedBy'] ?? []);

                              if (!likedBy.contains(currentUser.uid)) {
                                likedBy.add(currentUser.uid);
                                await postRef.update({'likedBy': likedBy});
                              }
                            },
                          ),
                          Text('${likedBy.length} likes'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }
}
