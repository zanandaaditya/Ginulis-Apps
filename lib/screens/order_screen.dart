import 'package:flutter/material.dart';
import '../data/repository.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, this.order});
  final Map<String, dynamic>? order;
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  List<Map<String, dynamic>> _customers = [];
  String? _customerId;
  DateTime? _deadline;
  String _workStatus = 'menunggu';
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.order?['title']?.toString() ?? '');
    _description = TextEditingController(text: widget.order?['description']?.toString() ?? '');
    _price = TextEditingController(text: widget.order?['price']?.toString() ?? '');
    _customerId = widget.order?['customer_id']?.toString();
    _deadline = DateTime.tryParse(widget.order?['deadline']?.toString() ?? '');
    _workStatus = widget.order?['work_status']?.toString() ?? 'menunggu';
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      _customers = await GinulisRepository.instance.customers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat klien: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _price.dispose(); super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _customerId == null) return;
    setState(() => _saving = true);
    try {
      await GinulisRepository.instance.saveOrder(
        id: widget.order?['id']?.toString(),
        customerId: _customerId!, title: _title.text,
        description: _description.text, price: int.parse(_price.text.trim()),
        deadline: _deadline?.toIso8601String().substring(0, 10),
        workStatus: _workStatus,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.order == null ? 'Tambah Pesanan' : 'Edit Pesanan')),
    body: _loading ? const Center(child: CircularProgressIndicator())
    : _customers.isEmpty ? const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('Belum ada klien. Tambahkan klien dari menu Klien terlebih dahulu.'),
      ))
    : Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(
        value: _customerId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Pilih klien'),
        items: _customers.map((c) => DropdownMenuItem<String>(
          value: c['id'].toString(), child: Text(c['name'].toString()),
        )).toList(),
        onChanged: (v) => setState(() => _customerId = v),
        validator: (v) => v == null ? 'Pilih klien' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(controller: _title,
        decoration: const InputDecoration(labelText: 'Jenis jasa / nama pesanan'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _description, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Rincian pesanan')),
      const SizedBox(height: 12),
      TextFormField(controller: _price, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Harga total (Rp)', hintText: '250000'),
        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Harga harus lebih dari 0' : null),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.calendar_month),
        label: Text(_deadline == null ? 'Atur deadline (opsional)' :
          '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
        onPressed: () async {
          final picked = await showDatePicker(context: context,
            initialDate: _deadline ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (picked != null && mounted) setState(() => _deadline = picked);
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _workStatus,
        decoration: const InputDecoration(labelText: 'Status pengerjaan'),
        items: const [
          'menunggu', 'diproses', 'revisi', 'selesai', 'diserahkan', 'dibatalkan'
        ].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
        onChanged: (v) => setState(() => _workStatus = v ?? 'menunggu'),
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Menyimpan...' : 'Simpan Pesanan')),
    ])),
  );
}
