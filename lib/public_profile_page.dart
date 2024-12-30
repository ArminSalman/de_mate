import 'package:de_mate/home_page.dart';
import 'package:de_mate/notification_page.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/profile_settings_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/user.dart';

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
  String buttonLabel = "Loading";
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
        List<String> receivedMateRequests = List<String>.from(currentUserData?["receivedMateRequests"] ?? []);
        List<String> sentMateRequests = List<String>.from(currentUserData?["sentMateRequests"] ?? []);

        setState(() {
          if (mates.contains(widget.userMail)) {
            buttonLabel = "Mate";
            isMate = true;
          } else if (receivedMateRequests.contains(widget.userMail)) {
            buttonLabel = "Accept Request";
          } else if (sentMateRequests.contains(widget.userMail)) {
            buttonLabel = "Request Sent"; // Initially shows "Request Sent"
          } else {
            buttonLabel = "Add Mate"; // Default state
          }
        });
      }
    } catch (e) {
      showError("Error determining button label: $e");
    }
  }

  Future<void> _handleMateRequest() async {
    if (buttonLabel == "Request Sent") {
      // Handle deleting the sent mate request
      await userControl.deleteMateRequest(widget.userMail, auth.currentUser!.email!);
      setState(() {
        buttonLabel = "Add Mate"; // Change the button label to "Add Mate"
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mate request deleted.")));
    } else if (buttonLabel == "Add Mate") {
      // Send a mate request
      await userControl.addMateRequest(widget.userMail, auth.currentUser!.email!);
      setState(() {
        buttonLabel = "Request Sent"; // Change the button label to "Request Sent"
      });
    } else if (buttonLabel == "Accept Request") {
      // Accept a mate request
      await userControl.acceptMateRequest(widget.userMail, auth.currentUser!.email!);
    } else if (isMate) {
      // Show confirmation dialog to remove a mate
      bool shouldRemove = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Remove Mate'),
            content: const Text('Are you sure you want to remove this mate?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User pressed Cancel
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User pressed Confirm
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ) ?? false; // Default to false if the dialog is dismissed without a selection.

      if (shouldRemove) {
        await userControl.removeMate(widget.userMail, auth.currentUser!.email!);
        setState(() {
          isMate = false;
          buttonLabel = "Add Mate"; // Reset button label after removal
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mate removed successfully.")));
      }
    }
    await fetchUserData(widget.userMail); // Refresh user data
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
                  child: Image.network(userData?['profilePicture'] ?? "https://api.dicebear.com/9.x/lorelei/svg?seed=Andrea&flip=true"),
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
                  onPressed: _handleMateRequest,
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
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.black,
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
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.black,
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
                color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.black,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 35,
                color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.black,
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
