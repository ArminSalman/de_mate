import 'dart:math';

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
  String mail="";

  // Fetch user data based on username (not UID)
  Future<void> fetchUserData(String email) async {
    final doc = await firestore.collection('users').doc(email).get();

    if (doc.exists) {
      setState(() {
        userData = doc.data(); // Update state with fetched data
      });
    } else {
      print("User not found");
    }
  }

  @override
  void initState() {
    super.initState();
    final user = auth.currentUser;

    if (user != null) {
      // Fetch data based on username
      fetchUserData(user.email ?? ""); // Use displayName as username (or some other identifier)
    }
  }

  static Random random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 100),
            const CircleAvatar(
              radius: 50,
            ),
            const SizedBox(height: 10),
            // Display username from Firestore or "Loading..." if not available
            Text(
              userData?['username'] ??"Loading...", // Show username
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              "Status should be here",
              style: TextStyle(),
            ),
            const SizedBox(height: 20),
            // Other UI elements
          ],
        ),
      ),
    );
  }
}
