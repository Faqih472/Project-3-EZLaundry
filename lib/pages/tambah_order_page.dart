import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TambahOrderPage extends StatefulWidget {
  const TambahOrderPage({super.key});

  @override
  State<TambahOrderPage> createState() => _TambahOrderPageState();
}

class _TambahOrderPageState extends State<TambahOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  String? _username;
  String? _nomorHp;
  String? _alamat;
  String? _selectedLayanan;
  double? _berat;
  int? _hargaTotal;

  String _statusPembayaran = 'Lunas';
  String _statusOrder = 'Diproses';

  final List<String> layanan = ['Cuci Kering', 'Cuci Setrika', 'Express'];

  final Map<String, int> hargaPerKg = {
    'Cuci Kering': 5000,
    'Cuci Setrika': 7000,
    'Express': 10000,
  };

  final Map<String, IconData> layananIcons = {
    'Cuci Kering': LucideIcons.wind,
    'Cuci Setrika': LucideIcons.shirt, // pengganti iron
    'Express': LucideIcons.alarmClock,
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
          const SnackBar(content: Text('Data user tidak ditemukan')),
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

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate() &&
        _selectedLayanan != null &&
        _username != null &&
        _nomorHp != null &&
        _hargaTotal != null) {
      try {
        String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

        await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
          'order_id': orderId,
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil disimpan')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2196F3);
    final backgroundColor = Colors.white;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Tambah Order"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _username ?? '',
                enabled: false,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _nomorHp ?? '',
                enabled: false,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Nomor HP',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                onChanged: (val) => _alamat = val,
                validator: (val) => val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLayanan,
                decoration: InputDecoration(
                  labelText: 'Pilih Layanan',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: layanan.map((layanan) {
                  return DropdownMenuItem(
                    value: layanan,
                    child: Row(
                      children: [
                        Icon(layananIcons[layanan], color: primaryColor),
                        const SizedBox(width: 8),
                        Text(layanan, style: GoogleFonts.poppins()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLayanan = value);
                  hitungHargaTotal();
                },
                validator: (val) => val == null ? 'Pilih layanan' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _berat = double.tryParse(value);
                  hitungHargaTotal();
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Berat wajib diisi';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Berat harus lebih dari 0 kg';
                  return null;
                },
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Berat (kg)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              if (_hargaTotal != null)
                Text(
                  "Total Harga: Rp $_hargaTotal",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitOrder,
                icon: const Icon(LucideIcons.save),
                label: const Text("Simpan Order"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
