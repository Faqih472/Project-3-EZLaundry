import 'dart:io'; // Digunakan untuk operasi file, terutama untuk PDF
import 'package:flutter/material.dart'; // Pustaka utama Flutter untuk membangun UI
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk interaksi dengan Firestore
import 'package:pdf/pdf.dart'; // Untuk definisi format PDF
import 'package:pdf/widgets.dart' as pw; // Untuk membangun widget PDF
import 'package:printing/printing.dart'; // Untuk fungsi cetak PDF
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori penyimpanan
import 'package:google_fonts/google_fonts.dart'; // Untuk font kustom (Poppins)
import 'package:intl/intl.dart'; // Untuk format tanggal dan mata uang

class LaporanPage extends StatefulWidget {
  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  // Variabel untuk menyimpan pilihan jenis laporan (orders atau pengeluaran)
  String _selectedLaporan = '';

  // --- PALET WARNA DISELARASKAN DENGAN TRANSAKSI_PAGE.DART ANDA ---
  // Kode HEX warna diambil langsung dari TransaksiPage.dart
  // Pastikan definisi ini sama persis di kedua file untuk konsistensi visual.
  final Color _primaryColor = const Color(0xFF2196F3); // Sesuai dengan Colors.blue (contoh: warna username di TransaksiPage)
  final Color _secondaryColor = const Color(0xFF42A5F5); // Sesuai dengan Colors.blue.shade400 (contoh: warna AppBar di TransaksiPage)
  final Color _backgroundColor = const Color(0xFFF5F5F5); // Sesuai dengan Colors.grey.shade100 (latar belakang Scaffold di TransaksiPage)
  final Color _cardColor = Colors.white; // Sesuai dengan Colors.white (latar belakang card di TransaksiPage)
  final Color _textColor = Colors.grey.shade800; // Sesuai dengan Colors.grey.shade800 (contoh: teks layanan/keterangan di TransaksiPage)
  final Color _lightTextColor = Colors.grey.shade600; // Sesuai dengan Colors.grey.shade600 (contoh: teks alamat/no. hp di TransaksiPage)
  final Color _subtleTextColor = Colors.grey.shade500; // Sesuai dengan Colors.grey.shade500 (contoh: teks tanggal kecil di TransaksiPage)
  final Color _successColor = Colors.green.shade700; // Sesuai dengan Colors.green.shade700 (contoh: status 'Selesai' di TransaksiPage)
  final Color _dangerColor = Colors.red.shade700; // Sesuai dengan Colors.red.shade700 (contoh: status 'Dibatalkan' di TransaksiPage)
  final Color _infoColor = const Color(0xFFFF9800); // Sesuai dengan Colors.orange (contoh: ikon edit di TransaksiPage, digunakan untuk 'Diproses' di sini)


