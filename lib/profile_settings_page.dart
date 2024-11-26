import 'package:de_mate/profile_page.dart';
import 'package:flutter/material.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool isDarkMode = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  void _logout() {
    // Implement logout logic
    Navigator.pushReplacementNamed(context, '/login'); // Adjust the route as needed
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
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
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
              child: Text(
                "Save",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
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
              backgroundImage: NetworkImage(
                '',
              ),
              child: Icon(Icons.edit, size: 24, color: Colors.white),
            ),
          ),
        ),
      ],
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

  Widget _buildThemeToggle() {
    return SwitchListTile(
      title: const Text("Dark Mode"),
      value: isDarkMode,
      onChanged: (value) {
        setState(() {
          isDarkMode = value;
        });
      },
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
              color: Colors.white, // İkonun rengi beyaz yapıldı
            ),
            label: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white, // Yazı rengi beyaz
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor, // Butonun arkaplan rengi
            ),
          ),
        ],
      ),
    );
  }
}
