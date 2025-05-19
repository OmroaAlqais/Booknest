// login_page.dart
import 'package:booknest/screens/registration_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booknest/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

 // In login_page.dart
Future signIn() async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email.text.trim(),
      password: _password.text.trim(),
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => HomeScreen()));
  } on FirebaseAuthException catch (e) {
    // Add these debug prints
    print('Error Code: ${e.code}');
    print('Error Message: ${e.message}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.code)),
    );
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
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true, 
              decoration: const InputDecoration(labelText: 'Password')),
            ElevatedButton(onPressed: signIn, child: const Text('Sign In')),
            TextButton(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const RegistrationPage())),
              child: const Text('Create New Account')),
          ],
        ),
      ),
    );
  }
}