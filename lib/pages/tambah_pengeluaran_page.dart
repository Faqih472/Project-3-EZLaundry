import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class TambahPengeluaranPage extends StatefulWidget {
  @override
  _TambahPengeluaranPageState createState() => _TambahPengeluaranPageState();
}

class _TambahPengeluaranPageState extends State<TambahPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();

  // Warna konsisten
  final Color _primaryColor = const Color(0xFF2196F3);
  final Color _secondaryColor = const Color(0xFF42A5F5);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.grey.shade800;
  final Color _lightTextColor = Colors.grey.shade600;
  final Color _subtleTextColor = Colors.grey.shade500;
  final Color _dangerColor = Colors.red.shade700;
  final Color _successColor = Colors.green.shade700;

  DateTime? _selectedDate;
  String? _selectedKategori;
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  final List<String> _kategoriList = [
    'Listrik',
    'Air',
    'Bahan Cuci',
    'Transportasi',
    'Sewa Tempat',
    'Perawatan Mesin',
    'Perlengkapan Operasional',
    'Lain-lain',
  ];

  final Map<String, IconData> _kategoriIcons = {
    'Listrik': Icons.bolt,
    'Air': Icons.water_drop,
    'Bahan Cuci': Icons.soap,
    'Transportasi': Icons.directions_car,
    'Sewa Tempat': Icons.home_work,
    'Perawatan Mesin': Icons.build,
    'Perlengkapan Operasional': Icons.inventory,
    'Lain-lain': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _secondaryColor,
              onPrimary: Colors.white,
              surface: _cardColor,
              onSurface: _textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _secondaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _simpanPengeluaran() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedKategori == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lengkapi semua isian terlebih dahulu!"),
            backgroundColor: _dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        int jumlahPengeluaran = int.parse(_jumlahController.text);

        await FirebaseFirestore.instance.collection('pengeluaran').add({
          'tanggal': _selectedDate,
          'kategori': _selectedKategori,
          'jumlah': jumlahPengeluaran,
          'keterangan': _keteranganController.text,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pengeluaran berhasil disimpan!"),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _selectedDate = DateTime.now();
          _selectedKategori = null;
          _jumlahController.clear();
          _keteranganController.clear();
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan: $e"),
            backgroundColor: _dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Tambah Pengeluaran",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _secondaryColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // Tanggal
              _buildModernCard(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: _primaryColor),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Pilih Tanggal Pengeluaran'
                                : 'Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: _selectedDate == null ? _lightTextColor : _textColor,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: _lightTextColor),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Kategori
              _buildModernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedKategori,
                    hint: Text(
                      "Pilih Kategori Pengeluaran",
                      style: GoogleFonts.poppins(color: _lightTextColor),
                    ),
                    items: _kategoriList.map((kategori) {
                      return DropdownMenuItem(
                        value: kategori,
                        child: Row(
                          children: [
                            Icon(_kategoriIcons[kategori], color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(kategori, style: GoogleFonts.poppins()),
                          ],
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return _kategoriList.map((kategori) {
                        return Row(
                          children: [
                            Icon(_kategoriIcons[kategori], color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(kategori, style: GoogleFonts.poppins()),
                          ],
                        );
                      }).toList();
                    },
                    onChanged: (value) => setState(() => _selectedKategori = value),
                    validator: (value) => value == null ? 'Kategori harus dipilih' : null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                    isExpanded: true,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Jumlah
              _buildModernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah Pengeluaran",
                      hintText: "Contoh: 50000",
                      prefixText: 'Rp ',
                      labelStyle: GoogleFonts.poppins(color: _lightTextColor),
                      hintStyle: GoogleFonts.poppins(color: _subtleTextColor),
                      prefixStyle: GoogleFonts.poppins(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah wajib diisi';
                      } else if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Masukkan angka valid (> 0)';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Keterangan
              _buildModernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: TextFormField(
                    controller: _keteranganController,
                    decoration: InputDecoration(
                      labelText: "Keterangan Pengeluaran",
                      hintText: "Contoh: Bayar listrik bulan Juni",
                      labelStyle: GoogleFonts.poppins(color: _lightTextColor),
                      hintStyle: GoogleFonts.poppins(color: _subtleTextColor),
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 16),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Keterangan wajib diisi' : null,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Tombol simpan (di tengah)
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.save, size: 20),
                  label: Text(
                    "Simpan Pengeluaran",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _simpanPengeluaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
