import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:flutter/material.dart';

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
        return PostDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Decisions"),
      ),
      body: DecisionList(),
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
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.grey,
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
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.grey,
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
                color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 35,
                color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.grey,
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
        onPressed: _showPostDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class PostDialog extends StatefulWidget {
  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController()
  ];

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

  void _postDecision() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _optionControllers.any((controller) => controller.text.isEmpty)) return;

    Map<String, dynamic> options = {};
    for (int i = 0; i < _optionControllers.length; i++) {
      options['option${i + 1}'] = {'choosen': 0};
    }

    try {
      await FirebaseFirestore.instance.collection('decisions').add({
        'author': _authorController.text, // Extract the text value from the controller
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': 'Unknown', // Replace with real location if available
        'options': options,
        'published_date': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Close the dialog upon successful posting
    } catch (e) {
      // Log or handle the error
      print("Failed to post decision: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create a New Decision"),
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
          onPressed: _postDecision,
          child: const Text("Post"),
        ),
      ],
    );
  }
}

class DecisionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('decisions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final decisions = snapshot.data!.docs;

        return ListView.builder(
          itemCount: decisions.length,
          itemBuilder: (context, index) {
            var decision = decisions[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                title: Text(
                  decision['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(decision['description']),
                onTap: () {
                  // Implement dialog for voting as before
                },
              ),
            );
          },
        );
      },
    );
  }
}
