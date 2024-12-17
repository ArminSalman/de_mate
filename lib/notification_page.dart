import 'package:de_mate/profile_page.dart';
import 'package:de_mate/search_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/user.dart'; // Import the UserRepository
import 'home_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final UserRepository _userController = UserRepository();
  final String _currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final receivedMateRequests = await _userController.readUserField(
        _currentUserEmail,
        'receivedMateRequests',
      ) as List<dynamic>?;

      final nearbyDeems = await _getNearbyDeems(); // Custom method for nearby deems

      setState(() {
        _notifications = [
          ...?receivedMateRequests?.map((email) => {
            'type': 'Mate Request',
            'email': email,
          }),
          ...nearbyDeems.map((deem) => {
            'type': 'New Deem',
            'deem': deem,
          }),
        ];
      });
    } catch (e) {
      print("Error fetching notifications: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching notifications4")),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getNearbyDeems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('deems')
          .where('location', isEqualTo: 'nearby') // Example filter
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error fetching nearby deems: $e");
      return [];
    }
  }

  void _handleMateRequest(String senderEmail) async {
    // Handle accept or reject of mate request
    await _userController.acceptMateRequest(senderEmail, _currentUserEmail);
    await _fetchNotifications(); // Refresh notifications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text("No notifications yet."))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          if (notification['type'] == 'Mate Request') {
            return ListTile(
              title: Text("Mate request from ${notification['email']}",style: const TextStyle(color: Colors.blue),),
              trailing: ElevatedButton(
                onPressed: () =>
                    _handleMateRequest(notification['email']),
                child: const Text("Accept"),
              ),
            );
          } else if (notification['type'] == 'New Deem') {
            return ListTile(
              title: const Text("New deem published nearby"),
              subtitle: Text(notification['deem']['title']),
            );
          }
          return const SizedBox.shrink();
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
                if (cp.getCurrentPage() != 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                  cp.setCurrentPage(2);
                }
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
}
