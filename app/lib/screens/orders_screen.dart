import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/chip_button.dart';

/// The signed-in pharmacy's own order history.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final orders = app.myOrders;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.borderCard))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Отправленные заказы', style: AppText.display),
              const SizedBox(height: 3),
              Text(
                'Код доставки ${app.loginCode.trim().isEmpty ? '190172-04' : app.loginCode.trim()} · ${orders.length} заказов',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final o in orders) _OrderCard(order: o, onTap: () => app.openOrderDetail(o.number))],
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return AppCard(
      margin: const EdgeInsets.only(bottom: 9),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.number, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14)),
              StatusChip(label: order.status.label, fg: order.status.fg, bg: order.status.bg, fontSize: 11),
            ],
          ),
          const SizedBox(height: 9),
          Text('${order.positions} позиций · ${order.packs} пачек', style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderHairline))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(order.date, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                Text(app.money(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              children: [
                StatusChip(label: order.dbf.label, fg: order.dbf.fg, bg: order.dbf.bg, mono: true),
                const Spacer(),
                const Text('Открыть →', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
