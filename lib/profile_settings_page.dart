import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_provider.dart';
import 'profile_page.dart';
import 'package:de_mate/main.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  bool isLoading = true;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    final user = auth.currentUser;

    if (user != null) {
      fetchUserData(user.email ?? "");
    }
  }

  Future<void> fetchUserData(String email) async {
    try {
      final doc = await firestore.collection('users').doc(email).get();

      if (doc.exists) {
        userData = doc.data();
        setState(() {
          usernameController.text = userData?['username'] ?? '';
          nameController.text = userData?['name'] ?? '';
          surnameController.text = userData?['surname'] ?? '';
          birthdateController.text = userData?['birthdate'] ?? '';
          aboutController.text = userData?['about'] ?? '';
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user data: $e")),
      );
    }
  }

  Future<void> _saveUserData() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.email).update({
          'username': usernameController.text,
          'name': nameController.text,
          'surname': surnameController.text,
          'birthdate': birthdateController.text,
          'about': aboutController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving user data: $e")),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfilePicture(String avatarLink) async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.email).update({
          'profilePicture': avatarLink,
        });
        setState(() {
          userData?['profilePicture'] = avatarLink;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile picture: $e")),
      );
    }
  }

  Future<void> _showAvatarPicker() async {
    List<String> avatarLinks = [
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Liliana&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Maria&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Adrian&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Andrea&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Jack&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Caleb&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Easton&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Aidan&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Jessica&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Aiden&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Mason&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Chase&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Robert&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Oliver&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=George&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Eliza&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Leah&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Eden&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Jade&flip=true",
      "https://api.dicebear.com/9.x/lorelei/svg?seed=Sadie&flip=true"
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select an Avatar"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Set a height for the dialog
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: avatarLinks.length,
              itemBuilder: (context, index) {
                print("Avatar URL: ${avatarLinks[index]}");  // Debugging line
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfilePicture(avatarLinks[index]);
                  },
                  child: CircleAvatar(
                    radius: 30,
                    child: SvgPicture.network(
                      avatarLinks[index],
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveUserData,
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildUserInfoFields(),
            const SizedBox(height: 10),
            _buildThemeToggle(),
            const SizedBox(height: 5),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profilePicture = userData?['profilePicture'] ??
        "https://avatars.dicebear.com/api/avataaars/default.svg";
    return Stack(
      alignment: Alignment.center,
      children: [
        const SizedBox(
          height: 100,
          width: double.infinity,
        ),
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _showAvatarPicker,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profilePicture),
              child: const Icon(Icons.edit, size: 24, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: themeProvider.toggleTheme,
          child: Icon(
            themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            size: 35,
            color: themeProvider.isDarkMode ? Colors.yellow : Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildUserInfoFields() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: surnameController,
            decoration: const InputDecoration(
              labelText: "Surname",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: birthdateController,
            decoration: const InputDecoration(
              labelText: "Birthdate (e.g., YYYY-MM-DD)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("Logout", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
