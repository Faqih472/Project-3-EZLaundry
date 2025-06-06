// transaksi_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransaksiPage extends StatefulWidget {
  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final roleFromDb = doc.data()?['role'] ?? 'user';
      setState(() {
        userRole = roleFromDb;
        _tabController = TabController(length: userRole == 'admin' ? 3 : 2, vsync: this);

      });
    } else {
      setState(() {
        userRole = 'user';
        _tabController = TabController(length: 1, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (userRole.isEmpty || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Data Transaksi')),
        body: Center(child: CircularProgressIndicator()),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Data Transaksi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: userRole == 'admin'
              ? [
            Tab(text: 'Orders'),
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Riwayat'),
          ]
              : [
            Tab(text: 'Orders'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: userRole == 'admin'
            ? [_buildOrdersTab(), _buildPengeluaranTab(), _buildRiwayatTab()]
            : [_buildOrdersTab(), _buildRiwayatTab()],
      ),

    );
  }

  Widget _buildOrdersTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    Stream<QuerySnapshot> ordersStream;

    if (userRole == 'admin') {
      ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('status_order', isNotEqualTo: 'Selesai')
          .orderBy('status_order')
          .orderBy('tanggal_order', descending: true)
          .snapshots();
    } else {
      ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('user_uid', isEqualTo: currentUser?.uid ?? '')
          .where('status_order', isNotEqualTo: 'Selesai')
          .orderBy('status_order')
          .orderBy('tanggal_order', descending: true)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada transaksi.'));
        }

        final orders = snapshot.data!.docs;

        final adaSelesai = orders.any((order) {
          final data = order.data() as Map<String, dynamic>;
          return (data['status_order'] ?? '').toString().toLowerCase() == 'selesai';
        });

        if (adaSelesai) {
          return Center(
              child: Text('Data transaksi disembunyikan karena ada status selesai.'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

            final tanggal = (data['tanggal_order'] as Timestamp?)?.toDate();
            final formattedTanggal = tanggal != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(tanggal)
                : '-';

            final statusPembayaran = data['status_pembayaran'] ?? 'Tidak diketahui';
            final isLunas = statusPembayaran.toLowerCase() == 'lunas';

            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Username: ${data['username'] ?? '-'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor HP: ${data['nomor_hp'] ?? '-'}'),
                    Text('Alamat: ${data['alamat'] ?? '-'}'),
                    Text('Layanan: ${data['layanan'] ?? '-'}'),
                    Text('Berat: ${data['berat'] ?? '-'} kg'),
                    Text('Status Order: ${data['status_order'] ?? '-'}'),
                    Text('Status Pembayaran: $statusPembayaran'),
                    Text('Tanggal Order: $formattedTanggal'),
                    Text('Order Id: ${data['order_id'] ?? '-'}'),
                    Text('Harga Total: ${data['harga_total'] ?? '-'}'),
                  ],
                ),
                trailing: userRole == 'admin'
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editOrder(context, order.id, data);
                    } else if (value == 'hapus') {
                      _hapusOrder(order.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                )
                    : Icon(
                  isLunas ? Icons.check_circle : Icons.cancel,
                  color: isLunas ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPengeluaranTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pengeluaran')
          .orderBy('tanggal', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada pengeluaran.'));
        }

        final pengeluaran = snapshot.data!.docs;

        return ListView.builder(
          itemCount: pengeluaran.length,
          itemBuilder: (context, index) {
            final data = pengeluaran[index].data() as Map<String, dynamic>;
            final tanggal = (data['tanggal'] as Timestamp).toDate();
            final formattedTanggal = DateFormat('yyyy-MM-dd').format(tanggal);
            final kategori = data['kategori'] ?? '-';
            final keterangan = data['keterangan'] ?? '-';
            final jumlah = data['jumlah'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(kategori),
                subtitle: Text('$keterangan - $formattedTanggal'),
                trailing: userRole == 'admin'
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPengeluaran(
                          context, pengeluaran[index].id, jumlah, keterangan);
                    } else if (value == 'hapus') {
                      _hapusPengeluaran(pengeluaran[index].id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                )
                    : Text('Rp $jumlah'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRiwayatTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    Stream<QuerySnapshot> riwayatStream;

    if (userRole == 'admin') {
      riwayatStream = FirebaseFirestore.instance
          .collection('orders')
          .where('status_order', isEqualTo: 'Selesai')
          .orderBy('tanggal_order', descending: true)
          .snapshots();
    } else {
      riwayatStream = FirebaseFirestore.instance
          .collection('orders')
          .where('user_uid', isEqualTo: currentUser?.uid)
          .where('status_order', isEqualTo: 'Selesai')
          .orderBy('tanggal_order', descending: true)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: riwayatStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Terjadi kesalahan: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada riwayat transaksi.'));
        }

        final riwayat = snapshot.data!.docs;

        return ListView.builder(
          itemCount: riwayat.length,
          itemBuilder: (context, index) {
            final data = riwayat[index].data() as Map<String, dynamic>;
            final tanggal = (data['tanggal_order'] as Timestamp?)?.toDate();
            final formattedTanggal = tanggal != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(tanggal)
                : '-';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                title: Text('Username: ${data['username'] ?? '-'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor HP: ${data['nomor_hp'] ?? '-'}'),
                    Text('Alamat: ${data['alamat'] ?? '-'}'),
                    Text('Layanan: ${data['layanan'] ?? '-'}'),
                    Text('Berat: ${data['berat'] ?? '-'} kg'),
                    Text('Status Order: ${data['status_order'] ?? '-'}'),
                    Text('Status Pembayaran: ${data['status_pembayaran'] ?? '-'}'),
                    Text('Tanggal Order: $formattedTanggal'),
                    Text('Order Id: ${data['order_id'] ?? '-'}'),
                    Text('Harga Total: ${data['harga_total'] ?? '-'}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editOrder(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    String statusOrder = data['status_order'] ?? 'Diproses';
    String statusPembayaran = data['status_pembayaran'] ?? 'Belum Lunas';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: statusOrder,
              items: ['Diproses', 'Selesai', 'Dibatalkan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => statusOrder = val!,
              decoration: InputDecoration(labelText: 'Status Order'),
            ),
            DropdownButtonFormField<String>(
              value: statusPembayaran,
              items: ['Belum Lunas', 'Lunas']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => statusPembayaran = val!,
              decoration: InputDecoration(labelText: 'Status Pembayaran'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Simpan')),
        ],
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'status_order': statusOrder,
        'status_pembayaran': statusPembayaran,
      });
    }
  }

  void _hapusOrder(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
  }

  void _editPengeluaran(
      BuildContext context, String docId, int jumlahLama, String keteranganLama) async {
    final jumlahController = TextEditingController(text: jumlahLama.toString());
    final keteranganController = TextEditingController(text: keteranganLama);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Pengeluaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keteranganController,
              decoration: InputDecoration(labelText: 'Keterangan'),
            ),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Simpan')),
        ],
      ),
    );

    if (result == true) {
      final jumlah = int.tryParse(jumlahController.text) ?? 0;
      final keterangan = keteranganController.text;

      await FirebaseFirestore.instance.collection('pengeluaran').doc(docId).update({
        'jumlah': jumlah,
        'keterangan': keterangan,
      });
    }
  }

  void _hapusPengeluaran(String docId) async {
    await FirebaseFirestore.instance.collection('pengeluaran').doc(docId).delete();
  }
}
  
