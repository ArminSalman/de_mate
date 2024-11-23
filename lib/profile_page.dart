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
  final firestore = FirebaseFirestore.instance;

  Future<void> fetchUserData(String username) async {
    final doc = await firestore.collection('users').doc(username).get();

    if (doc.exists) {
      final data = doc.data();
    } else {
      print("User not found");
    }
  }

  static Random random = Random();
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Kullanıcı bilgilerini Firebase'den alıyoruz
    final User? user = auth.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 100),
              CircleAvatar(
                backgroundImage: AssetImage(
                  "assets/cm${random.nextInt(10)}.jpeg",
                ),
                radius: 50,
              ),
              const SizedBox(height: 10),
              Text(
                // Eğer `displayName` null ise bir fallback metin gösteriyoruz.
                user?.displayName ?? "User Name",
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Icon(Icons.message),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          random.nextInt(10000).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Mates",
                          style: TextStyle(),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          random.nextInt(10000).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Sups",
                          style: TextStyle(),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          random.nextInt(10000).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Decisions",
                          style: TextStyle(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
