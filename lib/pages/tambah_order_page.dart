import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahOrderPage extends StatefulWidget {
  @override
  _TambahOrderPageState createState() => _TambahOrderPageState();
}

class _TambahOrderPageState extends State<TambahOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  String? _username;
  String? _nomorHp;
  String? _alamat;
  String? _selectedLayanan;
  double? _berat;

  // Status pembayaran dan order otomatis default dan tidak bisa diubah
  String _statusPembayaran = 'Lunas';
  String _statusOrder = 'Diproses';

  int? _hargaTotal;

  final List<String> layanan = ['Cuci Kering', 'Cuci Setrika', 'Express'];

  final Map<String, int> hargaPerKg = {
    'Cuci Kering': 5000,
    'Cuci Setrika': 7000,
    'Express': 10000,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'];
          _nomorHp = doc.data()?['nomor_hp'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data user tidak ditemukan')),
        );
      }
    }
  }

  void hitungHargaTotal() {
    if (_selectedLayanan != null && _berat != null) {
      final hargaPerItem = hargaPerKg[_selectedLayanan] ?? 0;
      setState(() {
        _hargaTotal = (_berat! * hargaPerItem).toInt();
      });
    } else {
      setState(() => _hargaTotal = null);
    }
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate() &&
        _selectedLayanan != null &&
        _username != null &&
        _nomorHp != null &&
        _hargaTotal != null) {
      try {
        // Buat order ID unik, contoh: ORD + timestamp
        String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId) // simpan dengan doc ID orderId
            .set({
          'order_id': orderId,      // simpan order_id di field juga
          'user_uid': user!.uid,
          'username': _username,
          'nomor_hp': _nomorHp,
          'alamat': _alamat,
          'layanan': _selectedLayanan,
          'berat': _berat,
          'harga_total': _hargaTotal,
          'status_pembayaran': _statusPembayaran,
          'status_order': _statusOrder,
          'tanggal_order': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi berhasil disimpan')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi semua field!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Tambah Order")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Tambah Order")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Username - disabled
              TextFormField(
                decoration: InputDecoration(labelText: "Username"),
                initialValue: _username ?? '',
                enabled: false,
              ),
              // Nomor HP - disabled
              TextFormField(
                decoration: InputDecoration(labelText: "Nomor HP"),
                initialValue: _nomorHp ?? '',
                enabled: false,
              ),
              // Alamat lengkap - input biasa
              TextFormField(
                decoration: InputDecoration(labelText: "Alamat Lengkap"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                onChanged: (value) => _alamat = value,
              ),
              // Pilih layanan
              DropdownButtonFormField<String>(
                value: _selectedLayanan,
                hint: Text("Pilih Layanan"),
                items: layanan
                    .map((layanan) => DropdownMenuItem(
                  value: layanan,
                  child: Text(layanan),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedLayanan = value);
                  hitungHargaTotal();
                },
                validator: (value) => value == null ? 'Pilih layanan' : null,
              ),
              // Berat
              TextFormField(
                decoration: InputDecoration(labelText: "Berat (kg)"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Berat wajib diisi';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Berat harus lebih dari 0 kg';
                  }
                  return null;
                },
                onChanged: (value) {
                  _berat = double.tryParse(value);
                  hitungHargaTotal();
                },
              ),
              SizedBox(height: 20),
              if (_hargaTotal != null)
                Text(
                  "Total Harga: Rp $_hargaTotal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitOrder,
                child: Text("Simpan Order"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
