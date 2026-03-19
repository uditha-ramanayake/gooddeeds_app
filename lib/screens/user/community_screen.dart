import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _postController = TextEditingController();
  bool _loading = false;

  // 📤 Upload image to Firebase Storage
  Future<String?> _uploadImage(File file) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final ref = FirebaseStorage.instance.ref().child('post_images').child(
          '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ➕ Create Post
  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userName = userDoc['name'] ?? 'User';
      final userImage = userDoc['profileImage'] ?? '';

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'userName': userName,
        'userImage': userImage,
        'text': _postController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likedBy': [], // new field for likes
      });

      _postController.clear();
      setState(() => _selectedImage = null);

      Navigator.pop(context);
    } catch (e) {
      print('Post creation error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 📸 Pick image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // 💬 Show Create Post Modal
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
                  TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'What good deed did you do today?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _pickImage,
                        color: const Color(0xFF4CAF50),
                      ),
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
              final data = posts[index];
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
                      // 👤 User info
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
                      // 📝 Post text
                      Text(data['text'] ?? ''),
                      const SizedBox(height: 10),
                      // 📸 Post image
                      if (data['imageUrl'] != null && data['imageUrl'] != '')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(data['imageUrl']),
                        ),
                      const SizedBox(height: 10),
                      // ❤️ Like button
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
                                  .doc(data.id);
                              final postSnapshot = await postRef.get();
                              final likedBy = List<String>.from(
                                  postSnapshot['likedBy'] ?? []);

                              if (!likedBy.contains(currentUser.uid)) {
                                likedBy.add(currentUser.uid);
                                await postRef.update({'likedBy': likedBy});
                              }
                            },
                          ),
                          Text(
                              '${(data['likedBy'] as List?)?.length ?? 0} likes')
                        ],
                      )
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
