import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Update 'deems' map
  Future<void> updateDeems(String email, Map<String, dynamic> deems) async {
    try {
      await _usersCollection.doc(email).update({'deems': deems});
      print("Deems updated successfully.");
    } catch (e) {
      print("Error updating deems: $e");
    }
  }

  // Add a new friend request
  Future<void> addFriendRequest(String receiverEmail, String senderEmail) async {
    try {
      DocumentSnapshot receiverDoc = await _usersCollection.doc(receiverEmail).get();
      DocumentSnapshot senderDoc = await _usersCollection.doc(senderEmail).get();

      Map<String, dynamic> receiverData =
          receiverDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> senderData =
          senderDoc.data() as Map<String, dynamic>? ?? {};

      Map<String, dynamic> receiverRequests =
      Map<String, dynamic>.from(receiverData['friendRequests'] ?? {});
      Map<String, dynamic> senderRequests =
      Map<String, dynamic>.from(senderData['friendRequests'] ?? {});

      // Check if receiver already requested the sender
      if (receiverRequests.containsKey(senderEmail)) {
        // Mutual request found, convert to mates
        List<String> receiverMates = List<String>.from(receiverData['mates'] ?? []);
        List<String> senderMates = List<String>.from(senderData['mates'] ?? []);

        if (!receiverMates.contains(senderEmail)) receiverMates.add(senderEmail);
        if (!senderMates.contains(receiverEmail)) senderMates.add(receiverEmail);

        // Remove the friend requests
        receiverRequests.remove(senderEmail);
        senderRequests.remove(receiverEmail);

        // Update both users in Firestore
        await _usersCollection.doc(receiverEmail).update({
          'friendRequests': receiverRequests,
          'mates': receiverMates,
        });

        await _usersCollection.doc(senderEmail).update({
          'friendRequests': senderRequests,
          'mates': senderMates,
        });

        print("Mutual friend request converted to mates.");
      } else {
        // Add the friend request normally
        receiverRequests[senderEmail] = true;

        await _usersCollection.doc(receiverEmail).update({
          'friendRequests': receiverRequests,
        });

        print("Friend request added successfully.");
      }
    } catch (e) {
      print("Error adding friend request: $e");
    }
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(
      String senderEmail, String receiverEmail, FirebaseFirestore firestore) async {
    final senderRef = firestore.collection('users').doc(senderEmail);
    final receiverRef = firestore.collection('users').doc(receiverEmail);

    try {
      DocumentSnapshot senderSnapshot = await senderRef.get();
      DocumentSnapshot receiverSnapshot = await receiverRef.get();

      if (senderSnapshot.exists && receiverSnapshot.exists) {
        Map<String, dynamic> senderData =
        senderSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> receiverData =
        receiverSnapshot.data() as Map<String, dynamic>;

        // Remove friend request
        Map<String, dynamic> senderRequests =
        Map<String, dynamic>.from(senderData['friendRequests'] ?? {});
        Map<String, dynamic> receiverRequests =
        Map<String, dynamic>.from(receiverData['friendRequests'] ?? {});

        senderRequests.remove(receiverEmail);
        receiverRequests.remove(senderEmail);

        // Add to mates
        List<String> senderMates = List<String>.from(senderData['mates'] ?? []);
        List<String> receiverMates = List<String>.from(receiverData['mates'] ?? []);

        if (!senderMates.contains(receiverEmail)) senderMates.add(receiverEmail);
        if (!receiverMates.contains(senderEmail)) receiverMates.add(senderEmail);

        // Update Firestore
        await senderRef.update({
          'friendRequests': senderRequests,
          'mates': senderMates
        });
        await receiverRef.update({
          'friendRequests': receiverRequests,
          'mates': receiverMates
        });

        print("Friend request accepted and mates updated.");
      }
    } catch (e) {
      print("Error accepting friend request: $e");
    }
  }

  // Remove a friend
  Future<void> removeFriend(String email, String friendEmail) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(email).get();
      Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>? ?? {};

      List<String> mates = List<String>.from(userData['mates'] ?? []);
      mates.remove(friendEmail);

      await _usersCollection.doc(email).update({'mates': mates});
      print("Friend removed successfully.");
    } catch (e) {
      print("Error removing friend: $e");
    }
  }

  // Example: Add a sup (sup)
  Future<void> addSup(String email, String supId, dynamic value) async {
    try {
      await _usersCollection.doc(email).update({
        'sups.$supId': value,
      });
      print("Subscription added successfully.");
    } catch (e) {
      print("Error adding subscription: $e");
    }
  }
}

// Update PublicProfilePage.dart
// When sending a friend request, update button label to "Request Sent"
// Use the determineButtonLabel method to re-check and set appropriate label.
