import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class LaporanPage extends StatefulWidget {
  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String _selectedLaporan = '';

  Future<List<Map<String, dynamic>>> _fetchData(String collectionName) async {
    final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _generateAndSavePdf(List<Map<String, dynamic>> data, String title, String fileName, String jenis) async {
    final pdf = pw.Document();

    List<String> headers;
    List<List<String>> tableData;

    if (jenis == 'orders') {
      headers = ['username', 'No HP', 'Alamat', 'Layanan', 'Berat', 'Status Order', 'Status Bayar', 'Tanggal', 'Order ID', 'Harga Total'];
      tableData = data.map<List<String>>((order) {
        final tanggal = (order['tanggal_order'] as Timestamp?)?.toDate();
        final formattedTanggal = tanggal != null
            ? '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')} '
            '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}'
            : '';
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
          (order['harga_total'] ?? '').toString(),
        ];
      }).toList();
    } else {
      headers = ['Kategori', 'Keterangan', 'Tanggal', 'Jumlah'];
      tableData = data.map<List<String>>((item) {
        final tanggal = (item['tanggal'] as Timestamp?)?.toDate();
        final formattedTanggal = tanggal != null
            ? '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}'
            : '-';
        return [
          (item['kategori'] ?? '').toString(),
          (item['keterangan'] ?? '').toString(),
          formattedTanggal,
          'Rp ${(item['jumlah'] ?? 0).toString()}'
        ];
      }).toList();
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          tableData.isEmpty
              ? pw.Text("Tidak ada data tersedia.")
              : pw.Table.fromTextArray(headers: headers, data: tableData),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF berhasil disimpan di ${file.path}')),
    );
  }

  void _handleCetak(String jenis) async {
    final title = jenis == 'orders' ? 'Laporan Orders' : 'Laporan Pengeluaran';
    final fileName = jenis == 'orders' ? 'laporan_orders.pdf' : 'laporan_pengeluaran.pdf';
    final data = await _fetchData(jenis);
    await _generateAndSavePdf(data, title, fileName, jenis);
  }

  Widget _buildLaporanContent() {
    if (_selectedLaporan == '') {
      return Center(child: Text('Silakan pilih jenis laporan.'));
    }

    final collectionName = _selectedLaporan;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchData(collectionName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Tidak ada data $_selectedLaporan.'));

        final data = snapshot.data!;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  if (collectionName == 'orders') {
                    final tanggal = (item['tanggal_order'] as Timestamp?)?.toDate();
                    final formattedTanggal = tanggal != null
                        ? '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')} '
                        '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}'
                        : '-';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Username: ${item['username'] ?? '-'}', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Nomor HP: ${item['nomor_hp'] ?? '-'}'),
                            Text('Alamat: ${item['alamat'] ?? '-'}'),
                            Text('Layanan: ${item['layanan'] ?? '-'}'),
                            Text('Berat: ${item['berat'] ?? '-'} kg'),
                            Text('Status Order: ${item['status_order'] ?? '-'}'),
                            Text('Status Pembayaran: ${item['status_pembayaran'] ?? '-'}'),
                            Text('Tanggal Order: $formattedTanggal'),
                            Text('Order ID: ${item['order_id'] ?? '-'}'),
                            Text('Harga Total: ${item['harga_total'] ?? '-'}'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final tanggal = (item['tanggal'] as Timestamp?)?.toDate();
                    final formattedTanggal = tanggal != null
                        ? '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}'
                        : '-';
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(item['kategori'] ?? '-'),
                        subtitle: Text('${item['keterangan']} - $formattedTanggal'),
                        trailing: Text("Rp ${item['jumlah']}"),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _handleCetak(collectionName),
              icon: Icon(Icons.picture_as_pdf),
              label: Text('Cetak PDF ${collectionName == 'orders' ? 'Orders' : 'Pengeluaran'}'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Laporan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _selectedLaporan = 'orders'),
                  child: Text('Laporan Orders'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedLaporan = 'pengeluaran'),
                  child: Text('Laporan Pengeluaran'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(child: _buildLaporanContent()),
          ],
        ),
      ),
    );
  }
}
