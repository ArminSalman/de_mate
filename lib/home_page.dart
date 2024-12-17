import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/mate_profile_page.dart';
import 'package:de_mate/notification_page.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool _isPosting = false;

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
        backgroundColor: Colors.blue[400],
        centerTitle: true,
      ),
      body: const DeemList(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomIcon(Icons.home, 0, const HomePage()),
            _buildBottomIcon(Icons.search, 1, const SearchPage()),
            const SizedBox(width: 40), // Space for FAB
            _buildBottomIcon(Icons.notifications, 2, const NotificationPage()),
            _buildBottomIcon(Icons.person, 3, const ProfilePage()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[400],
        onPressed: _showPostDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  IconButton _buildBottomIcon(IconData icon, int index, Widget page) {
    return IconButton(
      icon: Icon(
        icon,
        size: 30,
        color: cp.getCurrentPage() == index ? Colors.blue : Colors.black,
      ),
      onPressed: () {
        if (cp.getCurrentPage() != index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
          cp.setCurrentPage(index);
        }
      },
    );
  }
}

class PostDialog extends StatefulWidget {
  const PostDialog({super.key});

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController()
  ];
  bool _isLoading = false;

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _postDeem() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _optionControllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _requestLocationPermission();

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get location")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Map<String, dynamic> options = {};
    for (int i = 0; i < _optionControllers.length; i++) {
      options['option${i + 1}'] = {
        'chosen': 0,
        'text': _optionControllers[i].text
      };
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await firestore.collection('deems').add({
        'author': user.email,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': {'latitude': position.latitude, 'longitude': position.longitude},
        'options': options,
        'publishedTime': FieldValue.serverTimestamp(),
        'isForMate': false,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deem posted successfully!")),
      );
    } catch (e) {
      print("Error posting deem: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post deem: $e")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Deem"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
              maxLength: 50,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLength: 200,
            ),
            ..._optionControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: "Option ${index + 1}"),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() {
                        _optionControllers.removeAt(index);
                      }),
                    ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() {
                _optionControllers.add(TextEditingController());
              }),
              icon: const Icon(Icons.add),
              label: const Text("Add Option"),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
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
          onPressed: _isLoading ? null : _postDeem,
          child: const Text("Post"),
        ),
      ],
    );
  }
}

class DeemList extends StatelessWidget {
  const DeemList({super.key});

  Future<void> _addSup(String docId, String optionKey, int currentSup) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Seçilen option için sup sayısını artır
      await firestore.collection('deems').doc(docId).update({
        'options.$optionKey.sups': currentSup + 1,
      });
    } catch (e) {
      print("Error adding sup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deems').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final deems = snapshot.data!.docs;

        return ListView.builder(
          itemCount: deems.length,
          itemBuilder: (context, index) {
            var deem = deems[index];
            var options = deem['options'] as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(deem['title'] ?? "No Title"),
                    subtitle: Text(deem['description'] ?? "No Description"),
                  ),
                  const Divider(),
                  // Seçenekleri Listele
                  ...options.entries.map((entry) {
                    String optionKey = entry.key; // option1, option2, vb.
                    String optionText = entry.value['text'];
                    int sups = entry.value['sups'] ?? 0;

                    return ListTile(
                      title: Text(optionText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$sups"), // Sup sayısını göster
                          IconButton(
                            icon: const Icon(Icons.thumb_up, color: Colors.blue),
                            onPressed: () => _addSup(deem.id, optionKey, sups),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


