import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/repository.dart';
import '../widgets/ginulis_ui.dart';
import 'customer_screen.dart';

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});
  @override
  State<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  bool _loading = true;
  String _search = '';
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await GinulisRepository.instance.customers();
      if (mounted) setState(() => _clients = rows);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat klien: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? client]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CustomerScreen(customer: client)));
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> client) async {
    final agree = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus klien?'),
      content: const Text('Klien dengan pesanan tidak dapat dihapus untuk menjaga riwayat transaksi.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
      ],
    ));
    if (agree != true) return;
    try {
      await GinulisRepository.instance.deleteCustomer(client['id'].toString());
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat menghapus klien: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _clients.where((c) => '${c['name']} ${c['phone']}'.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Klien')),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _load, child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                TextField(onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(hintText: 'Cari nama atau nomor WhatsApp', prefixIcon: Icon(Icons.search_rounded))),
                const SizedBox(height: 17),
                Text('${shown.length} klien', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 10),
                if (shown.isEmpty) const EmptyPanel('Belum ada klien yang cocok.')
                else ...shown.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(children: [
                    const SquareIcon(Icons.person_rounded, color: AppColors.cyan),
                    const SizedBox(width: 10),
                    Expanded(child: InkWell(onTap: () => _edit(c), child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(c['phone'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ]),
                    ))),
                    IconButton(tooltip: 'Edit klien', icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: () => _edit(c)),
                    IconButton(tooltip: 'Hapus klien', icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red), onPressed: () => _delete(c)),
                  ]),
                ))),
              ],
            )),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), tooltip: 'Tambah klien', child: const Icon(Icons.add_rounded)),
    );
  }
}
