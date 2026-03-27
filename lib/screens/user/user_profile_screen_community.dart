import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreenCommunity extends StatefulWidget {
  final String userId;

  const UserProfileScreenCommunity({super.key, required this.userId});

  @override
  State<UserProfileScreenCommunity> createState() =>
      _UserProfileScreenCommunityState();
}

class _UserProfileScreenCommunityState
    extends State<UserProfileScreenCommunity> {
  String userName = 'User';
  String userImage = '';
  int totalPoints = 0;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUserData();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        userName = data['name'] ?? 'User';
        userImage = data['profileImage'] ?? '';
        totalPoints = data['points'] ?? 0;
      });
    }
  }

  // STREAMS FOR REAL-TIME UPDATES
  Stream<int> _followersCountStream() {
    return FirebaseFirestore.instance
        .collection('followers')
        .where('followingId', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _followingCountStream() {
    return FirebaseFirestore.instance
        .collection('followers')
        .where('followerId', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<bool> _isFollowingStream() {
    if (currentUserId == widget.userId) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('followers')
        .where('followerId', isEqualTo: currentUserId)
        .where('followingId', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> _toggleFollow() async {
    if (currentUserId.isEmpty) return;

    final followersRef = FirebaseFirestore.instance.collection('followers');
    final query = await followersRef
        .where('followerId', isEqualTo: currentUserId)
        .where('followingId', isEqualTo: widget.userId)
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
        'followingId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showFollowersFollowingList(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingListScreen(
          userId: widget.userId,
          type: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  userImage.isNotEmpty ? NetworkImage(userImage) : null,
              child:
                  userImage.isEmpty ? const Icon(Icons.person, size: 50) : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Points: $totalPoints',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          // FOLLOW BUTTON
          if (currentUserId != widget.userId)
            StreamBuilder<bool>(
              stream: _isFollowingStream(),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return Center(
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                      foregroundColor: isFollowing ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // FOLLOWERS / FOLLOWING / POSTS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StreamBuilder<int>(
                stream: _followersCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return GestureDetector(
                    onTap: () => _showFollowersFollowingList('followers'),
                    child: Column(
                      children: [
                        Text('$count',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Followers'),
                      ],
                    ),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: _followingCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return GestureDetector(
                    onTap: () => _showFollowersFollowingList('following'),
                    child: Column(
                      children: [
                        Text('$count',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Following'),
                      ],
                    ),
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId', isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Column(
                    children: [
                      Text('$count',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Posts'),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          // POSTS GRID
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: widget.userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No posts yet.'),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  final data = posts[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      // Open post details (likes, comments)
                    },
                    child: data['imageUrl'] != null && data['imageUrl'] != ''
                        ? Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50),
                          ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// SCREEN FOR FOLLOWERS / FOLLOWING LIST
class FollowersFollowingListScreen extends StatelessWidget {
  final String userId;
  final String type; // 'followers' or 'following'

  const FollowersFollowingListScreen(
      {super.key, required this.userId, required this.type});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('followers')
        .where(type == 'followers' ? 'followingId' : 'followerId',
            isEqualTo: userId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(type.capitalize())),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final otherUserId = type == 'followers'
                  ? data['followerId']
                  : data['followingId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage'])
                          : null,
                      child: userData['profileImage'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData['name'] ?? 'User'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreenCommunity(
                            userId: otherUserId,
                          ),
                        ),
                      );
                    },
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

extension StringExtension on String {
  String capitalize() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}