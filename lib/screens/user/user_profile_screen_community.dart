import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPoints();
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
      });
    }
  }

  Future<void> _loadPoints() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        totalPoints = data['points'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔥 PROFILE IMAGE (FIXED)
          Center(
            child: CircleAvatar(
              radius: 50,
              child: ClipOval(
                child: userImage.isNotEmpty
                    ? Image.network(
                        userImage,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,

                        /// ✅ LOADING FIX
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },

                        /// ✅ ERROR FIX
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 50);
                        },
                      )
                    : const Icon(Icons.person, size: 50),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// USER NAME
          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          /// POINTS
          Text(
            'Points: $totalPoints',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          /// POSTS
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

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final data = posts[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TEXT POST
                          if (data['text'] != null && data['text'] != '')
                            Text(
                              data['text'],
                              style: const TextStyle(fontSize: 16),
                            ),

                          const SizedBox(height: 8),

                          /// IMAGE POST (FIXED)
                          if (data['imageUrl'] != null &&
                              data['imageUrl'] != '')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['imageUrl'],
                                fit: BoxFit.cover,

                                /// ✅ LOADING FIX
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    height: 200,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },

                                /// ✅ ERROR FIX
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    height: 200,
                                    child: Center(
                                        child: Text("Image failed to load")),
                                  );
                                },
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
        ],
      ),
    );
  }
}
