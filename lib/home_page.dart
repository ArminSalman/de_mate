import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/mate_profile_page.dart';
import 'package:de_mate/services/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  Set<String> expandedPosts = {}; // Genişletilen gönderilerin kaydı
  Map<String, dynamic>? currentUserData; // Kullanıcı bilgileri için önbellek
  bool isLoading = false; // Paylaşım işlemi sırasında butonu devre dışı bırakmak için

  @override
  void initState() {
    super.initState();
    cacheCurrentUser();
  }

  Future<void> cacheCurrentUser() async {
    final userDoc = await firestore.collection('users').doc(currentUserEmail).get();
    if (userDoc.exists) {
      setState(() {
        currentUserData = userDoc.data();
      });
    }
  }

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

  void togglePost(String postId) {
    setState(() {
      if (expandedPosts.contains(postId)) {
        expandedPosts.remove(postId);
      } else {
        expandedPosts.add(postId);
      }
    });
  }

  bool isPostExpanded(String postId) {
    return expandedPosts.contains(postId);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$optionText seçildi!")),
      );
    } catch (e) {
      print("Error updating choice: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seçim kaydedilirken bir hata oluştu.")),
      );
    }
  }

  Future<void> _createPost() async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController()
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create a New Post"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value!.isEmpty ? "Title cannot be empty" : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? "Description cannot be empty" : null,
                  ),
                  ...optionControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    return TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                      validator: (value) => value!.isEmpty ? "Option cannot be empty" : null,
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                    child: const Text("Add Option"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() {
                  isLoading = true;
                });

                Map<String, dynamic> options = {};
                for (int i = 0; i < optionControllers.length; i++) {
                  options['option${i + 1}'] = {'chosen': 0, 'text': optionControllers[i].text};
                }

                try {
                  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                  int deemId = await _getNextDeemId();
                  String docId = "d_$deemId";
                  await firestore.collection('deems').doc(docId).set({
                    'authorProfilePage': currentUserData?['profilePicture'] ?? "https://via.placeholder.com/150",
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'options': options,
                    'author': currentUserEmail,
                    'authorUsername': currentUserData?['username'] ?? "Unknown",
                    'publishedTime': FieldValue.serverTimestamp(),
                    'location': {
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    },
                    'isForMate': false,
                  });

                  UserRepository userControl = UserRepository();
                  userControl.addDeemToUser(currentUserEmail, "d_$deemId");

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
                setState(() {
                  isLoading = false;
                });
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(DocumentSnapshot deem) {
    final data = deem.data() as Map<String, dynamic>;
    final options = data['options'] as Map<String, dynamic>;
    final isForMate = data['isForMate'] as bool;
    final String deemId = deem.id;

    if (isForMate && !(data['mates'] as List<dynamic>).contains(currentUserEmail)) {
      return const SizedBox.shrink();
    }

    final bool isExpanded = isPostExpanded(deemId);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: () => togglePost(deemId),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      data['authorProfilePage'] ?? "https://via.placeholder.com/150",
                    ),
                    radius: 25,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['authorUsername'] ?? "Unknown",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['author'] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data['title'] ?? "No Title",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data['description'] ?? "No Description",
                style: const TextStyle(fontSize: 16),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                ...options.entries.map((entry) {
                  final optionKey = entry.key;
                  final optionData = entry.value as Map<String, dynamic>;
                  final isSelected = userChoices[deem.id] == optionKey;

                  return ListTile(
                    title: Text(optionData['text']),
                    trailing: Text("${optionData['chosen']} votes"),
                    onTap: () => _chooseOption(deem.id, optionKey, optionData['text']),
                    tileColor: isSelected ? Colors.blue.shade100 : null,
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
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
              return _buildPostCard(deem);
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

}
