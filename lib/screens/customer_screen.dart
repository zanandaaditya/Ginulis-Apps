import 'package:flutter/material.dart';
import '../data/repository.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key, this.customer});
  final Map<String, dynamic>? customer;
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?['name']?.toString() ?? '');
    _phone = TextEditingController(text: widget.customer?['phone']?.toString() ?? '');
    _notes = TextEditingController(text: widget.customer?['notes']?.toString() ?? '');
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await GinulisRepository.instance.saveCustomer(
        id: widget.customer?['id']?.toString(), name: _name.text,
        phone: _phone.text, notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan klien: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.customer == null ? 'Tambah Klien' : 'Edit Klien')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nama klien'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Nomor WhatsApp, contoh 0812...'),
        validator: (v) => v == null || v.replaceAll(RegExp(r'\D'), '').length < 10
          ? 'Masukkan nomor yang valid' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _notes, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
      const SizedBox(height: 24),
      FilledButton(onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Menyimpan...' : 'Simpan Klien')),
    ])),
  );
}
