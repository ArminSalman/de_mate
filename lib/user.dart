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
  Future<void> addFriendRequest(String email, String requesterEmail) async {
    try {
      await _usersCollection.doc(email).update({
        'friendRequests.$requesterEmail': true,
      });
      print("Friend request added successfully.");
    } catch (e) {
      print("Error adding friend request: $e");
    }
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(
      String email, String friendEmail) async {
    try {
      await _usersCollection.doc(email).update({
        'friendRequests.$friendEmail': FieldValue.delete(),
        'mates.$friendEmail': true,
      });
      print("Friend request accepted successfully.");
    } catch (e) {
      print("Error accepting friend request: $e");
    }
  }

  // Remove a friend
  Future<void> removeFriend(String email, String friendEmail) async {
    try {
      await _usersCollection.doc(email).update({
        'mates.$friendEmail': FieldValue.delete(),
      });
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
