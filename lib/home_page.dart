import 'package:de_mate/profile_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sample posts for the home feed
  final List<Map<String, dynamic>> posts = [
    {
      "name": "Armin Salman",
      "username": "@arminthesalman",
      "details": "This is a detailed description of the post.",
      "profilePicture": null, // Add profile picture asset path if needed
      "isExpanded": false
    },
    {
      "name": "Hacı Sağır",
      "username": "@haci_sagir",
      "details": "Another detailed post content goes here.",
      "profilePicture": null,
      "isExpanded": false
    },
    {
      "name": "Enes Belkaya",
      "username": "@enesbelkaya",
      "details": "Yet another detailed post for demonstration.",
      "profilePicture": null,
      "isExpanded": false
    },
  ];

  // Function to toggle the expansion of a post
  void toggleExpand(int index) {
    setState(() {
      posts[index]["isExpanded"] = !posts[index]["isExpanded"];
    });
  }

  // Function to show the pop-up when "sup" is clicked
  void showSupPopup(BuildContext context, int index) {
    List<String> options = ["Option 1", "Option 2", "Option 3"]; // Example options
    String? selectedOption;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Respond to ${posts[index]["name"]}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (String option in options)
                RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle option submission
                if (selectedOption != null) {
                  print("Selected: $selectedOption");
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Feed"),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: posts[index]["profilePicture"] == null
                        ? null
                        : AssetImage(posts[index]["profilePicture"]),
                    child: posts[index]["profilePicture"] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(posts[index]["name"]),
                  subtitle: Text(posts[index]["username"]),
                  trailing: IconButton(
                    icon: Icon(posts[index]["isExpanded"]
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down),
                    onPressed: () => toggleExpand(index),
                  ),
                ),
                if (posts[index]["isExpanded"])
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(posts[index]["details"]),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () => showSupPopup(context, index),
                    child: const Text("sup"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home,size: 35),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search,size: 35),
              onPressed: () {},
            ),
            const SizedBox(width: 40), // Space for floating action button
            IconButton(
              icon: const Icon(Icons.favorite,size: 30),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person,size: 35),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new post functionality
        },
        child: const Icon(Icons.add,),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}