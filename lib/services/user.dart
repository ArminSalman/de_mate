import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserRepository {
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');

  // Get a user by email
  Future<DocumentSnapshot<Object?>?> getUserByEmail(String email) async {
    try {
      return await _usersCollection.doc(email).get();
    } catch (e) {
      print("Error getting user: $e");
      return null;
    }
  }

  Future<int> countDocumentsInCollection(String collectionName) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(collectionName).get();

      // Return doc number
      return snapshot.size;
    } catch (e) {
      print("Error counting documents in collection '$collectionName': $e");
      return 0; // Return 0 when throws an error
    }
  }

  // Add user to Firestore
  Future<void> addUserToFirestore(String username, String email, String name, String surname, TextEditingController _birthdateController, FirebaseFirestore _firestore) async {
    await _firestore.collection('users').doc(email).set({
      'username': username,
      'email': email,
      'name': name,
      'surname': surname,
      'birthdate': _birthdateController.text,
      'createdAt': Timestamp.now(),
      'profilePicture' : "https://api.dicebear.com/9.x/adventurer/svg?seed=Kimberly",
      'mates': [],
      'sups': [],
      'deems': [],
      'receivedMateRequests': [],
      'sentMateRequests': [],
    });
  }

  // Add or update user data
  Future<void> addUserOrUpdate(String email, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(email).set(data, SetOptions(merge: true));
      print("User updated/added successfully.");
    } catch (e) {
      print("Error adding/updating user: $e");
    }
  }

  // Update specific fields for a user
  Future<void> updateUserFields(String email, Map<String, dynamic> fields) async {
    try {
      await _usersCollection.doc(email).update(fields);
      print("User fields updated successfully.");
    } catch (e) {
      print("Error updating user fields: $e");
    }
  }

  Future<void> addDeemToUser(String email, String deemId) async {
    try {
      final userSnapshot = await getUserByEmail(email);

      if (userSnapshot == null || !userSnapshot.exists) {
        // If the user document does not exist, create it with a new list of deems
        await addUserOrUpdate(email, {
          'deems': [deemId],
        });
      } else {
        // If the user document exists, update the deems list
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;
        List<dynamic> deems = List<dynamic>.from(userData?['deems'] ?? []);

        if (!deems.contains(deemId)) {
          deems.add(deemId);
          await updateUserFields(email, {'deems': deems});
        }
      }
    } catch (e) {
      print("Error updating user's deems: $e");
    }
  }

  // Delete a user
  Future<void> deleteUser(String email) async {
    try {
      await _usersCollection.doc(email).delete();
      print("User deleted successfully.");
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // Read a specific field
  Future<dynamic> readUserField(String email, String field) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(email).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?[field];
    } catch (e) {
      print("Error reading user field: $e");
      return null;
    }
  }

  // Add a new friend request
  Future<void> addMateRequest(String receiverEmail, String senderEmail) async {
    try {
      DocumentSnapshot receiverDoc = await _usersCollection.doc(receiverEmail).get();
      DocumentSnapshot senderDoc = await _usersCollection.doc(senderEmail).get();

      if (!receiverDoc.exists || !senderDoc.exists) {
        print("One or both users do not exist.");
        return;
      }

      Map<String, dynamic> receiverData = receiverDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> senderData = senderDoc.data() as Map<String, dynamic>;

      List<String> receiverRequests = List<String>.from(receiverData['receivedMateRequests'] ?? []);
      List<String> senderRequests = List<String>.from(senderData['sentMateRequests'] ?? []);

      if (!receiverRequests.contains(senderEmail)) {
        receiverRequests.add(senderEmail);
        senderRequests.add(receiverEmail);

        await _usersCollection.doc(receiverEmail).update({
          'receivedMateRequests': receiverRequests,
        });

        await _usersCollection.doc(senderEmail).update({
          'sentMateRequests': senderRequests,
        });

        print("Mate request added successfully.");
      } else {
        print("Mate request already exists.");
      }
    } catch (e) {
      print("Error adding mate request: $e");
    }
  }

  // Delete a sent mate request
  Future<void> deleteMateRequest(String receiverEmail, String senderEmail) async {
    try {
      DocumentSnapshot receiverDoc = await _usersCollection.doc(receiverEmail).get();
      DocumentSnapshot senderDoc = await _usersCollection.doc(senderEmail).get();

      if (!receiverDoc.exists || !senderDoc.exists) {
        print("One or both users do not exist.");
        return;
      }

      Map<String, dynamic> receiverData = receiverDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> senderData = senderDoc.data() as Map<String, dynamic>;

      List<String> receiverRequests = List<String>.from(receiverData['receivedMateRequests'] ?? []);
      List<String> senderRequests = List<String>.from(senderData['sentMateRequests'] ?? []);

      // Remove the sender's email from the receiver's received requests and vice versa
      receiverRequests.remove(senderEmail);
      senderRequests.remove(receiverEmail);

      // Update the Firestore documents
      await _usersCollection.doc(receiverEmail).update({
        'receivedMateRequests': receiverRequests,
      });

      await _usersCollection.doc(senderEmail).update({
        'sentMateRequests': senderRequests,
      });

      print("Mate request deleted successfully.");
    } catch (e) {
      print("Error deleting mate request: $e");
    }
  }

  // Accept a friend request
  Future<void> acceptMateRequest(String senderEmail, String receiverEmail) async {
    try {
      DocumentSnapshot senderDoc = await _usersCollection.doc(senderEmail).get();
      DocumentSnapshot receiverDoc = await _usersCollection.doc(receiverEmail).get();

      if (!senderDoc.exists || !receiverDoc.exists) {
        print("One or both users do not exist.");
        return;
      }

      Map<String, dynamic> senderData = senderDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> receiverData = receiverDoc.data() as Map<String, dynamic>;

      List<String> senderRequests = List<String>.from(senderData['sentMateRequests'] ?? []);
      List<String> receiverRequests = List<String>.from(receiverData['receivedMateRequests'] ?? []);

      List<String> senderMates = List<String>.from(senderData['mates'] ?? []);
      List<String> receiverMates = List<String>.from(receiverData['mates'] ?? []);

      if (receiverRequests.contains(senderEmail) && senderRequests.contains(receiverEmail)) {
        receiverRequests.remove(senderEmail);
        senderRequests.remove(receiverEmail);

        if (!senderMates.contains(receiverEmail)) senderMates.add(receiverEmail);
        if (!receiverMates.contains(senderEmail)) receiverMates.add(senderEmail);

        await _usersCollection.doc(receiverEmail).update({
          'receivedMateRequests': receiverRequests,
          'mates': receiverMates,
        });

        await _usersCollection.doc(senderEmail).update({
          'sentMateRequests': senderRequests,
          'mates': senderMates,
        });

        print("Mate request accepted and mates updated.");
      } else {
        print("No mate request found to accept.");
      }
    } catch (e) {
      print("Error accepting mate request: $e");
    }
  }

  // Remove a friend
  Future<void> removeMate(String email, String friendEmail) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(email).get();
      DocumentSnapshot friendDoc = await _usersCollection.doc(friendEmail).get();

      if (!userDoc.exists || !friendDoc.exists) {
        print("One or both users do not exist.");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;

      List<String> userMates = List<String>.from(userData['mates'] ?? []);
      List<String> friendMates = List<String>.from(friendData['mates'] ?? []);

      userMates.remove(friendEmail);
      friendMates.remove(email);

      await _usersCollection.doc(email).update({'mates': userMates});
      await _usersCollection.doc(friendEmail).update({'mates': friendMates});

      print("Mate removed successfully.");
    } catch (e) {
      print("Error removing friend: $e");
    }
  }
  // Save FCM token to Firestore
  Future<void> saveFCMToken(String email) async {
    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _usersCollection.doc(email).update({
          'fcmToken': fcmToken,
        });
        print("FCM Token saved successfully.");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // Handle FCM token refresh
  void handleTokenRefresh(String email) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await _usersCollection.doc(email).update({'fcmToken': newToken});
        print("FCM Token refreshed and saved.");
      } catch (e) {
        print("Error updating FCM token: $e");
      }
    });
  }
}