  // Fungsi untuk mengambil data dari koleksi Firestore (orders atau pengeluaran)
  Future<List<Map<String, dynamic>>> _fetchData(String collectionName) async {
    final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Tambahkan ID dokumen untuk referensi jika diperlukan
      return data;
    }).toList();
  }

  // Fungsi untuk membuat dan menampilkan PDF laporan
  Future<void> _generateAndSavePdf(List<Map<String, dynamic>> data, String title, String fileName, String jenis) async {
    final pdf = pw.Document();

    List<String> headers;
    List<List<String>> tableData;

    if (jenis == 'orders') {
      // Filter orders yang tidak berstatus 'diproses' untuk laporan PDF
      final filteredData = data.where((order) {
        final status = (order['status_order'] ?? '').toString().toLowerCase();
        return status != 'diproses';
      }).toList();

      headers = ['Username', 'No HP', 'Alamat', 'Layanan', 'Berat', 'Status Order', 'Status Bayar', 'Tanggal', 'Order ID', 'Harga Total'];
      tableData = filteredData.map<List<String>>((order) {
        final tanggal = (order['tanggal_order'] as Timestamp?)?.toDate();
        final formattedTanggal = tanggal != null
            ? DateFormat('dd-MM-yyyy HH:mm').format(tanggal) // Format tanggal dan waktu
            : '-';
        return [
          (order['username'] ?? '').toString(),
          (order['nomor_hp'] ?? '').toString(),
          (order['alamat'] ?? '').toString(),
          (order['layanan'] ?? '').toString(),
          '${order['berat'] ?? '0'} kg',
          (order['status_order'] ?? '').toString(),
          (order['status_pembayaran'] ?? '').toString(),
          formattedTanggal,
          (order['order_id'] ?? '').toString(),
          // Format harga total ke format mata uang Rupiah
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(double.parse((order['harga_total'] ?? '0').toString())),
        ];
      }).toList();
    } else { // Jika jenis laporan adalah 'pengeluaran'
      headers = ['Kategori', 'Keterangan', 'Tanggal', 'Jumlah'];
      tableData = data.map<List<String>>((item) {
        final tanggal = (item['tanggal'] as Timestamp?)?.toDate();
        final formattedTanggal = tanggal != null
            ? DateFormat('dd-MM-yyyy').format(tanggal) // Format tanggal saja
            : '-';
        return [
          (item['kategori'] ?? '').toString(),
          (item['keterangan'] ?? '').toString(),
          formattedTanggal,
          // Format jumlah ke format mata uang Rupiah
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(double.parse((item['jumlah'] ?? '0').toString())),
        ];
      }).toList();
    }

    // Tambahkan halaman ke dokumen PDF
    pdf.addPage(
      pw.MultiPage( // MultiPage agar konten bisa berlanjut ke halaman berikutnya jika panjang
        pageFormat: PdfPageFormat.a4, // Ukuran halaman A4
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              title, // Judul laporan
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex(_secondaryColor.value.toRadixString(16).substring(2)) // Warna judul dari _secondaryColor
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          // Tampilkan pesan jika tidak ada data
          tableData.isEmpty
              ? pw.Text("Tidak ada data tersedia untuk laporan ini.")
              : pw.Table.fromTextArray(
            headers: headers, // Header kolom tabel
            data: tableData, // Data tabel
            border: pw.TableBorder.all(color: PdfColors.grey), // Border tabel
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex(_secondaryColor.value.toRadixString(16).substring(2)) // Warna header tabel dari _secondaryColor
            ),
            cellAlignment: pw.Alignment.centerLeft, // Alignment teks dalam sel
            cellPadding: pw.EdgeInsets.all(6), // Padding dalam sel
            // Penyesuaian lebar kolom untuk PDF agar tidak terjadi overflow teks
            columnWidths: {
              0: pw.FlexColumnWidth(1.5),  // Username/Kategori
              1: pw.FlexColumnWidth(1.2), // No HP/Keterangan
              2: pw.FlexColumnWidth(2.5), // Alamat
              3: pw.FlexColumnWidth(1.2), // Layanan/Tanggal
              4: pw.FlexColumnWidth(0.8),   // Berat
              5: pw.FlexColumnWidth(1.2), // Status Order
              6: pw.FlexColumnWidth(1.2), // Status Bayar
              7: pw.FlexColumnWidth(1.8),   // Tanggal
              8: pw.FlexColumnWidth(1.8),   // Order ID
              9: pw.FlexColumnWidth(1.5),   // Harga Total/Jumlah
            },
          ),
        ],
      ),
    );

    // Menampilkan preview PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Fungsi untuk menangani proses cetak PDF (menampilkan loading, memanggil generate PDF, dan menangani error)
  void _handleCetak(String jenis) async {
    final title = jenis == 'orders' ? 'Laporan Orders' : 'Laporan Pengeluaran';
    final fileName = jenis == 'orders' ? 'laporan_orders.pdf' : 'laporan_pengeluaran.pdf';
    final data = await _fetchData(jenis);

    // Tampilkan dialog loading saat membuat PDF
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _primaryColor),
                const SizedBox(height: 15),
                Text("Membuat Laporan PDF...", style: GoogleFonts.poppins(fontSize: 16, color: _textColor)),
              ],
            ),
          ),
        );
      },
    );

    try {
      await _generateAndSavePdf(data, title, fileName, jenis);
    } catch (e) {
      // Tampilkan SnackBar jika ada error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat PDF: $e")),
      );
    } finally {
      // Tutup dialog loading setelah selesai atau ada error
      Navigator.pop(context);
    }
  }

  // Widget untuk membangun konten utama laporan (daftar orders/pengeluaran)
  Widget _buildLaporanContent() {
    // Tampilkan pesan default jika belum ada laporan yang dipilih
    if (_selectedLaporan == '') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Silakan pilih jenis laporan yang ingin Anda lihat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: _lightTextColor),
            ),
          ],
        ),
      );
    }

    final collectionName = _selectedLaporan; // Tentukan koleksi berdasarkan pilihan
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchData(collectionName), // Panggil fungsi untuk mengambil data
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan: ${snapshot.error}',
              style: GoogleFonts.poppins(color: _dangerColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data ${_selectedLaporan == 'orders' ? 'orders' : 'pengeluaran'} yang tersedia.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: _lightTextColor),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8.0),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  if (collectionName == 'orders') {
                    final tanggal = (item['tanggal_order'] as Timestamp?)?.toDate();
                    final formattedTanggal = tanggal != null
                        ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal) // Format tanggal & waktu yang sama
                        : '-';

                    Color statusColor;
                    Color statusBgColor;
                    final statusOrder = (item['status_order'] ?? '').toLowerCase();

                    // Logika warna status order, diselaraskan dengan TransaksiPage
                    if (statusOrder == 'selesai') {
                      statusColor = _successColor;
                      statusBgColor = Colors.green.shade100;
                    } else if (statusOrder == 'diproses') {
                      statusColor = _infoColor;
                      statusBgColor = Colors.orange.shade100;
                    } else if (statusOrder == 'dibatalkan') {
                      statusColor = _dangerColor;
                      statusBgColor = Colors.red.shade100;
                    } else { // Default atau status lain
                      statusColor = _primaryColor;
                      statusBgColor = Colors.blue.shade100;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4, // Sesuai dengan elevasi card di TransaksiPage
                      shadowColor: Colors.blue.shade50, // Sesuai dengan shadowColor di TransaksiPage
                      color: _cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Sesuai dengan padding di TransaksiPage
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Agar Order ID dan Status terpisah
                              children: [
                                Expanded( // Pastikan Order ID dan Tanggal tidak overflow
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ID: ${item['order_id'] ?? '-'}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold, fontSize: 16, color: _subtleTextColor), // Warna teks Order ID
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tanggal: $formattedTanggal',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12, color: _subtleTextColor), // Warna teks tanggal kecil
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item['status_order'] ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, // Sesuai dengan bold di TransaksiPage
                                      fontSize: 15, // Sesuai dengan font size di TransaksiPage
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 1, color: Colors.grey), // Divider yang sama
                            // Informasi detail order
                            // Menggunakan _buildInfoRow untuk detail
                            _buildInfoRow('Username', item['username'], textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryColor)), // Sesuai warna username
                            _buildInfoRow('Layanan', '${item['layanan'] ?? '-'} (${item['berat'] ?? '-'} kg)', textStyle: GoogleFonts.poppins(fontSize: 15, color: _textColor)),
                            _buildInfoRow('Alamat', item['alamat'], textStyle: GoogleFonts.poppins(fontSize: 14, color: _lightTextColor)),
                            _buildInfoRow('No. HP', item['nomor_hp'], textStyle: GoogleFonts.poppins(fontSize: 14, color: _lightTextColor)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(double.parse((item['harga_total'] ?? '0').toString()))}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green), // Sesuai warna di TransaksiPage
                                    ),
                                    Text(
                                      'Pembayaran: ${item['status_pembayaran'] ?? 'Tidak diketahui'}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: (item['status_pembayaran'] ?? '').toLowerCase() == 'lunas' ? Colors.green.shade600 : Colors.red.shade600, // Sesuai warna di TransaksiPage
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                // Icon status pembayaran (untuk user/admin preview di laporan)
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: (item['status_pembayaran'] ?? '').toLowerCase() == 'lunas' ? Colors.green.shade100 : Colors.red.shade100, // Sesuai warna di TransaksiPage
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    (item['status_pembayaran'] ?? '').toLowerCase() == 'lunas' ? Icons.check_circle_outline : Icons.cancel_outlined,
                                    color: (item['status_pembayaran'] ?? '').toLowerCase() == 'lunas' ? Colors.green : Colors.red, // Sesuai warna di TransaksiPage
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else { // Kartu untuk pengeluaran
                    final tanggal = (item['tanggal'] as Timestamp?)?.toDate();
                    final formattedTanggal = tanggal != null
                        ? DateFormat('dd MMM yyyy').format(tanggal)
                        : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4, // Sesuai dengan elevasi card di TransaksiPage
                      shadowColor: Colors.red.shade50, // Sesuai dengan shadowColor di TransaksiPage
                      color: _cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Sesuai dengan padding di TransaksiPage
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded( // Menggunakan Expanded untuk kategori agar tidak overflow
                                  child: Text(
                                    item['kategori'] ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.red, // Sesuai warna merah di TransaksiPage
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Text(
                                  formattedTanggal,
                                  style: GoogleFonts.poppins(fontSize: 14, color: _subtleTextColor), // Warna teks tanggal kecil
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 1, color: Colors.grey), // Divider yang sama
                            Text(
                              item['keterangan'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 16, color: _textColor), // Warna teks keterangan
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(double.parse((item['jumlah'] ?? '0').toString())),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent), // Sesuai warna merahAccent di TransaksiPage
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Tombol Cetak Laporan PDF
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _selectedLaporan.isNotEmpty ? () => _handleCetak(_selectedLaporan) : null, // Disabled jika belum ada pilihan
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  _selectedLaporan.isNotEmpty
                      ? 'Cetak Laporan PDF ${_selectedLaporan == 'orders' ? 'Orders' : 'Pengeluaran'}'
                      : 'Pilih Laporan untuk Cetak PDF',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _secondaryColor, // Menggunakan warna sekunder Anda untuk tombol utama
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5, // Sedikit bayangan
                  disabledBackgroundColor: Colors.grey.shade400, // Warna disabled
                  disabledForegroundColor: Colors.grey.shade700, // Warna teks disabled
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Fungsi pembantu untuk membuat baris informasi di dalam card dengan gaya yang konsisten
  // Parameter textStyle opsional memungkinkan kustomisasi gaya teks nilai
  Widget _buildInfoRow(String label, dynamic value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: _textColor),
          ),
          Expanded( // Memastikan teks nilai mengambil sisa ruang dan bisa wrap
            child: Text(
              value?.toString() ?? '-',
              style: textStyle ?? GoogleFonts.poppins(color: _lightTextColor), // Gunakan textStyle yang diberikan atau default
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Latar belakang halaman
      appBar: AppBar(
        title: Text(
          "Laporan EZLaundry", // Judul AppBar
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _secondaryColor, // Warna AppBar
        elevation: 0, // Tanpa bayangan untuk tampilan modern
        centerTitle: true, // Judul di tengah
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kontainer untuk pilihan jenis laporan (Orders atau Pengeluaran)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Jenis Laporan:',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _selectedLaporan = 'orders'),
                          style: ElevatedButton.styleFrom(
                            // Warna tombol berubah berdasarkan pilihan
                            backgroundColor: _selectedLaporan == 'orders' ? _primaryColor : _backgroundColor,
                            foregroundColor: _selectedLaporan == 'orders' ? Colors.white : _secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: _selectedLaporan == 'orders' ? 4 : 0, // Efek bayangan saat terpilih
                            shadowColor: _selectedLaporan == 'orders' ? _primaryColor.withOpacity(0.3) : Colors.transparent,
                          ),
                          child: Text(
                            'Orders',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _selectedLaporan = 'pengeluaran'),
                          style: ElevatedButton.styleFrom(
                            // Warna tombol berubah berdasarkan pilihan
                            backgroundColor: _selectedLaporan == 'pengeluaran' ? _primaryColor : _backgroundColor,
                            foregroundColor: _selectedLaporan == 'pengeluaran' ? Colors.white : _secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: _selectedLaporan == 'pengeluaran' ? 4 : 0, // Efek bayangan saat terpilih
                            shadowColor: _selectedLaporan == 'pengeluaran' ? _primaryColor.withOpacity(0.3) : Colors.transparent,
                          ),
                          child: Text(
                            'Pengeluaran',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildLaporanContent()), // Menampilkan konten laporan dinamis
          ],
        ),
      ),
    );
  }
}