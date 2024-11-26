import 'package:de_mate/profile_page.dart';
import 'package:flutter/material.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // Karanlık mod durumu (Varsayılan olarak aydınlık mod)
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(), // Aydınlık tema
      darkTheme: ThemeData.dark(), // Karanlık tema
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Mod seçimi
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Edit Profile"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Go to the profile page',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Kaydetme İşlevi
              },
              child: Text(
                "Kaydet",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black, // Renk doğru şekilde atanıyor
                ),
              ),
            ),


          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context), // Profil fotoğrafı güncelleme
              const SizedBox(height: 20),
              _buildUserInfoFields(), // Kullanıcı bilgilerini güncelleme
              const SizedBox(height: 20),
              // Karanlık Mod Anahtarı
              SwitchListTile(
                title: const Text("Karanlık Mod"),
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profil Fotoğrafı
Widget _buildHeader(BuildContext context) {
  return Stack(
    alignment: Alignment.center, // Ortalamak için kullanıyoruz
    children: [
      Container(
        height: 100, // Yükseklik belirliyoruz
        width: double.infinity, // Genişlik ekran boyunca
      ),
      const Positioned(
        top: 0, // Üstte konumlandırıyoruz
        child: CircleAvatar(
          radius: 50, // Boyutunu ayarlıyoruz
          backgroundImage: NetworkImage(
              'https://img.a.transfermarkt.technology/portrait/header/306462-1728391751.JPG?lm=1'),
        ),
      ),
    ],
  );
}

// Kullanıcı Bilgileri
Widget _buildUserInfoFields() {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: "Username",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            labelText: "About",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
      ],
    ),
  );
}

