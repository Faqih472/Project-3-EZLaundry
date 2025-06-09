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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final roleFromDb = doc.data()?['role'] ?? 'user';
      setState(() {
        userRole = roleFromDb;
        _tabController = TabController(length: userRole == 'admin' ? 3 : 2, vsync: this);
      });
    } else {
      setState(() {
        userRole = 'user';
        _tabController = TabController(length: 2, vsync: this);
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

    if (userRole.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Transaksi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Warna latar belakang yang lebih lembut
      appBar: AppBar(
        title: const Text('Data Transaksi'),
        backgroundColor: Colors.blue.shade400, // Warna app bar yang lebih modern
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70, // Warna tab tidak terpilih yang lebih lembut
          tabs: userRole == 'admin'
              ? const [
            Tab(text: 'Orders'),
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Riwayat'),
          ]
              : const [
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
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada transaksi.'));
        }

        final orders = snapshot.data!.docs;

        // Logika ini mungkin tidak sepenuhnya relevan jika query sudah memfilter 'isNotEqualTo: Selesai'
        // Namun, jika tujuannya adalah memberi pesan khusus, bisa dipertahankan.
        final adaSelesai = orders.any((order) {
          final data = order.data() as Map<String, dynamic>;
          return (data['status_order'] ?? '').toString().toLowerCase() == 'selesai';
        });

        if (adaSelesai) {
          return const Center(child: Text('Data transaksi disembunyikan karena ada status selesai.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0), // Padding untuk listview
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;
            final tanggal = (data['tanggal_order'] as Timestamp?)?.toDate();
            final formattedTanggal = tanggal != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal) // Format tanggal lebih ramah
                : '-';
            final statusPembayaran = data['status_pembayaran'] ?? 'Tidak diketahui';
            final isLunas = statusPembayaran.toLowerCase() == 'lunas';
            final statusOrder = data['status_order'] ?? '-';

            // Warna status order
            Color statusOrderColor;
            switch (statusOrder.toLowerCase()) {
              case 'diproses':
                statusOrderColor = Colors.blue.shade700;
                break;
              case 'selesai':
                statusOrderColor = Colors.green.shade700;
                break;
              case 'dibatalkan':
                statusOrderColor = Colors.red.shade700;
                break;
              default:
                statusOrderColor = Colors.grey.shade700;
            }

            return Card(
              elevation: 4, // Meningkatkan elevasi sedikit
              shadowColor: Colors.blue.shade50, // Bayangan lebih lembut
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Sudut lebih membulat
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              color: Colors.white, // Latar belakang card putih
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding di dalam card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: ${data['order_id'] ?? '-'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          statusOrder,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: statusOrderColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1, color: Colors.grey), // Pembatas visual
                    Text(
                      '${data['username'] ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue, // Warna utama untuk username
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['layanan'] ?? '-'} (${data['berat'] ?? '-'} kg)',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alamat: ${data['alamat'] ?? '-'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      'No. HP: ${data['nomor_hp'] ?? '-'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Harga: Rp${data['harga_total'] ?? '-'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green, // Warna untuk harga total
                              ),
                            ),
                            Text(
                              'Pembayaran: $statusPembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                color: isLunas ? Colors.green.shade600 : Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Tanggal: $formattedTanggal',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        // Opsi Admin (Edit/Delete) atau Status Pembayaran (User)
                        userRole == 'admin'
                            ? SizedBox(
                          width: 96, // Menentukan lebar untuk tombol agar sejajar
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 24),
                                onPressed: () => _editOrder(context, order.id, data),
                                tooltip: 'Edit Order',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                onPressed: () => _hapusOrder(order.id),
                                tooltip: 'Hapus Order',
                              ),
                            ],
                          ),
                        )
                            : Container( // Menggunakan Container agar bisa diberi ukuran atau padding jika diperlukan
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isLunas ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isLunas ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: isLunas ? Colors.green : Colors.red,
                            size: 30, // Ukuran ikon status
                          ),
                        ),
                      ],
                    ),
                  ],
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
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada pengeluaran.'));
        }

        final pengeluaran = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0), // Padding untuk listview
          itemCount: pengeluaran.length,
          itemBuilder: (context, index) {
            final doc = pengeluaran[index];
            final data = doc.data() as Map<String, dynamic>;
            final tanggal = (data['tanggal'] as Timestamp).toDate();
            final formattedTanggal = DateFormat('dd MMM yyyy').format(tanggal); // Format tanggal lebih ramah
            final kategori = data['kategori'] ?? '-';
            final keterangan = data['keterangan'] ?? '-';
            final jumlah = data['jumlah'] ?? 0;

            return Card(
              elevation: 4,
              shadowColor: Colors.red.shade50, // Bayangan berbeda untuk pengeluaran
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kategori,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red, // Warna utama untuk kategori pengeluaran
                          ),
                        ),
                        Text(
                          formattedTanggal,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1, color: Colors.grey),
                    Text(
                      keterangan,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp${NumberFormat('#,##0').format(jumlah)}', // Format angka sebagai mata uang
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.redAccent, // Warna untuk jumlah pengeluaran
                          ),
                        ),
                        userRole == 'admin'
                            ? SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 24),
                                onPressed: () => _editPengeluaran(
                                  context,
                                  doc.id,
                                  jumlah,
                                  keterangan,
                                ),
                                tooltip: 'Edit Pengeluaran',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                onPressed: () => _hapusPengeluaran(doc.id),
                                tooltip: 'Hapus Pengeluaran',
                              ),
                            ],
                          ),
                        )
                            : const SizedBox.shrink(), // Non-admin tidak melihat opsi ini
                      ],
                    ),
                  ],
                ),
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
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada riwayat transaksi.'));
        }

        final riwayat = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: riwayat.length,
          itemBuilder: (context, index) {
            final data = riwayat[index].data() as Map<String, dynamic>;
            final tanggal = (data['tanggal_order'] as Timestamp?)?.toDate();
            final formattedTanggal = tanggal != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal)
                : '-';
            final statusPembayaran = data['status_pembayaran'] ?? 'Tidak diketahui';
            final isLunas = statusPembayaran.toLowerCase() == 'lunas';
            final statusOrder = data['status_order'] ?? '-';

            Color statusOrderColor;
            switch (statusOrder.toLowerCase()) {
              case 'selesai':
                statusOrderColor = Colors.green.shade700;
                break;
              default:
                statusOrderColor = Colors.grey.shade700;
            }

            return Card(
              elevation: 4,
              shadowColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: ${data['order_id'] ?? '-'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          statusOrder,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: statusOrderColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1, color: Colors.grey),
                    Text(
                      '${data['username'] ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['layanan'] ?? '-'} (${data['berat'] ?? '-'} kg)',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alamat: ${data['alamat'] ?? '-'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      'No. HP: ${data['nomor_hp'] ?? '-'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Harga: Rp${data['harga_total'] ?? '-'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Pembayaran: $statusPembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                color: isLunas ? Colors.green.shade600 : Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Tanggal: $formattedTanggal',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isLunas ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isLunas ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: isLunas ? Colors.green : Colors.red,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Fungsi untuk Mengedit dan Menghapus ---

  void _editOrder(BuildContext context, String docId, Map<String, dynamic> data) async {
    String statusOrder = data['status_order'] ?? 'Diproses';
    String statusPembayaran = data['status_pembayaran'] ?? 'Belum Lunas';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: statusOrder,
              items: const ['Diproses', 'Selesai', 'Dibatalkan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  statusOrder = val;
                }
              },
              decoration: const InputDecoration(labelText: 'Status Order'),
            ),
            DropdownButtonFormField<String>(
              value: statusPembayaran,
              items: const ['Belum Lunas', 'Lunas']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  statusPembayaran = val;
                }
              },
              decoration: const InputDecoration(labelText: 'Status Pembayaran'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'status_order': statusOrder,
        'status_pembayaran': statusPembayaran,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil diperbarui!')),
      );
    }
  }

  void _hapusOrder(String docId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Anda yakin ingin menghapus order ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dihapus!')),
      );
    }
  }

  void _editPengeluaran(
      BuildContext context, String docId, int jumlahLama, String keteranganLama) async {
    final jumlahController = TextEditingController(text: jumlahLama.toString());
    final keteranganController = TextEditingController(text: keteranganLama);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pengeluaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keteranganController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil diperbarui!')),
      );
    }
  }

  void _hapusPengeluaran(String docId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Anda yakin ingin menghapus pengeluaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('pengeluaran').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil dihapus!')),
      );
    }
  }
}
