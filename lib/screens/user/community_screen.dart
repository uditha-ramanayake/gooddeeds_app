import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_screen_community.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _loading = false;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // CREATE POST
  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty &&
        _imageUrlController.text.trim().isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'text': _postController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
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

  // CREATE POST MODAL
  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      TextField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          hintText: 'Paste image URL (optional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 10),
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
      },
    );
  }

  // FOLLOW / UNFOLLOW USER
  Future<void> _toggleFollow(String userId) async {
    if (currentUserId.isEmpty) return;

    final followersRef = FirebaseFirestore.instance.collection('followers');
    final query = await followersRef
        .where('followerId', isEqualTo: currentUserId)
        .where('followingId', isEqualTo: userId)
        .get();

    if (query.docs.isNotEmpty) {
      // Unfollow
      for (var doc in query.docs) {
        await followersRef.doc(doc.id).delete();
      }
    } else {
      // Follow
      await followersRef.add({
        'followerId': currentUserId,
        'followingId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              final postId = posts[index].id;
              final postOwnerId = data['userId'];
              final likedBy = List<String>.from(data['likedBy'] ?? []);
              final isLiked = likedBy.contains(currentUserId);

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USER INFO + FOLLOW BUTTON
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(postOwnerId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) return const SizedBox();
                          final userData = userSnapshot.data!.data()
                                  as Map<String, dynamic>? ??
                              {};
                          final userName = userData['name'] ?? 'User';
                          final userImage = userData['profileImage'] ?? '';

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserProfileScreenCommunity(
                                              userId: postOwnerId),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: userImage.isNotEmpty
                                          ? NetworkImage(userImage)
                                          : null,
                                      child: userImage.isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentUserId != postOwnerId)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('followers')
                                      .where('followerId',
                                          isEqualTo: currentUserId)
                                      .where('followingId',
                                          isEqualTo: postOwnerId)
                                      .snapshots(),
                                  builder: (context, followSnapshot) {
                                    final isFollowing =
                                        followSnapshot.data?.docs.isNotEmpty ??
                                            false;
                                    return ElevatedButton(
                                      onPressed: () =>
                                          _toggleFollow(postOwnerId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing
                                            ? Colors.grey[300]
                                            : Colors.blue,
                                        foregroundColor: isFollowing
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      child: Text(
                                          isFollowing ? 'Following' : 'Follow'),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // POST TEXT
                      if (data['text'] != null && data['text'] != '')
                        Text(data['text']),
                      const SizedBox(height: 10),
                      // POST IMAGE
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
                      // COMMENT & LIKE SECTION
                      CommentLikeSection(
                        postId: postId,
                        isLiked: isLiked,
                        likedBy: likedBy,
                        postOwnerId: postOwnerId,
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

// COMMENT & LIKE SECTION
class CommentLikeSection extends StatefulWidget {
  final String postId;
  final bool isLiked;
  final List<String> likedBy;
  final String postOwnerId;

  const CommentLikeSection({
    super.key,
    required this.postId,
    required this.isLiked,
    required this.likedBy,
    required this.postOwnerId,
  });

  @override
  State<CommentLikeSection> createState() => _CommentLikeSectionState();
}

class _CommentLikeSectionState extends State<CommentLikeSection> {
  final TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  List<String> likedBy = [];

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;
    likedBy = widget.likedBy;
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (isLiked) {
      likedBy.remove(currentUser.uid);
    } else {
      likedBy.add(currentUser.uid);
    }

    await postRef.update({'likedBy': likedBy});
    setState(() => isLiked = !isLiked);
  }

  Future<void> _submitComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (_commentController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': currentUser.uid,
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  // NEW: SHOW LIKED USERS
  void _showLikedUsers() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (likedBy.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No likes yet"),
          );
        }

        return ListView.builder(
          itemCount: likedBy.length,
          itemBuilder: (context, index) {
            final userId = likedBy[index];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final userData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final userName = userData['name'] ?? 'User';
                final userImage = userData['profileImage'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(userName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreenCommunity(userId: userId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, size: 20),
              onPressed: _submitComment,
            ),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: _toggleLike,
            ),
          ],
        ),
        // CLICKABLE LIKES COUNT
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: _showLikedUsers,
            child: Text(
              '${likedBy.length} likes',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 6),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final comments = snapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comments.map((commentDoc) {
                final commentData =
                    commentDoc.data() as Map<String, dynamic>? ?? {};
                final commentId = commentDoc.id;
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(commentData['userId'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                    final userName = userData['name'] ?? 'User';
                    final canDelete = currentUser != null &&
                        (currentUser.uid == commentData['userId'] ||
                            currentUser.uid == widget.postOwnerId);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: '$userName ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  TextSpan(
                                      text: commentData['text'] ?? '',
                                      style:
                                          const TextStyle(color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                          if (canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _deleteComment(commentId),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
