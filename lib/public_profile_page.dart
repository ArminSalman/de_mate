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

UserRepository userControl = UserRepository();

class _PublicProfilePageState extends State<PublicProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  String buttonLabel = "Loading...";
  bool isMate = false;

  Future<void> fetchUserData(String userMail) async {
    try {
      final doc = await firestore.collection('users').doc(userMail).get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
        await determineButtonLabel();
      } else {
        showError("User not found");
      }
    } catch (e) {
      showError("Failed to fetch user data: $e");
    }
  }

  Future<void> determineButtonLabel() async {
    try {
      final currentUserEmail = auth.currentUser!.email.toString();
      final currentUserDoc = await firestore.collection('users').doc(currentUserEmail).get();

      if (currentUserDoc.exists) {
        Map<String, dynamic>? currentUserData = currentUserDoc.data();
        List<String> mates = List<String>.from(currentUserData?["mates"] ?? []);
        List<String> receivedFriendRequests = List<String>.from(currentUserData?["receivedFriendRequests"] ?? []);
        List<String> sentFriendRequests = List<String>.from(currentUserData?["sentFriendRequests"] ?? []);

        print(widget.userMail);
        print(receivedFriendRequests);

        setState(() {
          if (mates.contains(widget.userMail)) {
            buttonLabel = "Mate";
            isMate = true;
          } else if (receivedFriendRequests.contains(widget.userMail)) {
            buttonLabel = "Accept Request";
          } else if (sentFriendRequests.contains(widget.userMail)) {
            buttonLabel = "Request Sent";
          } else {
            buttonLabel = "Send Request";
          }
        });
      }
    } catch (e) {
      showError("Error determining button label: $e");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(widget.userMail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('DeMate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Go to search page",
          onPressed: () {
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
            Text(
              userData?['username'] ?? "Loading...",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Status should be here",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Mates", userData?["mates"]?.length.toString() ?? "0"),
                _buildStatCard("Sups", "0"),
                _buildStatCard("Deems", "0"),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isMate || buttonLabel == "Request Sent"
                      ? null // Disable the button for mates or if a request is sent
                      : () async {
                    if (buttonLabel == "Send Request") {
                      await userControl.addFriendRequest(widget.userMail, auth.currentUser!.email!);
                    } else if (buttonLabel == "Accept Request") {
                      await userControl.acceptFriendRequest(widget.userMail, auth.currentUser!.email!);
                    }
                    await determineButtonLabel(); // Update the button label
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMate || buttonLabel == "Request Sent"
                        ? Colors.grey // Gray for mates or request sent
                        : Colors.blue, // Blue for other states
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      fontSize: isMate ? 20 : 16, // Larger font size for "Mate"
                      color: Colors.grey[800],
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
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.grey,
              ),
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
              icon: Icon(
                Icons.search,
                size: 35,
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.grey,
              ),
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
              icon: Icon(
                Icons.notifications,
                size: 30,
                color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 35,
                color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.grey,
              ),
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
