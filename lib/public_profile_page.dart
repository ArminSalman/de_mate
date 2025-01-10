import 'package:de_mate/home_page.dart';
import 'package:de_mate/notification_page.dart';
import 'package:de_mate/profile_page.dart';
import 'package:de_mate/profile_settings_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'services/user.dart';

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.userMail});

  final String userMail;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

UserRepository userControl = UserRepository();

class _PublicProfilePageState extends State<PublicProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  Map<String, bool> expandedPosts = {};
  Map<String, String> userChoices = {};
  List<DocumentSnapshot> userDeems = [];
  String buttonLabel = "Loading";
  bool isMate = false;

  Future<void> fetchUserData(String userMail) async {
    try {
      final doc = await firestore.collection('users').doc(userMail).get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
        await determineButtonLabel();
      } else {
        showError("User not found");
      }
    } catch (e) {
      showError("Failed to fetch user data: $e");
    }
  }

  Future<void> _loadUserDeems() async {
    final deems = await UserRepository().fetchUserDeems(widget.userMail);
    print("Fetched deems: $deems"); // Hata ayıklama için eklendi
    setState(() {
      userDeems = deems;
    });
  }

  Future<void> _chooseOption(String docId, String optionKey, String optionText) async {
    final currentUserEmail = auth.currentUser?.email ?? "";

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
        expandedPosts[docId] = true; // Gönderi genişlemiş olarak kalmaya devam eder
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



  Future<void> determineButtonLabel() async {
    try {
      final currentUserEmail = auth.currentUser!.email.toString();
      final currentUserDoc = await firestore.collection('users').doc(currentUserEmail).get();

      if (currentUserDoc.exists) {
        Map<String, dynamic>? currentUserData = currentUserDoc.data();
        List<String> mates = List<String>.from(currentUserData?["mates"] ?? []);
        List<String> receivedMateRequests = List<String>.from(currentUserData?["receivedMateRequests"] ?? []);
        List<String> sentMateRequests = List<String>.from(currentUserData?["sentMateRequests"] ?? []);

        setState(() {
          if (mates.contains(widget.userMail)) {
            buttonLabel = "Mate";
            isMate = true;
          } else if (receivedMateRequests.contains(widget.userMail)) {
            buttonLabel = "Accept Request";
          } else if (sentMateRequests.contains(widget.userMail)) {
            buttonLabel = "Request Sent"; // Initially shows "Request Sent"
          } else {
            buttonLabel = "Add Mate"; // Default state
          }
        });
      }
    } catch (e) {
      showError("Error determining button label: $e");
    }
  }

  Future<void> _handleMateRequest() async {
    if (buttonLabel == "Request Sent") {
      // Handle deleting the sent mate request
      await userControl.deleteMateRequest(widget.userMail, auth.currentUser!.email!);
      setState(() {
        buttonLabel = "Add Mate"; // Change the button label to "Add Mate"
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mate request deleted.")));
    } else if (buttonLabel == "Add Mate") {
      // Send a mate request
      await userControl.addMateRequest(widget.userMail, auth.currentUser!.email!);
      setState(() {
        buttonLabel = "Request Sent"; // Change the button label to "Request Sent"
      });
    } else if (buttonLabel == "Accept Request") {
      // Accept a mate request
      await userControl.acceptMateRequest(widget.userMail, auth.currentUser!.email!);
    } else if (isMate) {
      // Show confirmation dialog to remove a mate
      bool shouldRemove = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Remove Mate'),
            content: const Text('Are you sure you want to remove this mate?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User pressed Cancel
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User pressed Confirm
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ) ?? false; // Default to false if the dialog is dismissed without a selection.

      if (shouldRemove) {
        await userControl.removeMate(widget.userMail, auth.currentUser!.email!);
        setState(() {
          isMate = false;
          buttonLabel = "Add Mate"; // Reset button label after removal
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mate removed successfully.")));
      }
    }
    await fetchUserData(widget.userMail); // Refresh user data
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(widget.userMail);
    _loadUserDeems(); // Deemleri yükle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('DeMate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Go to search page",
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Go to the profile settings page',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 100),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: SvgPicture.network(
                    userData?['profilePicture'] ?? "https://api.dicebear.com/9.x/lorelei/svg?seed=Andrea&flip=true",
                    placeholderBuilder: (context) => const CircularProgressIndicator(),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              userData?['username'] ?? "Loading...",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Status should be here",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Mates", userData?["mates"]?.length.toString() ?? "0"),
                _buildStatCard("Sups", "0"),
                _buildStatCard("Deems", "0"),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleMateRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMate || buttonLabel == "Request Sent"
                        ? Colors.grey // Gray for mates or request sent
                        : Colors.blue, // Blue for other states
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      fontSize: isMate ? 20 : 16, // Larger font size for "Mate"
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Yeni eklenen Deem Listesi
            const Text(
              "Deems",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            userDeems.isEmpty
                ? const Center(
              child: Text("No deems yet."),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userDeems.length,
              itemBuilder: (context, index) {
                final deem = userDeems[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(deem['title'] ?? 'No Title'),
                    subtitle: Text(deem['description'] ?? 'No Description'),
                  ),
                );
              },
            ),
          ],
        ),
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
                if (cp.getCurrentPage() != 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  cp.setCurrentPage(3);
                }
                cp.setCurrentPage(3);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot deem) {
    final currentUserEmail = auth.currentUser?.email ?? "";
    final data = deem.data() as Map<String, dynamic>;
    final options = data['options'] as Map<String, dynamic>;
    final isForMate = data['isForMate'] as bool;
    final String deemId = deem.id;
    Map<String, dynamic>? userData;

    if (isForMate && !(data['mates'] as List<dynamic>).contains(currentUserEmail)) {
      return const SizedBox.shrink(); // Eğer kullanıcı arkadaş değilse, gösterme
    }

    // Gönderinin genişletilip genişletilmediğini kontrol et
    final bool isExpanded = expandedPosts[deemId] ?? false;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            expandedPosts[deemId] = !isExpanded; // Gönderiyi genişlet/küçült
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gönderi başlığı ve yazar bilgisi
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: SvgPicture.network(
                      data['profilePicture'] ?? "https://api.dicebear.com/9.x/lorelei/svg?seed=Andrea&flip=true",
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                      fit: BoxFit.contain,
                    ),
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
              // Başlık ve açıklama
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
                // Seçenekler ve oy sayıları
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




  Widget buildDeemsList() {
    if (userDeems.isEmpty) {
      return const Center(child: Text("No deems yet."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userDeems.length,
      itemBuilder: (context, index) {
        final deem = userDeems[index];
        return _buildPostCard(deem);
      },
    );
  }


  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
