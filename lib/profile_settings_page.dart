import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import your ThemeProvider class
import 'profile_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

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
              style: TextStyle(color: Colors.black),
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
            const SizedBox(height: 20),
            _buildThemeToggle(),
            const SizedBox(height: 20),
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

  // Theme Toggle with Sun and Moon icons closer to the switch
  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), // Control the padding for better alignment
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space the icon and switch evenly
            children: [
              Icon(
                themeProvider.isDarkMode
                    ? Icons.nightlight_round // Moon icon for dark mode
                    : Icons.wb_sunny, // Sun icon for light mode
                color: themeProvider.isDarkMode ? Colors.yellow : Colors.blue,
                size: 30, // Adjust the size of the icon
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(); // Toggle the theme when the switch is changed
                },
              ),
            ],
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
              color: Colors.white,
            ),
            label: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _updateProfilePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Update Profile Photo clicked")),
    );
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

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
