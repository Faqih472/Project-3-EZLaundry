import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahPengeluaranPage extends StatefulWidget {
  @override
  _TambahPengeluaranPageState createState() => _TambahPengeluaranPageState();
}

class _TambahPengeluaranPageState extends State<TambahPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedKategori;
  String? _jumlah;
  String? _keterangan;

  final List<String> _kategoriList = [
    '-', 'Gaji', 'Bonus', 'Listrik', 'Bahan Baku', 'Air', 'Sewa', 'Lain-lain'
  ];

  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _simpanPengeluaran() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedKategori != null) {
      try {
        // Memastikan bahwa jumlah input berupa angka
        int jumlahPengeluaran = int.parse(_jumlah!);

        await FirebaseFirestore.instance.collection('pengeluaran').add({
          'tanggal': _selectedDate,
          'kategori': _selectedKategori,
          'jumlah': jumlahPengeluaran,
          'keterangan': _keterangan,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pengeluaran berhasil disimpan!")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap lengkapi semua field!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Pengeluaran")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Pilih Tanggal'
                      : 'Tanggal: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                hint: Text("Pilih Kategori"),
                items: _kategoriList.map((kategori) => DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori),
                )).toList(),
                onChanged: (value) => setState(() => _selectedKategori = value),
                validator: (value) => value == null || value == '-' ? 'Pilih kategori' : null,
              ),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Jumlah Pengeluaran"),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Wajib diisi';
                  } else if (int.tryParse(value) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
                onChanged: (value) => _jumlah = value,
              ),
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(labelText: "Keterangan"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                onChanged: (value) => _keterangan = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _simpanPengeluaran,
                child: Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
