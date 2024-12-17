import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/user.dart';

class MateProfilePage extends StatefulWidget {
  const MateProfilePage({super.key, required this.mateMail});

  final String mateMail;

  @override
  State<MateProfilePage> createState() => _MateProfilePageState();
}

UserRepository userControl = UserRepository();

class _MateProfilePageState extends State<MateProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  String buttonLabel = "Loading..."; // Label for the button (initially loading)
  bool isMate = false; // Whether the user is already a mate

  // Fetch the user's data from Firestore
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

  // Determine the label for the button based on the current user's relationship with this user
  Future<void> determineButtonLabel() async {
    try {
      final currentUserEmail = auth.currentUser!.email.toString();
      final currentUserDoc = await firestore.collection('users').doc(currentUserEmail).get();

      if (currentUserDoc.exists) {
        Map<String, dynamic>? currentUserData = currentUserDoc.data();
        List<String> mates = List<String>.from(currentUserData?["mates"] ?? []);

        setState(() {
          if (mates.contains(widget.mateMail)) {
            buttonLabel = "Mate";
            isMate = true;
          } else {
            buttonLabel = "Send Request"; // This can be adjusted if needed
            isMate = false;
          }
        });
      }
    } catch (e) {
      showError("Error determining button label: $e");
    }
  }

  // Show an error message
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(widget.mateMail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('DeMate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Go Back",
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
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
            // Show only the "Mate" button if the user is a mate
            // Show different buttons based on whether the user is a mate
            ElevatedButton(
              onPressed: () async {
                if (isMate) {
                  // Remove mate logic
                  await userControl.removeMate(auth.currentUser!.email!, widget.mateMail);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mate removed successfully.")),
                  );
                  await determineButtonLabel(); // Refresh button state
                } else {
                  // Send mate request logic
                  await userControl.addMateRequest(widget.mateMail, auth.currentUser!.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mate request sent successfully.")),
                  );
                  await determineButtonLabel(); // Refresh button state
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isMate ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
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
