import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String query = '';
  List<String> filteredItems = [];

  void updateSearch(String searchQuery) {
    setState(() {
      query = searchQuery;
      filteredItems = query.isEmpty ? [] : []; // Initial empty list
    });

    if (query.isNotEmpty) {
      _searchUsers(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    // Perform Firestore search query
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff') // Range query for usernames
        .get();

    setState(() {
      filteredItems = querySnapshot.docs
          .map((doc) => doc['username'].toString()) // Assuming 'username' is the field you're searching for
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for users...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.blue[50],
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: updateSearch,
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? const SizedBox.shrink() // Nothing will show when blank
                  : ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            filteredItems[index][0].toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          filteredItems[index],
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey),
                        onTap: () {
                          // Actions when item is tapped
                        },
                      ),
                    ),
                  );
                },
              ),
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
                if (cp.getCurrentPage() != 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    ),
                  );
                  cp.setCurrentPage(1);
                }
                cp.setCurrentPage(1);
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications,
                  size: 30,
                  color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.grey),
              onPressed: () {
                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                  Icons.person,
                  size: 35,
                  color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.grey),
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