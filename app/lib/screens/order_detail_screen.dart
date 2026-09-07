import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icons.dart';
import '../widgets/chip_button.dart';
import '../widgets/primary_button.dart';

/// Full-screen order detail: line items, comment, and a repeat-order
/// action — pushed on top of the tab content.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: AppColors.screenBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.borderCard))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: app.closeOrderDetail,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: AppIcon.back(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.number, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 19)),
                      const SizedBox(height: 2),
                      Text('${order.date} · ${order.client}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                StatusChip(label: order.status.label, fg: order.status.fg, bg: order.status.bg, fontSize: 11),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderCard), borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        color: const Color(0xFFF8FAF9),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
                        child: const Text('Позиции заказа', style: AppText.label),
                      ),
                      for (final l in order.lines) _OrderLineRow(order: order, productId: l.productId, qty: l.qty, price: l.price, app: app),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                        color: const Color(0xFFF8FAF9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('Итого · ${order.packs} пачек', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(app.money(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.hasComment)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Комментарий', style: AppText.label),
                        const SizedBox(height: 6),
                        Text(order.comment, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDim)),
                      ],
                    ),
                  ),
                SecondaryButton(label: 'Повторить заказ', onPressed: () => app.repeatOrder(order)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.order, required this.productId, required this.qty, required this.price, required this.app});
  final Order order;
  final String productId;
  final int qty;
  final double price;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final product = MockData.findProduct(productId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product?.name ?? productId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.35)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$productId · $qty × ${app.money(price)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textTertiary)),
              Text(app.money(qty * price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

