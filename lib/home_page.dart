import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
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
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";

  Map<String, String> userChoices = {}; // Kullanıcının yaptığı seçimler

  Future<int> _getNextDeemId() async {
    final counterRef = firestore.collection('counters').doc('deems');

    int nextId = 1; // Varsayılan başlangıç değeri

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (snapshot.exists) {
        final currentId = snapshot.data()?['currentId'] ?? 0;
        nextId = currentId + 1;

        // Firestore'daki ID'yi güncelle
        transaction.update(counterRef, {'currentId': nextId});
      } else {
        // Eğer ilk kez oluşturuluyorsa
        transaction.set(counterRef, {'currentId': nextId});
      }
    });

    return nextId;
  }

  Future<void> _chooseOption(String docId, String optionKey, String optionText) async {
    if (currentUserEmail.isEmpty) return;

    final docRef = firestore.collection('deems').doc(docId);
    final userDocRef = firestore.collection('users').doc(currentUserEmail);

    try {
      await firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(userDocRef);

        if (!docSnapshot.exists || !userSnapshot.exists) {
          throw Exception("Deem or User document does not exist.");
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final userData = userSnapshot.data() as Map<String, dynamic>;

        final Map<String, dynamic> options = Map<String, dynamic>.from(data['options']);
        final Map<String, String> votes = Map<String, String>.from(userData['votes'] ?? {});

        final String? previousOption = votes[docId];

        if (previousOption != null) {
          options[previousOption]['chosen'] -= 1; // Önceki seçimi azalt
        }

        options[optionKey]['chosen'] += 1; // Yeni seçimi artır

        votes[docId] = optionKey; // Kullanıcının oyunu güncelle

        transaction.update(docRef, {'options': options});
        transaction.update(userDocRef, {'votes': votes});
      });

      setState(() {
        userChoices[docId] = optionKey;
      });

      final currentContext = context;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text("$optionText seçildi!")),
      );
    } catch (e) {
      print("Error updating choice: $e");
      final currentContext = context;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text("Seçim kaydedilirken bir hata oluştu.")),
      );
    }
  }

  void _navigateToPage(int index) {
    if (index == 0 && cp.getCurrentPage() != 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      cp.setCurrentPage(0);
    } else if (index == 1 && cp.getCurrentPage() != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchPage()),
      );
      cp.setCurrentPage(1);
    } else if (index == 2 && cp.getCurrentPage() != 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      );
      cp.setCurrentPage(2);
    } else if (index == 3 && cp.getCurrentPage() != 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
      cp.setCurrentPage(3);
    }
  }

  Future<void> _createPost() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController()
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create a New Post"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    ...optionControllers.asMap().entries.map((entry) {
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
                            onPressed: optionControllers.length > 2
                                ? () => setState(() {
                              optionControllers.removeAt(index);
                            })
                                : null,
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        optionControllers.add(TextEditingController());
                      }),
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
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        optionControllers.any((controller) => controller.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in all fields")),
                      );
                      return;
                    }

                    Map<String, dynamic> options = {};
                    for (int i = 0; i < optionControllers.length; i++) {
                      options['option${i + 1}'] = {'chosen': 0, 'text': optionControllers[i].text};
                    }

                    try {
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      int deemId = await _getNextDeemId();
                      String docId = "d_$deemId";
                      await firestore.collection('deems').doc(docId).set({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'options': options,
                        'author': currentUserEmail,
                        'authorUsername': (await firestore.collection('users').doc(currentUserEmail).get()).data()?['username'] ?? "Unknown",
                        'publishedTime': FieldValue.serverTimestamp(),
                        'location': {
                          'latitude': position.latitude,
                          'longitude': position.longitude,
                        },
                        'isForMate': false,
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post created successfully!")),
                      );
                    } catch (e) {
                      print("Error creating post: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to create post: $e")),
                      );
                    }
                  },
                  child: const Text("Post"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Feed")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('deems')
            .orderBy('publishedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final deems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: deems.length,
            itemBuilder: (context, index) {
              final deem = deems[index];
              final data = deem.data() as Map<String, dynamic>;
              final options = data['options'] as Map<String, dynamic>;
              final isForMate = data['isForMate'] as bool;

              if (isForMate && !(data['mates'] as List<dynamic>).contains(currentUserEmail)) {
                return const SizedBox.shrink(); // Eğer kullanıcı arkadaş değilse, gösterme
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(data['title'] ?? "No Title"),
                      subtitle: Text("by ${data['authorUsername'] ?? "Unknown"}"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(data['description'] ?? "No Description"),
                    ),
                    const Divider(),
                    ...options.entries.map((entry) {
                      final optionKey = entry.key;
                      final optionData = entry.value as Map<String, dynamic>;
                      final isSelected = userChoices[deem.id] == optionKey;

                      return ListTile(
                        title: Text(optionData['text']),
                        trailing: Text("${optionData['chosen']} oy"),
                        onTap: () => _chooseOption(deem.id, optionKey, optionData['text']),
                        tileColor: isSelected ? Colors.blue.shade100 : null,
                      );
                    }).toList(),
                  ],
                ),
              );
            },
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
              icon: Icon(
                Icons.home,
                size: 35,
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.black,
              ),
              onPressed: () => _navigateToPage(0),
            ),
            IconButton(
              icon: Icon(
                Icons.search,
                size: 35,
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.black,
              ),
              onPressed: () => _navigateToPage(1),
            ),
            const SizedBox(width: 40), // FAB için boşluk
            IconButton(
              icon: Icon(
                Icons.notifications,
                size: 30,
                color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.black,
              ),
              onPressed: () => _navigateToPage(2),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 35,
                color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.black,
              ),
              onPressed: () => _navigateToPage(3),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[300],
        onPressed: _createPost,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
 