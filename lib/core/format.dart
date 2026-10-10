import 'package:intl/intl.dart';

String rupiah(num amount) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(amount);

String readableDate(Object? input) {
  if (input == null || input.toString().isEmpty) return '-';
  final parsed = DateTime.tryParse(input.toString());
  if (parsed == null) return input.toString();
  return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
}

int paidTotal(List<Map<String, dynamic>> payments) => payments.fold<int>(
      0,
      (sum, payment) => sum + (payment['amount'] as num).toInt(),
    );

String paymentStatus(int total, int paid) {
  if (paid <= 0) return 'Belum Bayar';
  if (paid >= total) return 'Lunas';
  return 'Sudah DP';
}
