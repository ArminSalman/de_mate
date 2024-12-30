import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mate_profile_page.dart'; // Import the PublicProfilePage
import 'services/user.dart';

class DisplayMatesPage extends StatefulWidget {
  const DisplayMatesPage({super.key});

  @override
  State<DisplayMatesPage> createState() => _DisplayMatesPageState();
}

class _DisplayMatesPageState extends State<DisplayMatesPage> {
  final UserRepository _userRepository = UserRepository();
  List<DocumentSnapshot> _mates = [];

  @override
  void initState() {
    super.initState();
    _loadMates();
  }

  // Load the mates of the current user
  Future<void> _loadMates() async {
    String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    if (currentUserEmail.isNotEmpty) {
      try {
        // Fetch user data
        DocumentSnapshot<Object?>? currentUserDoc = await _userRepository.getUserByEmail(currentUserEmail);
        Map<String, dynamic> currentUserData = currentUserDoc?.data() as Map<String, dynamic>;

        // Get mates' emails
        List<String> matesEmails = List<String>.from(currentUserData['mates'] ?? []);

        // Fetch mates' profiles
        List<DocumentSnapshot> mateDocs = [];
        for (String mateEmail in matesEmails) {
          DocumentSnapshot<Object?>? mateDoc = await _userRepository.getUserByEmail(mateEmail);
          mateDocs.add(mateDoc!);
        }

        setState(() {
          _mates = mateDocs; // Store mates documents
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error loading mates!"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mates"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: _mates.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching data
          : ListView.builder(
        itemCount: _mates.length,
        itemBuilder: (context, index) {
          var mateData = _mates[index].data() as Map<String, dynamic>;
          String mateName = mateData['name'] ?? 'Unknown';
          String mateSurname = mateData['surname'] ?? 'Unknown';
          String mateProfilePic = mateData['profilePictureUrl'] ?? ''; // Assuming the profile picture URL is stored
          String mateEmail = _mates[index].id; // Use the document ID as the email

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(mateProfilePic.isNotEmpty ? mateProfilePic : 'https://example.com/default-avatar.jpg'),
            ),
            title: Text('$mateName $mateSurname'),
            subtitle: const Text('Mate'),
            onTap: () {
              // Navigate to the PublicProfilePage with the mate's email
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MateProfilePage(mateMail: mateEmail),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
