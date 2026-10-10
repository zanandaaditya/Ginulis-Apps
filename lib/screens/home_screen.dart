import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../data/repository.dart';
import '../widgets/ginulis_ui.dart';
import 'customer_directory_screen.dart';
import 'customer_screen.dart';
import 'order_detail_screen.dart';
import 'order_screen.dart';

/// Halaman utama redesign. Tetap memakai tabel customers, orders, payments lama.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filter = 'Semua';
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _payments = [];
  final _filters = const ['Semua', 'Belum Bayar', 'Sudah DP', 'Lunas', 'Diproses', 'Selesai'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final result = await Future.wait<List<Map<String, dynamic>>>([
        GinulisRepository.instance.orders(),
        GinulisRepository.instance.customers(),
        GinulisRepository.instance.allPayments(),
      ]);
      if (mounted) setState(() { _orders = result[0]; _customers = result[1]; _payments = result[2]; });
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal mengambil data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _paid(String orderId) => _payments.where((p) => p['order_id'].toString() == orderId)
      .fold<int>(0, (a, p) => a + (p['amount'] as num).toInt());
  int get _received => _payments.fold<int>(0, (a, p) => a + (p['amount'] as num).toInt());
  int get _billed => _orders.fold<int>(0, (a, p) => a + (p['price'] as num).toInt());
  int get _outstanding => math.max(0, _billed - _received);
  bool _done(Map<String, dynamic> o) => ['selesai', 'diserahkan'].contains(o['work_status']);
  bool _cancelled(Map<String, dynamic> o) => o['work_status'] == 'dibatalkan';
  int get _active => _orders.where((o) => !_done(o) && !_cancelled(o)).length;
  int get _finished => _orders.where(_done).length;
  double get _completion => _orders.isEmpty ? 0 : _finished / _orders.length;
  String get _todayLabel => DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now());

  Future<void> _addOrder() async {
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan klien terlebih dahulu.')));
      await _addCustomer();
      return;
    }
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OrderScreen()));
    if (saved == true) await _load();
  }

  Future<void> _addCustomer() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CustomerScreen()));
    if (saved == true) await _load();
  }

  Future<void> _openClients() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerDirectoryScreen()));
    await _load();
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrderDetailScreen(orderId: order['id'].toString()),
    ));
    await _load();
  }

  Widget _header(String headline, String subtitle, {Widget? action}) =>
      Padding(padding: const EdgeInsets.fromLTRB(21, 18, 21, 15), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(headline, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 25, letterSpacing: -0.6)),
        ])),
        if (action != null) action,
      ]));

  Widget _dashboard() {
    final today = DateUtils.dateOnly(DateTime.now());
    final nearest = _orders.where((o) => !_done(o) && !_cancelled(o) && o['deadline'] != null)
        .toList()..sort((a, b) => a['deadline'].toString().compareTo(b['deadline'].toString()));
    final dueToday = nearest.where((o) => DateTime.tryParse(o['deadline'].toString()) == today).length;
    final monthPaid = _payments.where((p) {
      final d = DateTime.tryParse(p['paid_at'].toString())?.toLocal();
      return d != null && d.year == today.year && d.month == today.month;
    }).fold<int>(0, (a, p) => a + (p['amount'] as num).toInt());
    return RefreshIndicator(onRefresh: _load, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(21, 0, 21, 112), children: [
        const SizedBox(height: 15),
        Row(children: [
          const SquareIcon(Icons.grid_view_rounded, color: AppColors.primary, size: 45),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Halo, Admin 👋', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.navy)),
            Text(_todayLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ])),
          IconButton.filledTonal(tooltip: 'Lihat profil', onPressed: () => setState(() => _tab = 4),
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6D67FA), Color(0xFF4845D8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ringkasan Pekerjaan', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 7),
              const Text('Tetap produktif\nbersama Ginulis.id',
                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 12),
              Text('$_finished dari ${_orders.length} pesanan selesai', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
            SizedBox(width: 88, height: 88, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: _completion, strokeWidth: 9,
                backgroundColor: Colors.white.withValues(alpha: .20),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                strokeCap: StrokeCap.round,
              )),
              Text('${(_completion * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _metric(Icons.assignment_rounded, 'Pesanan Aktif', '$_active', AppColors.primary)),
          const SizedBox(width: 11),
          Expanded(child: _metric(Icons.event_rounded, 'Deadline Hari Ini', '$dueToday', AppColors.orange)),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: _metric(Icons.account_balance_wallet_rounded, 'Masuk Bulan Ini', rupiah(monthPaid), AppColors.green, compact: true)),
          const SizedBox(width: 11),
          Expanded(child: _metric(Icons.pending_actions_rounded, 'Sisa Tagihan', rupiah(_outstanding), AppColors.red, compact: true)),
        ]),
        const SizedBox(height: 20),
        const SectionHeading('Aksi Cepat'),
        const SizedBox(height: 9),
        Row(children: [
          _quick(Icons.add_circle_outline_rounded, 'Pesanan', _addOrder, AppColors.primary),
          _quick(Icons.person_add_alt_1_rounded, 'Klien', _addCustomer, AppColors.orange),
          _quick(Icons.calendar_month_rounded, 'Kalender', () => setState(() => _tab = 2), AppColors.cyan),
          _quick(Icons.pie_chart_outline_rounded, 'Keuangan', () => setState(() => _tab = 3), AppColors.green),
        ]),
        const SizedBox(height: 18),
        SectionHeading('Deadline Terdekat', trailing: 'Kalender', onTrailing: () => setState(() => _tab = 2)),
        const SizedBox(height: 7),
        if (nearest.isEmpty) const EmptyPanel('Tidak ada deadline aktif.', icon: Icons.event_available_outlined)
        else ...nearest.take(3).map((o) => Padding(padding: const EdgeInsets.only(bottom: 9),
          child: OrderCard(order: o, paid: _paid(o['id'].toString()), onTap: () => _openOrder(o)))),
        const SizedBox(height: 8),
        SectionHeading('Pesanan Terbaru', trailing: 'Lihat Semua', onTrailing: () => setState(() => _tab = 1)),
        const SizedBox(height: 7),
        if (_orders.isEmpty) const EmptyPanel('Belum ada pesanan. Mulai dengan tombol +.')
        else ..._orders.take(3).map((o) => Padding(padding: const EdgeInsets.only(bottom: 9),
          child: OrderCard(order: o, paid: _paid(o['id'].toString()), onTap: () => _openOrder(o)))),
      ],
    ));
  }

  Widget _metric(IconData icon, String caption, String value, Color color, {bool compact = false}) =>
    ExpandedMetric(icon: icon, caption: caption, value: value, color: color, compact: compact);

  Widget _quick(IconData icon, String label, VoidCallback onTap, Color color) => Expanded(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: InkWell(
      borderRadius: BorderRadius.circular(17), onTap: onTap,
      child: Column(children: [
        Container(width: 57, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(17)),
          child: Icon(icon, color: color, size: 25)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
      ]),
    )),
  );

  Widget _ordersPage() {
    final search = _search.trim().toLowerCase();
    final visible = _orders.where((o) {
      final customer = Map<String, dynamic>.from(o['customers'] as Map? ?? {});
      final matches = '${o['title']} ${customer['name']} ${customer['phone']}'.toLowerCase().contains(search);
      final payment = paymentStatus((o['price'] as num).toInt(), _paid(o['id'].toString()));
      return matches && (_filter == 'Semua' || payment == _filter ||
        o['work_status'].toString().toLowerCase() == _filter.toLowerCase());
    }).toList();
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(21, 0, 21, 110), physics: const AlwaysScrollableScrollPhysics(), children: [
        _header('Semua Pesanan', '${_orders.length} pesanan tercatat',
          action: IconButton.filledTonal(tooltip: 'Kelola klien', onPressed: _openClients,
            icon: const Icon(Icons.people_outline_rounded))),
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            hintText: 'Cari pesanan, klien, nomor WhatsApp',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(height: 37, child: ListView.separated(scrollDirection: Axis.horizontal,
          itemCount: _filters.length, separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, index) {
            final f = _filters[index];
            final selected = _filter == f;
            return ChoiceChip(
              label: Text(f), selected: selected, showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.stroke),
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
              onSelected: (_) => setState(() => _filter = f),
            );
          },
        )),
        const SizedBox(height: 20),
        Text('${visible.length} hasil ditemukan', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 10),
        if (visible.isEmpty) const EmptyPanel('Pesanan tidak ditemukan.')
        else ...visible.map((o) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: OrderCard(order: o, paid: _paid(o['id'].toString()), onTap: () => _openOrder(o)))),
      ],
    ));
  }

  List<Map<String, dynamic>> _dueOn(DateTime day) => _orders.where((o) {
    final d = DateTime.tryParse(o['deadline']?.toString() ?? '');
    return d != null && DateUtils.isSameDay(d, day) && !_cancelled(o);
  }).toList();

  Widget _calendarPage() {
    final first = DateTime(_month.year, _month.month, 1);
    final start = first.subtract(Duration(days: first.weekday - DateTime.monday));
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final visible = _dueOn(_selectedDate);
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(21, 0, 21, 112), physics: const AlwaysScrollableScrollPhysics(), children: [
        _header('Kalender', 'Atur jadwal dan deadline'),
        SoftCard(child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
              icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(child: Text(DateFormat('MMMM yyyy', 'id_ID').format(_month), textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          const SizedBox(height: 11),
          Row(children: weekdays.map((name) => Expanded(child: Center(child: Text(name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted))))).toList()),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.90),
            itemCount: 42,
            itemBuilder: (ctx, i) {
              final date = DateUtils.dateOnly(start.add(Duration(days: i)));
              final selected = DateUtils.isSameDay(date, _selectedDate);
              final today = DateUtils.isSameDay(date, DateTime.now());
              final inMonth = date.month == _month.month;
              final hasOrders = _dueOn(date).isNotEmpty;
              return InkWell(borderRadius: BorderRadius.circular(14), onTap: () => setState(() {
                _selectedDate = date;
                if (!inMonth) _month = DateTime(date.year, date.month);
              }), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(height: 31, width: 32, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    border: today && !selected ? Border.all(color: AppColors.primary) : null,
                  ), child: Text('${date.day}', style: TextStyle(
                    fontSize: 12, fontWeight: selected || today ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? Colors.white : inMonth ? AppColors.navy : AppColors.muted.withValues(alpha: .4)))),
                const SizedBox(height: 3),
                CircleAvatar(radius: 2.4, backgroundColor: hasOrders ? AppColors.orange : Colors.transparent),
              ]));
            },
          ),
        ])),
        const SizedBox(height: 20),
        SectionHeading('Deadline ${DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)}'),
        const SizedBox(height: 9),
        if (visible.isEmpty) const EmptyPanel('Tidak ada pesanan pada tanggal ini.', icon: Icons.event_available_outlined)
        else ...visible.map((o) => Padding(padding: const EdgeInsets.only(bottom: 9),
          child: OrderCard(order: o, paid: _paid(o['id'].toString()), onTap: () => _openOrder(o)))),
      ],
    ));
  }

  Widget _financePage() {
    final now = DateTime.now();
    final monthPaid = _payments.where((p) {
      final d = DateTime.tryParse(p['paid_at'].toString())?.toLocal();
      return d != null && d.year == now.year && d.month == now.month;
    }).fold<int>(0, (a, p) => a + (p['amount'] as num).toInt());
    final monthStart = DateUtils.dateOnly(now).subtract(const Duration(days: 6));
    final lastWeek = List<int>.generate(7, (i) {
      final target = monthStart.add(Duration(days: i));
      return _payments.where((p) {
        final d = DateTime.tryParse(p['paid_at'].toString())?.toLocal();
        return d != null && DateUtils.isSameDay(target, d);
      }).fold<int>(0, (a, p) => a + (p['amount'] as num).toInt());
    });
    final unpaid = _orders.where((o) => _paid(o['id'].toString()) == 0).length;
    final dp = _orders.where((o) { final v = _paid(o['id'].toString()); return v > 0 && v < (o['price'] as num).toInt(); }).length;
    final paid = _orders.length - unpaid - dp;
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(21, 0, 21, 112), physics: const AlwaysScrollableScrollPhysics(), children: [
        _header('Keuangan', 'Analitik usaha Ginulis.id'),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF605CF3), Color(0xFF4846C9)]), borderRadius: BorderRadius.circular(23)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pemasukan bulan ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Text(rupiah(monthPaid), style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(DateFormat('MMMM yyyy', 'id_ID').format(now), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _metric(Icons.savings_rounded, 'Total Diterima', rupiah(_received), AppColors.green, compact: true)),
          const SizedBox(width: 10),
          Expanded(child: _metric(Icons.account_balance_wallet_outlined, 'Sisa Tagihan', rupiah(_outstanding), AppColors.red, compact: true)),
        ]),
        const SizedBox(height: 21),
        const SectionHeading('Pemasukan 7 Hari'),
        const SizedBox(height: 9),
        SoftCard(child: Column(children: [
          SizedBox(height: 155, width: double.infinity, child: CustomPaint(painter: IncomeChartPainter(lastWeek))),
          const SizedBox(height: 9),
          Row(children: List.generate(7, (i) => Expanded(child: Text(
            DateFormat('E', 'id_ID').format(monthStart.add(Duration(days: i))), textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted))))),
          const SizedBox(height: 8),
          Text('Berdasarkan tanggal pembayaran tercatat', style: Theme.of(context).textTheme.bodySmall),
        ])),
        const SizedBox(height: 21),
        const SectionHeading('Status Pembayaran'),
        const SizedBox(height: 9),
        SoftCard(child: Row(children: [
          SizedBox(width: 108, height: 108, child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(child: CircularProgressIndicator(value: _orders.isEmpty ? 0 : paid / _orders.length,
              strokeWidth: 12, backgroundColor: AppColors.lavender, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green), strokeCap: StrokeCap.round)),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$paid', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const Text('Lunas', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ])),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _legend(AppColors.green, 'Lunas', paid),
            const SizedBox(height: 12),
            _legend(AppColors.orange, 'Sudah DP', dp),
            const SizedBox(height: 12),
            _legend(AppColors.red, 'Belum Bayar', unpaid),
          ])),
        ])),
        const SizedBox(height: 10),
        Text('Pemasukan adalah uang yang sudah dicatat, bukan total nilai pesanan.',
          style: Theme.of(context).textTheme.bodySmall),
      ],
    ));
  }

  Widget _legend(Color color, String name, int count) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
    Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
  ]);

  Widget _profilePage() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Akun pemilik';
    return ListView(padding: const EdgeInsets.fromLTRB(21, 0, 21, 112), children: [
      _header('Profil & Pengaturan', 'Pengelolaan aplikasi pribadi'),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF263452), Color(0xFF14203C)]),
        borderRadius: BorderRadius.circular(25)),
        child: Row(children: [
          Container(width: 61, height: 61, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(19)),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 35)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pemilik Ginulis.id', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 3),
            Text(email, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            const Text('Akun admin pribadi', style: TextStyle(color: AppColors.yellow, fontSize: 11)),
          ])),
        ])),
      const SizedBox(height: 21),
      const SectionHeading('Kelola Usaha'),
      const SizedBox(height: 8),
      SoftCard(padding: EdgeInsets.zero, child: Column(children: [
        _setting(Icons.people_alt_outlined, 'Data Klien', 'Lihat dan edit kontak', _openClients),
        const Divider(height: 1, indent: 64),
        _setting(Icons.receipt_long_outlined, 'Daftar Pesanan', 'Pantau pekerjaan dan pembayaran', () => setState(() => _tab = 1)),
        const Divider(height: 1, indent: 64),
        _setting(Icons.refresh_rounded, 'Sinkronkan Data', 'Ambil data terbaru dari Supabase', _load),
      ])),
      const SizedBox(height: 21),
      const SectionHeading('Informasi'),
      const SizedBox(height: 8),
      SoftCard(padding: EdgeInsets.zero, child: Column(children: [
        _setting(Icons.chat_bubble_outline_rounded, 'WhatsApp Business', 'Nomor usaha: 0895 3286 32187', () => showDialog<void>(
          context: context, builder: (ctx) => AlertDialog(title: const Text('WhatsApp Business'),
          content: const Text('Buka pesanan untuk mengirim pesan ke nomor klien. Pengiriman dilakukan secara manual di WhatsApp.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))]))),
        const Divider(height: 1, indent: 64),
        _setting(Icons.info_outline_rounded, 'Tentang Ginulis.id', 'Versi redesign 1.1', () => showAboutDialog(
          context: context, applicationName: 'Ginulis.id', applicationVersion: '1.1',
          children: [const Text('Aplikasi pribadi manajemen pesanan, keuangan, dan deadline.')],
        )),
      ])),
      const SizedBox(height: 19),
      OutlinedButton.icon(onPressed: () async => Supabase.instance.client.auth.signOut(),
        icon: const Icon(Icons.logout_rounded), label: const Text('Keluar dari Akun')),
    ]);
  }

  Widget _setting(IconData icon, String title, String subtitle, VoidCallback tap) => ListTile(
    leading: SquareIcon(icon, size: 40), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted), onTap: tap,
  );

  Widget _bottomNav() {
    const icons = [Icons.home_outlined, Icons.receipt_long_outlined, Icons.calendar_month_outlined,
      Icons.bar_chart_rounded, Icons.person_outline_rounded];
    const selected = [Icons.home_rounded, Icons.receipt_long_rounded, Icons.calendar_month_rounded,
      Icons.bar_chart_rounded, Icons.person_rounded];
    const labels = ['Home', 'Pesanan', 'Kalender', 'Keuangan', 'Profil'];
    return Container(
      padding: EdgeInsets.only(bottom: math.max(10, MediaQuery.paddingOf(context).bottom), top: 10, left: 8, right: 8),
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: AppColors.stroke)),
        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.04), blurRadius: 17, offset: const Offset(0, -4))]),
      child: Row(children: List.generate(5, (i) => Expanded(child: InkWell(
        onTap: () => setState(() => _tab = i), borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_tab == i ? selected[i] : icons[i], size: 23, color: _tab == i ? AppColors.primary : AppColors.muted),
          const SizedBox(height: 5),
          Text(labels[i], style: TextStyle(fontSize: 9.5,
            fontWeight: _tab == i ? FontWeight.w800 : FontWeight.w500,
            color: _tab == i ? AppColors.primary : AppColors.muted)),
        ])),
      )))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(bottom: false, child: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 40),
              const SizedBox(height: 13),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(onPressed: _load, child: const Text('Coba lagi')),
            ])))
        : switch (_tab) {
          0 => _dashboard(),
          1 => _ordersPage(),
          2 => _calendarPage(),
          3 => _financePage(),
          _ => _profilePage(),
        }),
    bottomNavigationBar: _bottomNav(),
    floatingActionButton: _tab <= 2 ? FloatingActionButton(
      onPressed: _addOrder, tooltip: 'Tambah pesanan', child: const Icon(Icons.add_rounded, size: 30)) : null,
  );
}

