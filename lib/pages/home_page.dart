import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tambah_order_page.dart';
import 'tambah_pengeluaran_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int totalOrder = 0;
  int orderDiproses = 0;
  int orderSelesai = 0;

  String? userRole;

  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Panggil ini untuk ambil role & kemudian getOrderStats()
  }

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'user';
        });
        await getOrderStats(); // Panggil setelah dapat role
      }
    }
  }

  Future<void> getOrderStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot;

    if (userRole == 'admin') {
      snapshot = await FirebaseFirestore.instance.collection('orders').get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_uid', isEqualTo: user.uid)
          .get();
    }

    int total = snapshot.docs.length;
    int diproses = snapshot.docs.where((doc) => doc['status_order'] == 'Diproses').length;
    int selesai = snapshot.docs.where((doc) => doc['status_order'] == 'Selesai').length;

    setState(() {
      totalOrder = total;
      orderDiproses = diproses;
      orderSelesai = selesai;
    });
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedButton({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.5),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getOrderStats,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard('Total Order', totalOrder, Colors.blue, Icons.list_alt),
                    _buildStatCard('Diproses', orderDiproses, Colors.orange, Icons.sync),
                    _buildStatCard('Selesai', orderSelesai, Colors.green, Icons.check_circle),
                  ],
                ),
                SizedBox(height: 20),
                _animatedButton(
                  label: 'Tambah Order',
                  icon: Icons.add_shopping_cart,
                  color1: Colors.blueAccent,
                  color2: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TambahOrderPage()),
                    );
                  },
                ),
                if (userRole == 'admin')
                  _animatedButton(
                    label: 'Tambah Pengeluaran',
                    icon: Icons.money_off_csred,
                    color1: Colors.redAccent,
                    color2: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TambahPengeluaranPage()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
