import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../data/repository.dart';
import '../services/receipt_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/ginulis_ui.dart';
import 'order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final o = await GinulisRepository.instance.order(widget.orderId);
      final p = await GinulisRepository.instance.payments(widget.orderId);
      if (mounted) setState(() { _order = o; _payments = p; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _customer => Map<String, dynamic>.from(_order?['customers'] as Map? ?? {});
  int get _total => (_order?['price'] as num?)?.toInt() ?? 0;
  int get _paid => paidTotal(_payments);
  int get _balance => _total - _paid;

  Future<void> _sendWhatsApp() async {
    if (_order == null) return;
    final type = await showModalBottomSheet<String>(context: context, showDragHandle: true,
      isScrollControlled: true, builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Kirim ke WhatsApp Klien',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          _waChoice(ctx, 'rincian', Icons.description_outlined, 'Rincian pesanan'),
          _waChoice(ctx, 'tagihan', Icons.receipt_long_outlined, 'Tagihan / sisa pembayaran'),
          if (_paid > 0 && _balance > 0)
            _waChoice(ctx, 'dp', Icons.payments_outlined, 'Konfirmasi DP'),
          if (_balance == 0)
            _waChoice(ctx, 'lunas', Icons.check_circle_outline_rounded, 'Konfirmasi lunas'),
          if (['selesai', 'diserahkan'].contains(_order?['work_status']))
            _waChoice(ctx, 'selesai', Icons.task_alt_rounded, 'Pekerjaan selesai'),
          const Padding(padding: EdgeInsets.all(8), child: Text(
            'Pesan akan dibuka di WhatsApp. Tekan Kirim secara manual.',
            style: TextStyle(color: AppColors.muted, fontSize: 11))),
        ]),
      )));
    if (type == null || !mounted) return;
    final clientName = _customer['name']?.toString() ?? 'Pelanggan';
    final title = _order?['title']?.toString() ?? 'Pesanan';
    final base = 'Halo Kak $clientName,\n\n';
    final money = 'Layanan: $title\nTotal tagihan: ${rupiah(_total)}\n'
        'Sudah dibayar: ${rupiah(_paid)}\nSisa pembayaran: ${rupiah(_balance)}\n'
        'Status: ${paymentStatus(_total, _paid)}';
    final message = switch (type) {
      'tagihan' => '${base}Berikut informasi tagihan Ginulis.id:\n$money\n\nTerima kasih.',
      'dp' => '${base}Pembayaran DP telah kami catat.\n$money\n\nTerima kasih.',
      'lunas' => '${base}Berikut status pembayaran pesanan Ginulis.id:\n$money\n\nTerima kasih.',
      'selesai' => '${base}Pekerjaan "$title" telah selesai diproses. Silakan hubungi admin untuk penerimaan hasil.\n\nGinulis.id',
      _ => WhatsAppService.orderMessage(customerName: clientName, title: title,
          status: paymentStatus(_total, _paid), total: rupiah(_total),
          paid: rupiah(_paid), balance: rupiah(_balance)),
    };
    try {
      await WhatsAppService.openChat(_customer['phone'].toString(), message);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa membuka WhatsApp: $e')));
    }
  }

  Widget _waChoice(BuildContext sheetContext, String value, IconData icon, String title) =>
    ListTile(leading: SquareIcon(icon, size: 39), title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(sheetContext, value));

  Future<void> _sharePdf() async {
    if (_order == null) return;
    try {
      await ReceiptService.shareReceipt(order: _order!,
        customerName: _customer['name']?.toString() ?? 'Pelanggan', paid: _paid);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membagikan PDF: $e')));
    }
  }

  Future<void> _addPayment() async {
    final remaining = _balance;
    if (remaining <= 0) return;
    final amount = TextEditingController();
    final notes = TextEditingController();
    String method = 'transfer';
    bool saving = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (inner, updateDialog) => AlertDialog(
        title: const Text('Catat Pembayaran'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Sisa tagihan: ${rupiah(remaining)}'),
          const SizedBox(height: 16),
          TextField(controller: amount, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal diterima (Rp)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: method,
            decoration: const InputDecoration(labelText: 'Metode pembayaran'),
            items: ['transfer', 'qris', 'tunai', 'lainnya'].map((s) => DropdownMenuItem(
              value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: saving ? null : (v) => updateDialog(() => method = v ?? 'transfer')),
          const SizedBox(height: 12),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
        ])),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: saving ? null : () async {
            final pay = int.tryParse(amount.text.trim()) ?? 0;
            if (pay <= 0 || pay > remaining) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                content: Text('Nominal tidak valid atau melebihi sisa tagihan.')));
              return;
            }
            updateDialog(() => saving = true);
            try {
              await GinulisRepository.instance.addPayment(orderId: widget.orderId,
                amount: pay, method: method, notes: notes.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await _load();
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Pembayaran gagal: $e')));
                updateDialog(() => saving = false);
              }
            }
          }, child: Text(saving ? 'Menyimpan...' : 'Simpan')),
        ],
      ),
    ));
    // Controller sengaja tidak dibuang pada saat dialog menutup dengan animasi;
    // akan dilepas setelah frame berikutnya untuk menghindari akses saat transisi.
    WidgetsBinding.instance.addPostFrameCallback((_) { amount.dispose(); notes.dispose(); });
  }

  Future<void> _edit() async {
    if (_order == null) return;
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => OrderScreen(order: _order)));
    if (saved == true) _load();
  }

  Future<void> _delete() async {
    if (_payments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
        Text('Pesanan yang sudah memiliki transaksi tidak bisa dihapus. Ubah statusnya menjadi Dibatalkan.')));
      return;
    }
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Pesanan?'),
      content: const Text('Pesanan tanpa pembayaran akan dihapus permanen.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
      ],
    ));
    if (yes != true) return;
    try {
      await GinulisRepository.instance.deleteOrder(widget.orderId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Widget _detailLine(String label, String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
      Expanded(child: Text(text, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan'), actions: [
        if (order != null) IconButton(tooltip: 'Edit pesanan', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        if (order != null) PopupMenuButton<String>(tooltip: 'Aksi lainnya', onSelected: (v) { if (v == 'delete') _delete(); },
          itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Hapus pesanan'))]),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : order == null ? const Center(child: Text('Pesanan tidak ditemukan.'))
        : ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 35), children: [
          SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const SquareIcon(Icons.description_outlined), const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order['title'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('ID: ${widget.orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ]))]),
            const SizedBox(height: 16),
            Wrap(spacing: 7, runSpacing: 7, children: [
              StatusTag(paymentStatus(_total, _paid)),
              StatusTag(order['work_status']?.toString() ?? 'menunggu'),
            ]),
            const SizedBox(height: 16),
            const Divider(color: AppColors.stroke),
            _detailLine('Nama klien', _customer['name']?.toString() ?? '-'),
            _detailLine('Nomor WhatsApp', _customer['phone']?.toString() ?? '-'),
            _detailLine('Deadline', readableDate(order['deadline'])),
            if ((order['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Catatan pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 5),
              Text(order['description'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ])),
          const SizedBox(height: 15),
          SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ringkasan Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 13),
            _detailLine('Total harga', rupiah(_total)),
            _detailLine('Sudah dibayar', rupiah(_paid)),
            const Divider(color: AppColors.stroke),
            Row(children: [const Expanded(child: Text('Sisa tagihan', style: TextStyle(fontWeight: FontWeight.w800))),
              Text(rupiah(_balance), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.primary))]),
            const SizedBox(height: 15),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: _total <= 0 ? 0 : (_paid / _total).clamp(0.0, 1.0).toDouble(),
              minHeight: 8, backgroundColor: AppColors.lavender, color: AppColors.green)),
          ])),
          const SizedBox(height: 17),
          FilledButton.icon(onPressed: _sendWhatsApp, icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Kirim ke WhatsApp Klien')),
          const SizedBox(height: 9),
          OutlinedButton.icon(onPressed: _sharePdf, icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Bagikan Invoice / Resi PDF')),
          if (_balance > 0) ...[
            const SizedBox(height: 9),
            OutlinedButton.icon(onPressed: _addPayment, icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Catat DP / Pelunasan')),
          ],
          const SizedBox(height: 23),
          const SectionHeading('Riwayat Pembayaran'),
          const SizedBox(height: 9),
          if (_payments.isEmpty) const EmptyPanel('Belum ada pembayaran tercatat.', icon: Icons.payments_outlined)
          else ..._payments.map((p) => Padding(padding: const EdgeInsets.only(bottom: 9), child: SoftCard(
            child: Row(children: [const SquareIcon(Icons.payments_outlined, color: AppColors.green),
              const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rupiah((p['amount'] as num).toInt()), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${p['method'].toString().toUpperCase()} • ${readableDate(p['paid_at'])}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ])),
            ]),
          ))),
        ]),
    );
  }
}
