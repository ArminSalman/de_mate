import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                color: cp.getCurrentPage() == 0 ? Colors.blue : Colors.grey,),
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
              icon: Icon(Icons.search,
                size: 35,
                color: cp.getCurrentPage() == 1 ? Colors.blue : Colors.grey,),
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
            const SizedBox(width: 40), // Space for floating action button
            IconButton(
              icon: Icon(Icons.favorite,
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
