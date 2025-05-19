// admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:booknest/main.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatCard(
              title: 'Total Books',
              stream: FirebaseFirestore.instance.collection('books').snapshots(),
              value: (snapshot) => snapshot.docs.length.toString(),
            ),
            _buildStatCard(
              title: 'Total Users',
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              value: (snapshot) => snapshot.docs.length.toString(),
            ),
            _buildStatCard(
              title: 'Admins',
              stream: FirebaseFirestore.instance.collection('users')
                .where('isAdmin', isEqualTo: true).snapshots(),
              value: (snapshot) => snapshot.docs.length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String Function(QuerySnapshot) value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (!snapshot.hasData) return const CircularProgressIndicator();
            
            return Column(
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                Text(value(snapshot.data!), 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            );
          },
        ),
      ),
    );
  }
}