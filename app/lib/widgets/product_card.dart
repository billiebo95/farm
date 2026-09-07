import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'chip_button.dart';
import 'primary_button.dart';
import 'qty_stepper.dart';

/// A dense price-list row: name/producer/tags on top, price and quantity
/// controls on the bottom. Tapping the name area opens the detail sheet;
/// tapping remove/qty controls does not.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final qty = app.cart[product.id] ?? 0;
    final hasQty = qty > 0;
    final totalDisc = app.totalDisc;
    final price = app.finalPrice(product.basePrice);
    final out = product.outOfStock;
    final low = product.lowStock;

    final stockLabel = out ? 'нет на складе' : low ? 'мало · ${product.stock}' : '${product.stock} пачек';
    final stockFg = out ? AppColors.dangerFg : low ? AppColors.warnFg : AppColors.accent;
    final stockBg = out ? AppColors.dangerBg : low ? AppColors.warnBg : AppColors.accentSoftBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: hasQty ? AppColors.accent : AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => app.openProductSheet(product.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(product.name, style: AppText.productName)),
                          if (product.requiresMarking) ...[
                            const SizedBox(width: 6),
                            const StatusChip(label: 'ЧЗ', fg: AppColors.markFg, bg: AppColors.markBg, mono: true, fontSize: 9),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(product.producer, style: AppText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          StatusChip(label: stockLabel, fg: stockFg, bg: stockBg),
                          StatusChip(label: 'до ${product.period}', fg: AppColors.textMuted, bg: AppColors.chipBg),
                          StatusChip(label: 'уп. ${product.minOrder}', fg: AppColors.textMuted, bg: AppColors.chipBg),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (hasQty)
                InkWell(
                  onTap: () => app.removeFromCart(product),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(9)),
                    child: const Center(child: AppIcon.trash(color: AppColors.dangerFg)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.only(top: 9),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderHairline))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(app.money(price), style: AppText.price),
                          if (totalDisc < 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              app.money(product.basePrice),
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('за пачку · код ${product.id}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (hasQty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      QtyStepper(
                        text: app.qtyText(product),
                        onChanged: (v) => app.typeQty(product, v),
                        onCommit: () => app.commitQty(product),
                        onInc: () => app.bump(product, 1),
                        onDec: () => app.bump(product, -1),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextOnlyButton(label: '+ уп. ${product.minOrder}', onPressed: () => app.bump(product, product.minOrder), fontSize: 11),
                          const SizedBox(width: 6),
                          Text(app.money(qty * price), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: out ? null : () => app.bump(product, 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: out ? AppColors.disabledBg : AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!out) ...[
                            const Icon(Icons.add, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          Text(out ? 'Нет' : 'Добавить', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
