import 'package:booknest/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_page.dart';
import 'screens/registration_page.dart';
import 'screens/add_book.dart';
import 'screens/view_books.dart';
import 'screens/admin_dashboard.dart';
import 'screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAJH2vyfF-9L4HDkEF75mnSEcJZSDzaLmQ",
      appId: "1:970035401691:android:7c0200cd2d4c3585e9cdfe",
      messagingSenderId: "970035401691",
      projectId: "booknest-5d5e6",
    ),
  );
  runApp(const BookNestApp());
}

class BookNestApp extends StatelessWidget {
  const BookNestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookNest',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const HomeScreen() : const LoginPage();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  bool _loading = true;
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
      _isAdmin = doc.data()?['isAdmin'] == true;
    }
    setState(() => _loading = false);
  }

  void _addToCart(Map<String, dynamic> bookData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(uid).collection('items');
    final existing = await cartRef.where('bookId', isEqualTo: bookData['id']).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await doc.reference.update({'quantity': doc['quantity'] + 1});
    } else {
      await cartRef.add({
        'bookId': bookData['id'],
        'title': bookData['title'],
        'author': bookData['author'],
        'price': bookData['price'],
        'imageUrl': bookData['imageUrl'],
        'quantity': 1,
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book added to cart')),
    );
  }

  Future<void> _deleteBook(String id) async {
    await FirebaseFirestore.instance.collection('books').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book deleted'), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('📚 BookNest', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search books...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value.toLowerCase()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return data['title'].toLowerCase().contains(_search) ||
                        data['author'].toLowerCase().contains(_search);
                  }).toList();

                  if (filteredDocs.isEmpty) return const Center(child: Text('No books available.'));

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data()! as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return Card(
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? '', style: const TextStyle(fontSize: 12)),
                                    Text(data['author'] ?? '', style: const TextStyle(fontSize: 10)),
                                    const Spacer(),
                                    Text('${data['price']} OMR', style: const TextStyle(color: Colors.teal)),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (_isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteBook(doc.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart),
                                  onPressed: () => _addToCart(data),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBookPage()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(FirebaseAuth.instance.currentUser?.displayName ?? ''),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, color: Colors.teal),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          if (_isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Book'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookPage())),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Admin Dashboard'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('View Books'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewBooksPage())),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Cart'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
    );
  }
}
