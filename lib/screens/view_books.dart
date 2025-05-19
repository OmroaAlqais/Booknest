import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewBooksPage extends StatefulWidget {
  const ViewBooksPage({Key? key}) : super(key: key);

  @override
  State<ViewBooksPage> createState() => _ViewBooksPageState();
}

class _ViewBooksPageState extends State<ViewBooksPage> {
  bool _isAdmin = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() => _isAdmin = doc.data()?['isAdmin'] == true);
    }
  }

  Future<void> _deleteBook(String id) async {
    await FirebaseFirestore.instance.collection('books').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book deleted'), backgroundColor: Colors.redAccent),
    );
  }

  void _editBook(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final _title = TextEditingController(text: data['title']);
    final _author = TextEditingController(text: data['author']);
    final _price = TextEditingController(text: data['price'].toString());
    final _imageUrl = TextEditingController(text: data['imageUrl']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Book'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _author, decoration: const InputDecoration(labelText: 'Author')),
              TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price')),
              TextField(controller: _imageUrl, decoration: const InputDecoration(labelText: 'Image URL')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('books').doc(doc.id).update({
                'title': _title.text.trim(),
                'author': _author.text.trim(),
                'price': double.tryParse(_price.text.trim()) ?? 0.0,
                'imageUrl': _imageUrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Books'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search books...',
                prefixIcon: Icon(Icons.search),
                filled: true,
              ),
              onChanged: (val) => setState(() => _search = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('books').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          
          final books = snap.data!.docs.where((doc) {
            final title = (doc['title'] ?? '').toString().toLowerCase();
            return title.contains(_search);
          }).toList();

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (_, index) {
              final doc = books[index];
              final data = doc.data()! as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(data['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
                title: Text(data['title'] ?? ''),
                subtitle: Text('${data['author']} • ${data['price']} OMR'),
                trailing: _isAdmin ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editBook(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBook(doc.id),
                    ),
                  ],
                ) : null,
              );
            },
          );
        },
      ),
    );
  }
}