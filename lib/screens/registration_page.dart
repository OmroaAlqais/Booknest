// registration_page.dart
import 'package:booknest/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booknest/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  Future<void> _register() async {
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    try {
      UserCredential userCredential = 
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
      );

      await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
          'email': _email.text.trim(),
          'fullName': _fullName.text.trim(),
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create New Account', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            TextField(controller: _fullName, 
              decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: _email, 
              decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
            TextField(controller: _confirmPassword, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password')),
            ElevatedButton(onPressed: _register, child: const Text('Register')),
            TextButton(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage())),
              child: const Text('Already have an account? Login')),
          ],
        ),
      ),
    );
  }
}