import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/mate_profile_page.dart';
import 'package:de_mate/notification_page.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/geolocator.dart';
import 'package:geolocator/geolocator.dart';

class CurrentPage {
  int currentPage = 0;

  int getCurrentPage() {
    return currentPage;
  }

  void setCurrentPage(int i) {
    currentPage = i;
  }
}

CurrentPage cp = CurrentPage();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _showPostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const PostDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deems"),
      ),
      body: const DeemList(),
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
            const SizedBox(width: 40), // Space for the FAB
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
                cp.setCurrentPage(3);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[300],
        onPressed: _showPostDialog,
        child: const Icon(Icons.add,color: Colors.black,),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class PostDialog extends StatefulWidget {
  const PostDialog({super.key});

  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController()
  ];

  final LocationService _locationService = LocationService();

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index);
    });
  }

  void _postDeem() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _optionControllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Collect options
    Map<String, dynamic> options = {};
    for (int i = 0; i < _optionControllers.length; i++) {
      options['option${i + 1}'] = {
        'chosen': 0,
        'text': _optionControllers[i].text
      };
    }

    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    int deemId = 0;
    try {
      // Fetch the current count of deems and increment
      deemId = await userControl.countDocumentsInCollection("deems");
      deemId++;
    } catch (e) {
      print("Error counting documents: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate deem ID")),
      );
      return;
    }

    String deemIdString = "d_$deemId";

    try {
      if (auth.currentUser == null || auth.currentUser!.email == null) {
        throw Exception("User not authenticated.");
      }

      // Fetch username
      String email = auth.currentUser!.email!;
      DocumentSnapshot userDoc =
      await firestore.collection('users').doc(email).get();
      String username = userDoc['username'] ?? "Unknown User";

      // Fetch current location using LocationService
      Position position = await _locationService.getCurrentLocation();

      // Add deem to Firestore
      await firestore.collection('deems').doc(deemIdString).set({
        'author': username,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'options': options,
        'publishedTime': FieldValue.serverTimestamp(),
        'isForMate': false,
      });

      // Update user's deems
      await userControl.addDeemToUser(email, deemIdString);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deem shared successfully!")),
      );
    } catch (e) {
      print("Error while posting deem: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share deem: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create a New Deem"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            ..._optionControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: _optionControllers.length > 2
                        ? () => _removeOption(index)
                        : null,
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text("Add Option"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _postDeem,
          child: const Text("Post"),
        ),
      ],
    );
  }
}


class DeemList extends StatefulWidget {
  const DeemList({super.key});

  @override
  _DeemListState createState() => _DeemListState();
}

class _DeemListState extends State<DeemList> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";

  // Store expanded/collapsed state for each deem
  Map<String, bool> expandedDeems = {};

  // Store user's selected choices for options
  Map<String, String> userChoices = {}; // {docId: optionKey}

  Future<void> _chooseOption(String docId, String optionKey, String optionTitle) async {
    if (currentUserEmail.isEmpty) return;

    // Save user's choice in Firestore
    try {
      await firestore.collection('users').doc(currentUserEmail).update({
        'sups': FieldValue.arrayUnion(["$docId-$optionTitle"]),
      });

      setState(() {
        userChoices[docId] = optionKey; // Update the selected option locally
      });
    } catch (e) {
      print("Error saving choice: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('deems').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final deems = snapshot.data!.docs;

        return ListView.builder(
          itemCount: deems.length,
          itemBuilder: (context, index) {
            var deem = deems[index];
            var options = deem['options'] as Map<String, dynamic>;
            String docId = deem.id;
            String title = deem['title'] ?? "No Title";
            String author = deem['author'] ?? "Unknown Author";
            bool isExpanded = expandedDeems[docId] ?? false;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deem title and author
                  ListTile(
                    title: Text(title),
                    subtitle: Text("by $author"),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue,
                    ),
                    onTap: () {
                      setState(() {
                        expandedDeems[docId] = !isExpanded;
                      });
                    },
                  ),
                  // Expandable content: description and options
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        deem['description'] ?? "No Description",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(),
                    // Options with selection logic
                    ...options.entries.map((entry) {
                      String optionKey = entry.key; // e.g., option1
                      String optionText = entry.value['text'];
                      bool isSelected = userChoices[docId] == optionKey;

                      return ListTile(
                        title: Text(
                          optionText,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                        onTap: () => _chooseOption(docId, optionKey, optionText),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

