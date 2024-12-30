import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'services/user.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final UserRepository _userController = UserRepository();
  final String _currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  List<Map<String, dynamic>> _notifications = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeFCM();
    _setupRealTimeNotifications();
    _initializeLocalNotifications();
    _getToken();
  }

  Future<void> _initializeFCM() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions.');
    } else {
      print('User declined or did not accept notification permissions.');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received: ${message.notification?.title}');
      _showLocalNotification(message);
      _fetchNotifications();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('app_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          print('Notification clicked with payload: ${response.payload}');
        }
      },
    );
  }

  Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        FirebaseFirestore.instance.collection('users').doc(_currentUserEmail).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      print('Error fetching FCM token: $e');
    }
  }

  void _setupRealTimeNotifications() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserEmail)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final receivedMateRequests = data['receivedMateRequests'] as List<dynamic>? ?? [];
        _updateNotifications(receivedMateRequests);
      }
    });
  }

  void _updateNotifications(List<dynamic> receivedMateRequests) async {
    final nearbyDeems = await _getNearbyDeems();

    setState(() {
      _notifications = [
        ...receivedMateRequests.map((email) => {
          'type': 'Mate Request',
          'email': email,
        }),
        ...nearbyDeems.map((deem) => {
          'type': 'New Deem',
          'deem': deem,
        }),
      ];
    });
  }

  Future<List<Map<String, dynamic>>> _getNearbyDeems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('deems')
          .where('location', isEqualTo: 'nearby')
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error fetching nearby deems: $e");
      return [];
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserEmail)
          .get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data() as Map<String, dynamic>;
        final receivedMateRequests = data['receivedMateRequests'] as List<dynamic>? ?? [];
        final nearbyDeems = await _getNearbyDeems();

        setState(() {
          _notifications = [
            ...receivedMateRequests.map((email) => {
              'type': 'Mate Request',
              'email': email,
            }),
            ...nearbyDeems.map((deem) => {
              'type': 'New Deem',
              'deem': deem,
            }),
          ];
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  void _handleMateRequest(String senderEmail) async {
    await _userController.acceptMateRequest(senderEmail, _currentUserEmail);
    _showSnackBar("Mate request accepted!");

    FirebaseFirestore.instance.collection('notifications').add({
      'recipient': senderEmail,
      'title': "Mate Request Accepted",
      'body': "Your mate request was accepted by $_currentUserEmail.",
      'timestamp': FieldValue.serverTimestamp(),
    });

    _fetchNotifications();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    var androidDetails = const AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    var notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
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
              title: Text(
                "Mate request from ${notification['email']}",
                style: const TextStyle(color: Colors.black),
              ),
              trailing: ElevatedButton(
                onPressed: () => _handleMateRequest(notification['email']),
                child: const Text(
                  "Accept",
                  style: TextStyle(color: Colors.blue),
                ),
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
                    MaterialPageRoute(builder: (context) => const HomePage()),
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
                  MaterialPageRoute(builder: (context) => const SearchPage()),
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
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
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
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  cp.setCurrentPage(3);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  var androidDetails = const AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );

  var notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
  );
}