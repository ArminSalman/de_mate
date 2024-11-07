import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kayıt fonksiyonu
  Future<void> _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    }
  }

  // Giriş fonksiyonu
  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    }
  }

  // Giriş veya kayıt formunu gösterme fonksiyonu
  void _showAuthForm({required bool isSignUp}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSignUp ? "Sign Up" : "Sign In"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isSignUp) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isSignUp) {
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords do not match")),
                    );
                    return;
                  }
                  await _signUp();
                } else {
                  await _signIn();
                }
                Navigator.of(context).pop();
              },
              child: Text(isSignUp ? "Sign Up" : "Sign In"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "...kararsız kalana yol göster.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Julius Caesar",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
            const SizedBox(height: 200),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _showAuthForm(isSignUp: false),
                  child: const Text("Sign In"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showAuthForm(isSignUp: true),
                  child: const Text("Sign Up"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
