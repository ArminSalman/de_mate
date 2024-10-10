import 'package:de_mate/main.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      appBar: AppBar(
        title: const Text('Sign In Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your email',
                    contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your password'
                ),
              ),
            ),
            const SizedBox(height: 20,),
            const TextButton(onPressed: null,
                child: Text("Sign In"),
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
              child: const Text('Go back!'),
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.blue),
                backgroundColor: WidgetStatePropertyAll(Colors.white),
              ),
            ),
          ],
        ),
    ),
      ),
    );
  }
}