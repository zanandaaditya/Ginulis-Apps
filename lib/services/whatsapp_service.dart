import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Nomor Indonesia: 0812... -> 62812..., +62812... -> 62812...
  static String normalizeIndonesianNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    if (digits.startsWith('8')) digits = '62$digits';
    if (!digits.startsWith('62') || digits.length < 11 || digits.length > 16) {
      throw const FormatException('Nomor WhatsApp tidak valid.');
    }
    return digits;
  }

  static String orderMessage({required String customerName,
      required String title, required String status, required String total,
      required String paid, required String balance}) => '''
Halo Kak $customerName,

Berikut rincian pesanan Ginulis.id:
Layanan: $title
Total tagihan: $total
Sudah dibayar: $paid
Sisa pembayaran: $balance
Status: $status

Terima kasih telah mempercayakan kebutuhan dokumen kepada Ginulis.id.
''';

  /// Membuka WA menggunakan tautan universal. Penerima & pesan terisi,
  /// tetapi pengguna tetap harus menekan tombol kirim di WhatsApp.
  /// iOS tidak selalu memilih WhatsApp Business secara otomatis.
  static Future<void> openChat(String phone, String text) async {
    final normalized = normalizeIndonesianNumber(phone);
    final url = Uri.https('wa.me', '/$normalized', {'text': text});
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('WhatsApp tidak dapat dibuka.');
  }
}
