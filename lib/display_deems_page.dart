import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/services/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DisplayDeemsPage extends StatefulWidget {
  const DisplayDeemsPage({super.key});

  @override
  State<DisplayDeemsPage> createState() => _DisplayDeemsPageState();
}

class _DisplayDeemsPageState extends State<DisplayDeemsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Map<String, bool> expandedPosts = {};
  Map<String, String> userChoices = {};

  Future<List<DocumentSnapshot>> fetchUserDeems() async {
    final user = auth.currentUser;

    if (user == null) {
      return [];
    }

    final querySnapshot = await firestore
        .collection('deems')
        .where('author', isEqualTo: auth.currentUser?.email)
        .get();

    return querySnapshot.docs;
  }

  Future<void> _chooseOption(String docId, String optionKey, String optionText) async {
    final user = auth.currentUser;
    if (user == null) return;

    final docRef = firestore.collection('deems').doc(docId);

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Deem does not exist.");

        final data = snapshot.data() as Map<String, dynamic>;
        final options = Map<String, dynamic>.from(data['options']);
        final String? previousChoice = userChoices[docId];

        if (previousChoice != null) {
          options[previousChoice]['chosen'] -= 1;
        }
        options[optionKey]['chosen'] += 1;

        transaction.update(docRef, {'options': options});
      });

      setState(() {
        userChoices[docId] = optionKey;
        expandedPosts[docId] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$optionText seçildi!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Choose couldn't be done: $e")));
    }
  }

  Future<void> _deleteDeem(String deemId) async {
    try {
      final docRef = firestore.collection('deems').doc(deemId);
      await docRef.delete();

      setState(() {
        expandedPosts.remove(deemId);
        userChoices.remove(deemId);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deem deleted successfully.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete operation couldn't be success: $e")));
    }
  }

  Future<Widget> _buildDeemCard(DocumentSnapshot deem) async {
    final data = deem.data() as Map<String, dynamic>;
    final options = data['options'] as Map<String, dynamic>;
    final String deemId = deem.id;
    final bool isExpanded = expandedPosts[deemId] ?? false;
    var userData;

    UserRepository userControl = UserRepository();
    var userSnapshot = await userControl.getUserByEmail(data["author"]);

    if (userSnapshot != null && userSnapshot.exists) {
      userData = userSnapshot.data() as Map<String, dynamic>;
    } else {
      userData = {'profilePicture': "default_image_url", 'authorUsername': "Unknown"};
    }

    // Always return a valid widget, even if data is missing
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            expandedPosts[deemId] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: SvgPicture.network(
                      userData['profilePicture'] ?? "https://api.dicebear.com/9.x/lorelei/svg?seed=Andrea&flip=true",
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        data['author'] ?? "",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  final isSelected = userChoices[deemId] == optionKey;

                  return ListTile(
                    title: Text(optionData['text']),
                    trailing: Text("${optionData['chosen']} vote"),
                    onTap: () => _chooseOption(deemId, optionKey, optionData['text']),
                    tileColor: isSelected ? Colors.blue.shade100 : null,
                  );
                }).toList(),
              ],
              const SizedBox(height: 10),
              // Silme butonu ekleme
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text("Sil", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  // Silme işlemi için onay dialogu gösterme
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Delete Deem"),
                        content: const Text("Are you sure about deleting this deem?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteDeem(deemId);
                              Navigator.pop(context);
                            },
                            child: const Text("Yes, Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Deems")),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchUserDeems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error:: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You haven't posted a deem."));
          }

          final deems = snapshot.data!;
          return ListView.builder(
            itemCount: deems.length,
            itemBuilder: (context, index) {
              return FutureBuilder<Widget>(
                future: _buildDeemCard(deems[index]),
                builder: (context, cardSnapshot) {
                  if (cardSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (cardSnapshot.hasError) {
                    return Center(child: Text("Error: ${cardSnapshot.error}"));
                  } else if (!cardSnapshot.hasData) {
                    return const Center(child: Text("Card hasn't downloaded"));
                  }
                  return cardSnapshot.data!;
                },
              );
            },
          );
        },
      ),
    );
  }
}
