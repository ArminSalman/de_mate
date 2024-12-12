import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:de_mate/public_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  String query = '';
  List<String> filteredItems = [];
  List<String> filteredItemsEmail = [];

  void updateSearch(String searchQuery) {
    setState(() {
      query = searchQuery;
      filteredItems = [];
      filteredItemsEmail = [];
    });

    if (query.isNotEmpty) {
      _searchUsers(query);
      _searchUsersEmail(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      filteredItems = querySnapshot.docs
          .map((doc) => doc['username'].toString())
          .toList();
    });
  }

  Future<void> _searchUsersEmail(String query) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      filteredItemsEmail = querySnapshot.docs
          .map((doc) => doc['email'].toString())
          .toList();
    });
  }

  void clearSearch() {
    _controller.clear();
    setState(() {
      query = '';
      filteredItems = [];
      filteredItemsEmail = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search for users...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.blue,
                    onPressed: clearSearch,
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, size: 100, color: Colors.blue),
                    SizedBox(height: 10),
                    Text(
                      'Search for users to connect!',
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            filteredItems[index][0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          filteredItems[index],
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey),
                        onTap: () {
                          if (auth.currentUser?.email.toString() ==
                              filteredItemsEmail[index].toString()) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfilePage()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PublicProfilePage(
                                  userMail: filteredItemsEmail[index],
                                ),
                              ),
                            );
                          }
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
                size: 30,
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
                size: 30,
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.grey,
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
                color: cp.getCurrentPage() == 2 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                cp.setCurrentPage(2);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 30,
                color: cp.getCurrentPage() == 3 ? Colors.blue : Colors.grey,
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
              },
            ),
          ],
        ),
      ),
    );
  }
}
