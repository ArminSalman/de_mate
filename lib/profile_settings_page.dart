import 'package:de_mate/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import your ThemeProvider class
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  void _logout() async {
    try {
      // Firebase sign-out
      await FirebaseAuth.instance.signOut();

      // Navigate to the login page after successful logout
      Navigator.pushReplacement(
        context,
          MaterialPageRoute(builder: (context) => const MainPage())
      ); // Adjust the route as needed
    } catch (e) {
      // Handle sign-out error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
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
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _updateProfilePhoto() {
    // Logic to pick or capture a new profile photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Update Profile Photo clicked")),
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
          tooltip: 'Go to the profile page',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile Saved")),
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.black), // Always black for light mode
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildUserInfoFields(),
            const SizedBox(height: 10),
            _buildThemeToggle(), // Theme toggle without switch
            const SizedBox(height: 5),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            onTap: _updateProfilePhoto,
            child: const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(''), // Default image
              child: Icon(Icons.edit, size: 24, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Theme Toggle Widget with Only Sun or Moon Icon
  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () {
            themeProvider.toggleTheme(); // Toggle the theme
          },
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
            controller: aboutController,
            decoration: const InputDecoration(
              labelText: "About",
              border: OutlineInputBorder(),
            ),
          ),
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
            icon: const Icon(
              Icons.logout,
              color: Colors.white, // Icon color set to white
            ),
            label: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white, // Text color set to white
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor, // Button background color
            ),
          ),
        ],
      ),
    );
  }
}
