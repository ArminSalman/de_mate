import 'dart:math';
import 'package:de_mate/home_page.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/profile_settings_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.userMail});

  final String userMail;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

UserRepository userControl = new UserRepository();

class _PublicProfilePageState extends State<PublicProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData; // Store user data

  // Fetch user data based on username
  Future<void> fetchUserData(String userMail) async {
    final doc = await firestore.collection('users').doc(userMail).get();

    if (doc.exists) {
      setState(() {
        userData = doc.data(); // Update state with fetched data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(widget.userMail);
  }

  static Random random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: const Text('DeMate'),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Go to search page",
          onPressed:(){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );

          },

        ),

        actions: <Widget>[

          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Go to the profile settings page',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
            },
          ),
        ],
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 100),
            // Profile Image with a shadow effect
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 60, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Display username
            Text(
              userData?['username'] ?? "Loading...", // Show username
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 10),
            // Placeholder status
            const Text(
              "Status should be here",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            // Profile stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Mates", random.nextInt(1).toString()),
                _buildStatCard("Sups", random.nextInt(1).toString()),
                _buildStatCard("Deems", random.nextInt(1).toString()),
              ],
            ),
            const SizedBox(height: 30),
            // Buttons for actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    String email = widget.userMail; // The email of the friend
                    bool isAccepted = false;

                    try {
                      // Get the current user's document
                      DocumentSnapshot? userDoc = await userControl.getUserByEmail(auth.currentUser!.email.toString());

                      if (userDoc != null && userDoc.exists) {
                        // Extract the friendRequests field
                        Map<String, dynamic>? friendData = userDoc.data() as Map<String, dynamic>?;
                        Map<String, dynamic>? friendRequests = friendData?['friendRequests'] as Map<String, dynamic>?;

                        if (friendRequests != null) {
                          if (friendRequests.containsKey(email)) {
                            // Accept the friend request if it exists
                            isAccepted = true;
                            await userControl.acceptFriendRequest(email, auth.currentUser!.email.toString());
                            print("Friend request accepted.");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Friend request accepted.")),
                            );
                          }
                        }

                        if (!isAccepted) {
                          // Add a friend request if none exists
                          await userControl.addFriendRequest(email, auth.currentUser!.email.toString());
                          print("Friend request sent.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Friend request sent.")),
                          );
                        }
                      } else {
                        print('No user found with email: ${auth.currentUser!.email.toString()}');
                      }
                    } catch (e) {
                      print('Error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text("Follow"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                size: 35,
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.grey,),
              onPressed: () {
                if (cp.getCurrentPage() != 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                  cp.setCurrentPage(0);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.search,
                size: 35,
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.grey,),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
                cp.setCurrentPage(1);
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications,
                  size: 30,
                  color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.grey),
              onPressed: () {

                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                  Icons.person,
                  size: 35,
                  color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.grey),
              onPressed: () {
                if (cp.getCurrentPage() != 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  cp.setCurrentPage(3);
                }
                cp.setCurrentPage(3);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a stat card (e.g., Posts, Followers)
  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