class ExpandedMetric extends StatelessWidget {
  const ExpandedMetric({super.key, required this.icon, required this.caption, required this.value, required this.color, this.compact = false});
  final IconData icon;
  final String caption;
  final String value;
  final Color color;
  final bool compact;
  @override
  Widget build(BuildContext context) => SoftCard(padding: const EdgeInsets.all(13), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      SquareIcon(icon, color: color, size: 35),
      const SizedBox(height: 9),
      Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      const SizedBox(height: 5),
      FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown,
        child: Text(value, style: TextStyle(fontSize: compact ? 18 : 22, fontWeight: FontWeight.w800, color: AppColors.navy))),
    ],
  ));
}

class IncomeChartPainter extends CustomPainter {
  IncomeChartPainter(this.values);
  final List<int> values;
  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = math.max(1, values.reduce(math.max));
    final h = size.height - 16;
    final w = size.width;
    final guide = Paint()..color = AppColors.stroke..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = 8 + i * h / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), guide);
    }
    final points = List<Offset>.generate(values.length, (i) => Offset(
      i * w / math.max(1, values.length - 1), 8 + h * (1 - values[i] / maxVal)));
    final fillPath = Path()..moveTo(points.first.dx, h + 8);
    for (final p in points) { fillPath.lineTo(p.dx, p.dy); }
    fillPath..lineTo(points.last.dx, h + 8)..close();
    canvas.drawPath(fillPath, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0x44625BF6), Color(0x00625BF6)],
    ).createShader(Rect.fromLTWH(0, 0, w, size.height)));
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) { line.lineTo(p.dx, p.dy); }
    canvas.drawPath(line, Paint()..color = AppColors.primary..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final p in points) { canvas.drawCircle(p, 4, Paint()..color = AppColors.primary); canvas.drawCircle(p, 2, Paint()..color = Colors.white); }
  }
  @override
  bool shouldRepaint(covariant IncomeChartPainter oldDelegate) => !listEqualsInt(values, oldDelegate.values);
  static bool listEqualsInt(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) { if (a[i] != b[i]) return false; }
    return true;
  }
}
