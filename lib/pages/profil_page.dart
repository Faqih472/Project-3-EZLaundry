import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();

  bool _loading = false;

  String? _oldUsername;
  String? _oldNomorHp;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _usernameController.text = data['username'] ?? '';
      _nomorHpController.text = data['nomor_hp'] ?? '';
      _oldUsername = data['username'] ?? '';
      _oldNomorHp = data['nomor_hp'] ?? '';
      setState(() {}); // refresh UI
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) return;

    setState(() => _loading = true);

    final newUsername = _usernameController.text.trim();
    final newNomorHp = _nomorHpController.text.trim();

    try {
      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'username': newUsername,
        'nomor_hp': newNomorHp,
      });

      // Update semua orders yang Username dan nomor_hp lama sama dengan _oldUsername, _oldNomorHp
      final ordersQuery = await FirebaseFirestore.instance.collection('orders')
          .where('Username', isEqualTo: _oldUsername)
          .get();

      for (var doc in ordersQuery.docs) {
        await doc.reference.update({
          'Username': newUsername,
          'nomor_hp': newNomorHp,
        });
      }

      // Update _old values supaya next update bisa jalan benar
      _oldUsername = newUsername;
      _oldNomorHp = newNomorHp;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil berhasil diperbarui')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'Tidak diketahui';

    return Scaffold(
      appBar: AppBar(title: Text('Profil Saya')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Username wajib diisi';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                initialValue: email,
                enabled: false,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nomorHpController,
                decoration: InputDecoration(labelText: 'Nomor HP'),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nomor HP wajib diisi';
                  if (!RegExp(r'^\d+$').hasMatch(val.trim())) return 'Nomor HP harus angka';
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
