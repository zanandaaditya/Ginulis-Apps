import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(17), this.color = Colors.white, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
      boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.035), blurRadius: 22, offset: const Offset(0, 6))],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing, this.onTrailing});
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy))),
      if (trailing != null)
        TextButton(onPressed: onTrailing, child: Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key, this.small = false});
  final String status;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final Color color;
    if (s.contains('lunas') || s == 'selesai' || s == 'diserahkan') {
      color = AppColors.green;
    } else if (s.contains('belum') || s == 'dibatalkan') {
      color = AppColors.red;
    } else if (s.contains('dp') || s == 'revisi') {
      color = AppColors.orange;
    } else {
      color = AppColors.primary;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 11, vertical: small ? 5 : 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(9)),
      child: Text(status, style: TextStyle(fontSize: small ? 10 : 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class SquareIcon extends StatelessWidget {
  const SquareIcon(this.icon, {super.key, this.color = AppColors.primary, this.size = 43});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(13)),
    child: Icon(icon, color: color, size: size * 0.48),
  );
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.paid, required this.onTap});
  final Map<String, dynamic> order;
  final int paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customer = Map<String, dynamic>.from(order['customers'] as Map? ?? {});
    final price = (order['price'] as num).toInt();
    final deadline = DateTime.tryParse(order['deadline']?.toString() ?? '');
    final overdue = deadline != null && DateUtils.dateOnly(deadline).isBefore(DateUtils.dateOnly(DateTime.now())) &&
        !['selesai', 'diserahkan', 'dibatalkan'].contains(order['work_status']);
    return SoftCard(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SquareIcon(Icons.description_rounded, color: AppColors.primary, size: 45),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order['title']?.toString() ?? 'Pesanan', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 3),
          Text(customer['name']?.toString() ?? 'Klien', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            StatusTag(paymentStatus(price, paid), small: true),
            StatusTag((order['work_status'] ?? 'menunggu').toString(), small: true),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: overdue ? AppColors.red : AppColors.muted),
            const SizedBox(width: 4),
            Expanded(child: Text(deadline == null ? 'Tanpa deadline' : readableDate(deadline),
              style: TextStyle(fontSize: 11, color: overdue ? AppColors.red : AppColors.muted), overflow: TextOverflow.ellipsis)),
            Text(rupiah(price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy)),
          ]),
        ])),
      ]),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SoftCard(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(child: Column(children: [
      Icon(icon, color: AppColors.muted, size: 32),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
    ])),
  ));
}
