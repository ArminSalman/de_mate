import 'package:de_mate/home_page.dart';
import 'package:de_mate/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _birthdateController.text =
        "${pickedDate.toLocal()}".split(' ')[0]; // Format date as yyyy-MM-dd
      });
    }
  }

  // Add user to Firestore
  Future<void> _addUserToFirestore(String username, String email,String name, String surname) async {
    await _firestore.collection('users').doc(email).set({
      'username': username,
      'email': email,
      'name': name,
      'surname': surname,
      'birthdate': _birthdateController.text,
      'createdAt': Timestamp.now(),
      'mates': {},
      'sups' : {},
      'deems' : {},
      'friendRequests' : {},
    });
  }

  // Check if the username is unique
  Future<bool> _isUsernameUnique(String username) async {
    final query = await _firestore.collection('users').where('username', isEqualTo: username).get();
    return query.docs.isNotEmpty;
  }

  // Check if the email is unique
  Future<bool> _isEmailUnique(String email) async {
    final query = await _firestore.collection('users').where('email', isEqualTo: email).get();
    return query.docs.isNotEmpty;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (await _isUsernameUnique(_usernameController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username already exists")),
          );
          return;
        }else if(await _isEmailUnique(_emailController.text)){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email already exists")),
          );
          return;
        }else{
          await _auth.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          _addUserToFirestore(_usernameController.text, _emailController.text, _nameController.text, _surnameController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage())
          );
        }

      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'), // Add your image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person,
                          ),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.badge,
                          ),
                          _buildTextField(
                            controller: _surnameController,
                            label: 'Surname',
                            icon: Icons.family_restroom,
                          ),
                          _buildDatePickerField(),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            obscureText: true,
                          ),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 40,
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16,color: Colors.blue),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage())
                              );
                            },
                            child: const Text("Have an account? Login here",style: TextStyle(color: Colors.blue),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          if (label == 'Password' && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          if (label == 'Confirm Password' &&
              value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _birthdateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Birthdate',
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDate(context),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your birthdate';
          }
          return null;
        },
      ),
    );
  }
}
