import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/format.dart';

class ReceiptService {
  static Future<void> shareReceipt({required Map<String, dynamic> order,
      required String customerName, required int paid}) async {
    final total = (order['price'] as num).toInt();
    final remaining = total - paid;
    final status = paymentStatus(total, paid);
    final shortId = (order['id'] as String).substring(0, 8).toUpperCase();
    final date = DateTime.now();
    final document = pw.Document();
    document.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ginulis.id', style: pw.TextStyle(
            fontSize: 24, color: PdfColor.fromHex('#2441A3'),
            fontWeight: pw.FontWeight.bold,
          )),
          pw.SizedBox(height: 6),
          pw.Text(paid == 0 ? 'INVOICE PESANAN' :
            remaining == 0 ? 'KUITANSI LUNAS' : 'RESI PEMBAYARAN DP'),
          pw.Divider(),
          pw.Text('No. Referensi: $shortId'),
          pw.Text('Tanggal: ${readableDate(date.toIso8601String())}'),
          pw.SizedBox(height: 14),
          pw.Text('Klien: $customerName'),
          pw.Text('Layanan: ${order['title']}'),
          pw.SizedBox(height: 14),
          _line('Total pesanan', rupiah(total)),
          _line('Total sudah dibayar', rupiah(paid)),
          _line('Sisa pembayaran', rupiah(remaining)),
          pw.Divider(),
          pw.Text('Status pembayaran: $status',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Text('Terima kasih telah menggunakan layanan Ginulis.id.'),
          pw.Text('WhatsApp: 0895 3286 32187'),
          pw.Text('Dokumen ringkasan pembayaran. Simpan catatan transaksi dalam aplikasi.'),
        ],
      ),
    ));
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'ginulis-$shortId.pdf',
    );
  }

  static pw.Widget _line(String left, String right) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(left), pw.Text(right)]),
  );
}
