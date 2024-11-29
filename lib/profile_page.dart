import 'dart:math';
import 'package:de_mate/home_page.dart';
import 'package:de_mate/profile_settings_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData; // Store user data

  // Fetch user data based on username (email in this case)
  Future<void> fetchUserData(String email) async {
    final doc = await firestore.collection('users').doc(email).get();

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
    final user = auth.currentUser;

    if (user != null) {
      fetchUserData(user.email ?? ""); // Fetch data using email
    }
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
          tooltip: "Go to main page",
          onPressed:(){
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
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
                  onPressed: () {},
                  icon: const Icon(Icons.message),
                  label: const Text("Message"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text("Follow"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
                if (cp.getCurrentPage() != 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    ),
                  );
                  cp.setCurrentPage(1);
                }
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
